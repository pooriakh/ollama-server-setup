# ollama-server-setup
## Overview
Small example showing how to create a Conda environment, install dependencies, and run a WebSocket server that accepts prompts and returns LLM outputs using langchain + langchain_ollama.

## Prerequisites
- Conda (Miniconda/Anaconda)
- Ollama (if using a local Ollama server or local model). Adjust model/source per your setup.

## Create environment and install
Run these commands:

```bash
conda create -n langchain python=3.13 -y
conda activate langchain
conda install -c conda-forge langchain -y
pip install langchain_ollama websockets
```

## WebSocket server (Python)
Save as `ws_server.py`. This opens a WebSocket server that receives JSON messages like `{"prompt": "..."}` and replies with `{"output": "..."}`.

```python
# ws_server.py
import asyncio
import json
import websockets
from langchain_ollama import ChatOllama

MODEL = "gpt-oss:20b"
BASE_URL = "http://10.101.80.10:11434"
TEMPERATURE = 0

# Initialize the model once
llm = ChatOllama(
    model=MODEL,
    temperature=TEMPERATURE,
    base_url=BASE_URL,
)

# single-argument handler, compatible with websockets>=11
async def handler(websocket):
    async for message in websocket:
        try:
            data = json.loads(message)
            prompt = data.get("prompt", "")

            # Run blocking LLM call in a thread so event loop stays responsive
            loop = asyncio.get_running_loop()
            ai_msg = await loop.run_in_executor(None, llm.invoke, prompt)

            # ai_msg is usually an AIMessage; fall back to str just in case
            output = getattr(ai_msg, "content", str(ai_msg))

            await websocket.send(json.dumps({"output": output}))
        except Exception as e:
            # Send error back to the client instead of crashing the server
            await websocket.send(json.dumps({"error": str(e)}))

async def main():
    async with websockets.serve(handler, "0.0.0.0", 8765):
        await asyncio.Future()  # run forever

if __name__ == "__main__":
    asyncio.run(main())
```

Run the server:
```bash
python ws_server.py
```

## WebSocket client (Python)
Save as `ws_client.py`. Example client sends a prompt and prints the response.

```python
# ws_client.py
import asyncio
import json
import websockets

async def main():
    uri = "ws://localhost:8765"
    async with websockets.connect(uri) as ws:
        prompt = "Write a short haiku about programming."
        await ws.send(json.dumps({"prompt": prompt}))
        resp = await ws.recv()
        print("Raw response:", resp)

        # Optional: parse JSON
        data = json.loads(resp)
        if "error" in data:
            print("Server error:", data["error"])
        else:
            print("Model output:", data["output"])

if __name__ == "__main__":
    asyncio.run(main())
```

Run the client:
```bash
python ws_client.py
```

## Notes
- Adjust the Ollama/model configuration as required by your environment (local Ollama daemon, remote host, or different model name).
- The example uses blocking LLM calls executed in an executor to keep the WebSocket loop responsive. For streaming or async LLM clients, integrate streaming handlers as appropriate.
- Add authentication, input validation, and rate limiting before exposing the server to untrusted networks.
