#include "SuriInference.h"
#include "llama.h"
#include <atomic>
#include <chrono>
#include <cstdlib>
#include <cstring>
#include <mutex>
#include <string>
#include <vector>

struct suri_cancel_flag { std::atomic<bool> canceled{false}; std::chrono::steady_clock::time_point deadline; };
struct suri_engine { llama_model * model = nullptr; llama_context * context = nullptr; };
static bool aborted(void * pointer) {
    auto flag = static_cast<suri_cancel_flag *>(pointer);
    return flag->canceled.load() || std::chrono::steady_clock::now() > flag->deadline;
}
static void private_log(ggml_log_level, const char *, void *) { /* Never log prompts or tokens. */ }
extern "C" suri_cancel_flag * suri_cancel_create(void) {
    auto flag = new suri_cancel_flag;
    flag->deadline = std::chrono::steady_clock::now() + std::chrono::seconds(120);
    return flag;
}
extern "C" void suri_cancel_set(suri_cancel_flag * flag) { if (flag) flag->canceled.store(true); }
extern "C" void suri_cancel_free(suri_cancel_flag * flag) { delete flag; }
extern "C" suri_engine * suri_engine_create(const char * path) {
    static std::once_flag initialized;
    std::call_once(initialized, [] { llama_log_set(private_log, nullptr); llama_backend_init(); });
    auto engine = new suri_engine;
    auto params = llama_model_default_params(); params.n_gpu_layers = 0;
    engine->model = llama_model_load_from_file(path, params);
    if (!engine->model) { delete engine; return nullptr; }
    auto context = llama_context_default_params();
    context.n_ctx = 4096; context.n_batch = 512; context.n_ubatch = 128;
    context.n_threads = 4; context.n_threads_batch = 4;
    context.flash_attn_type = LLAMA_FLASH_ATTN_TYPE_DISABLED;
    context.offload_kqv = false; context.op_offload = false;
    engine->context = llama_init_from_model(engine->model, context);
    if (!engine->context) { llama_model_free(engine->model); delete engine; return nullptr; }
    return engine;
}
extern "C" void suri_engine_free(suri_engine * engine) {
    if (!engine) return;
    if (engine->context) llama_free(engine->context);
    if (engine->model) llama_model_free(engine->model);
    delete engine;
}
static const char * grammar = R"GBNF(
root ::= "{" ws "\"action\"" ws ":" ws action ws "," ws "\"quality\"" ws ":" ws quality ws "," ws "\"findings\"" ws ":" ws findings ws "," ws "\"risk\"" ws ":" ws risk ws "}" ws
risk ::= "\"warning_signs_found\"" | "\"needs_verification\"" | "\"no_obvious_warning_signs\""
action ::= "\"share_code\"" | "\"pay_upfront\"" | "\"send_money\"" | "\"change_destination\"" | "\"share_personal_details\"" | "\"open_link\"" | "\"install_software\"" | "\"ordinary\"" | "\"unknown\""
quality ::= "\"complete\"" | "\"partial\""
findings ::= "[" ws (finding (ws "," ws finding)*)? ws "]"
finding ::= "{" ws "\"code\"" ws ":" ws code ws "," ws "\"evidence\"" ws ":" ws string ws "}"
code ::= "\"code_disclosure\"" | "\"upfront_payment\"" | "\"changed_destination\"" | "\"sensitive_details\"" | "\"secrecy\"" | "\"time_pressure\"" | "\"remote_access\""
string ::= "\"" ([^"\\\x00-\x1F] | "\\" (["\\/bfnrt] | "u" [0-9a-fA-F] [0-9a-fA-F] [0-9a-fA-F] [0-9a-fA-F]))* "\""
ws ::= [ \t\n\r]*
)GBNF";
extern "C" char * suri_engine_generate(suri_engine * engine, const char * prompt, suri_cancel_flag * flag) {
    if (!engine || !flag || aborted(flag)) return nullptr;
    try {
        auto vocab = llama_model_get_vocab(engine->model);
        int size = -llama_tokenize(vocab, prompt, int(std::strlen(prompt)), nullptr, 0, true, true);
        if (size <= 0 || size > 3000) return nullptr;
        std::vector<llama_token> tokens(size);
        int count = llama_tokenize(vocab, prompt, int(std::strlen(prompt)), tokens.data(), size, true, true);
        if (count <= 0) return nullptr;
        tokens.resize(count);
        llama_memory_clear(llama_get_memory(engine->context), true);
        llama_set_abort_callback(engine->context, aborted, flag);
        struct Reset { llama_context * ctx; ~Reset() { llama_set_abort_callback(ctx, nullptr, nullptr); } } reset{engine->context};
        for (size_t start = 0; start < tokens.size(); start += 512) {
            if (aborted(flag)) return nullptr;
            int n = int(std::min(size_t(512), tokens.size() - start));
            if (llama_decode(engine->context, llama_batch_get_one(tokens.data() + start, n)) != 0) return nullptr;
        }
        // Let Qwen resolve meaning before constraining its final JSON. Reasoning is never returned or logged.
        // Qwen recommends sampling rather than greedy decoding in thinking mode.
        auto reasoning = llama_sampler_chain_init(llama_sampler_chain_default_params());
        llama_sampler_chain_add(reasoning, llama_sampler_init_top_k(20));
        llama_sampler_chain_add(reasoning, llama_sampler_init_top_p(0.95f, 1));
        llama_sampler_chain_add(reasoning, llama_sampler_init_temp(0.6f));
        llama_sampler_chain_add(reasoning, llama_sampler_init_dist(42));
        std::string reasoning_tail;
        bool thought_finished = false;
        for (int step = 0; step < 384; ++step) {
            if (aborted(flag)) { llama_sampler_free(reasoning); return nullptr; }
            auto token = llama_sampler_sample(reasoning, engine->context, -1);
            if (llama_vocab_is_eog(vocab, token)) break;
            char piece[256];
            int length = llama_token_to_piece(vocab, token, piece, sizeof(piece), 0, true);
            if (length > 0) reasoning_tail.append(piece, length);
            if (reasoning_tail.size() > 512) reasoning_tail.erase(0, reasoning_tail.size() - 512);
            if (llama_decode(engine->context, llama_batch_get_one(&token, 1)) != 0) { llama_sampler_free(reasoning); return nullptr; }
            if (reasoning_tail.find("</think>") != std::string::npos) { thought_finished = true; break; }
        }
        llama_sampler_free(reasoning);
        if (!thought_finished) {
            const char * close = "\n</think>\n\n";
            std::vector<llama_token> suffix(32);
            int n = llama_tokenize(vocab, close, int(std::strlen(close)), suffix.data(), int(suffix.size()), false, true);
            if (n <= 0 || llama_decode(engine->context, llama_batch_get_one(suffix.data(), n)) != 0) return nullptr;
        }
        auto sampler = llama_sampler_chain_init(llama_sampler_chain_default_params());
        struct Owner { llama_sampler * ptr; ~Owner() { llama_sampler_free(ptr); } } owner{sampler};
        auto constraint = llama_sampler_init_grammar(vocab, grammar, "root");
        if (!constraint) return nullptr;
        llama_sampler_chain_add(sampler, constraint);
        llama_sampler_chain_add(sampler, llama_sampler_init_greedy());
        std::string output;
        for (int step = 0; step < 600; ++step) {
            if (aborted(flag)) return nullptr;
            auto token = llama_sampler_sample(sampler, engine->context, -1);
            if (llama_vocab_is_eog(vocab, token)) return strdup(output.c_str());
            std::vector<char> piece(256);
            int length = llama_token_to_piece(vocab, token, piece.data(), int(piece.size()), 0, false);
            if (length < 0) { piece.resize(-length); length = llama_token_to_piece(vocab, token, piece.data(), int(piece.size()), 0, false); }
            if (length < 0) return nullptr;
            output.append(piece.data(), length);
            if (output.size() > 20000) return nullptr;
            if (llama_decode(engine->context, llama_batch_get_one(&token, 1)) != 0) return nullptr;
        }
        return nullptr;
    } catch (...) { return nullptr; }
}
extern "C" void suri_string_free(char * value) { std::free(value); }

