"""Download/verify the exact Suri model for development. No message content is transmitted."""
import concurrent.futures, hashlib, json, pathlib, subprocess, sys
root = pathlib.Path(__file__).resolve().parent.parent
manifest = json.loads((root / 'SuriApp/Resources/model-manifest.json').read_text())
folder = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else root / '.build/Models/Qwen3-1.7B-GGUF'
folder.mkdir(parents=True, exist_ok=True)

def prepare(spec):
    target = folder / spec['name']
    if not target.exists() or target.stat().st_size != spec['bytes']:
        url = f"https://huggingface.co/{manifest['identifier']}/resolve/{manifest['revision']}/{spec['name']}"
        temporary = target.with_suffix(target.suffix + '.download')
        subprocess.run(['curl', '-L', '--fail', '--retry', '2', '--max-time', '1200', '-sS', url, '-o', str(temporary)], check=True)
        if temporary.stat().st_size != spec['bytes']: raise RuntimeError('Wrong file size: ' + spec['name'])
        temporary.replace(target)
    if spec['sha256']:
        hasher = hashlib.sha256()
        with target.open('rb') as stream:
            for block in iter(lambda: stream.read(4 * 1024 * 1024), b''): hasher.update(block)
        if hasher.hexdigest() != spec['sha256']: raise RuntimeError('Checksum mismatch: ' + spec['name'])
    return spec['name']

with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
    for name in pool.map(prepare, manifest['files']): print('Verified', name)
(folder / '.complete').write_text(manifest['revision'])
print('Model prepared at', folder)
