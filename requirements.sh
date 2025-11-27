# insatll ollama
curl -fsSL https://ollama.com/install.sh | sh
# You may need to restart or stop Ollama if it's already running. Use the following command to stop Ollama:
pkill ollama
# To make the Ollama model accessible in the langchain environment run the following command:
export OLLAMA_HOST=0.0.0.0:11434
ollama serve

# Check that the model is running locally by executing:
curl http://127.0.0.1:11434/api/tags
# or
ss -ltnp | grep 11434
# LISTEN 0      4096               *:11434            *:*    users:(("ollama",pid=23649,fd=3))   

# To varify that the model is accessible, run:
curl http://<Server IP>:11434/api/tags

# To run Ollama in the background, use:
OLLAMA_HOST=0.0.0.0:11434 nohup ollama serve &