extern "C" char * suri_engine_code_intent(suri_engine * engine, const char * prompt, suri_cancel_flag * flag) {
    if (!engine || !flag || aborted(flag)) return nullptr;
    try {
        auto vocab = llama_model_get_vocab(engine->model);
        int size = -llama_tokenize(vocab, prompt, int(std::strlen(prompt)), nullptr, 0, true, true);
        if (size <= 0 || size > 3000) return nullptr;
        std::vector<llama_token> tokens(size);
        int count = llama_tokenize(vocab, prompt, int(std::strlen(prompt)), tokens.data(), size, true, true);
        if (count <= 0) return nullptr;
        tokens.resize(count);
        llama_memory_clear(llama_get_memory(engine->context), true);
        llama_set_abort_callback(engine->context, aborted, flag);
        struct Reset { llama_context * ctx; ~Reset() { llama_set_abort_callback(ctx, nullptr, nullptr); } } reset{engine->context};
        for (size_t start = 0; start < tokens.size(); start += 512) {
            if (aborted(flag)) return nullptr;
            int n = int(std::min(size_t(512), tokens.size() - start));
            if (llama_decode(engine->context, llama_batch_get_one(tokens.data() + start, n)) != 0) return nullptr;
        }
        auto sampler = llama_sampler_chain_init(llama_sampler_chain_default_params());
        struct Owner { llama_sampler * ptr; ~Owner() { llama_sampler_free(ptr); } } owner{sampler};
        auto constraint = llama_sampler_init_grammar(vocab, "root ::= \"KEEP\" | \"REQUEST\" | \"OTHER\"", "root");
        if (!constraint) return nullptr;
        llama_sampler_chain_add(sampler, constraint); llama_sampler_chain_add(sampler, llama_sampler_init_greedy());
        std::string output;
        for (int step = 0; step < 12; ++step) {
            if (aborted(flag)) return nullptr;
            auto token = llama_sampler_sample(sampler, engine->context, -1);
            if (llama_vocab_is_eog(vocab, token)) return strdup(output.c_str());
            char piece[128]; int n = llama_token_to_piece(vocab, token, piece, sizeof(piece), 0, false);
            if (n > 0) output.append(piece, n);
            if (llama_decode(engine->context, llama_batch_get_one(&token, 1)) != 0) return nullptr;
        }
        return nullptr;
    } catch (...) { return nullptr; }
}
