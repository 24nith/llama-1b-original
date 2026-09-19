import os
import shutil
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parent
SERVER = Path(os.environ.get(
    'LLAMA_SERVER_EXE',
    ROOT / 'llama.cpp' / 'build-ascii' / 'bin' / 'Release' / 'llama-server.exe',
))
MODEL = Path(os.environ.get(
    'LLAMA_MODEL',
    ROOT / 'Llama-3.2-1B-Instruct-Q4_K_M.complete.gguf',
))


def main():
    if not SERVER.is_file():
        raise SystemExit(f'Cannot find llama-server executable: {SERVER}')
    if not MODEL.is_file():
        raise SystemExit(f'Cannot find GGUF model: {MODEL}')

    command = [
        str(SERVER),
        '--model', str(MODEL),
        '--host', '0.0.0.0',
        '--port', '8000',
        '--ctx-size', '2048',
        '--predict', '256',
    ]
    print('Host llama server starting on http://0.0.0.0:8000', flush=True)
    print('Android emulator should reach it via http://10.0.2.2:8000', flush=True)
    process = subprocess.Popen(command)
    try:
        process.wait()
    except KeyboardInterrupt:
        process.terminate()
        process.wait()


if __name__ == '__main__':
    main()
