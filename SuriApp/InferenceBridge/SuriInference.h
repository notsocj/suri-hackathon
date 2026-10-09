#ifndef SURI_INFERENCE_H
#define SURI_INFERENCE_H
#ifdef __cplusplus
extern "C" {
#endif
typedef struct suri_engine suri_engine;
typedef struct suri_cancel_flag suri_cancel_flag;
suri_cancel_flag * suri_cancel_create(void);
void suri_cancel_set(suri_cancel_flag * flag);
void suri_cancel_free(suri_cancel_flag * flag);
suri_engine * suri_engine_create(const char * model_path);
void suri_engine_free(suri_engine * engine);
char * suri_engine_generate(suri_engine * engine, const char * prompt, suri_cancel_flag * flag);
char * suri_engine_code_intent(suri_engine * engine, const char * prompt, suri_cancel_flag * flag);
void suri_string_free(char * value);
#ifdef __cplusplus
}
#endif
#endif
