# Quick Guide: Switch to Ollama (Free, No Quotas!)

## Why Ollama?
- ✅ **100% Free** - No API keys, no quotas
- ✅ **Open Source** - Completely free
- ✅ **Runs Locally** - No internet needed
- ✅ **Privacy** - All data stays on your machine

## 3-Step Setup (5 minutes)

### Step 1: Install Ollama
```bash
# Windows: Download from https://ollama.ai/download
# Or use winget:
winget install Ollama.Ollama
```

### Step 2: Pull a Model
```bash
# Open terminal and run:
ollama pull llama3.2

# This downloads the model (takes 2-5 minutes)
# Other options: mistral, phi3, gemma2
```

### Step 3: Switch Your Code

**Option A: Quick Switch (Recommended)**
```python
# In server/api/main.py, change line 12:
from . import ollama_chat as chat  # Instead of: from . import chat
```

**Option B: Update chat.py**
Just replace the contents of `server/api/chat.py` with `server/api/ollama_chat.py`

### Step 4: Restart Server
```bash
cd server
python -m uvicorn api.main:app --reload --port 8000
```

## That's It! 🎉

Your chat will now use Ollama - **completely free, no quotas, no API keys!**

## Test It

1. Make sure Ollama is running:
   ```bash
   # Check if running:
   curl http://localhost:11434/api/tags
   ```

2. Send a chat message in your app
3. It should work instantly!

## Troubleshooting

**"Cannot connect to Ollama"**
- Make sure Ollama is installed and running
- Check: http://localhost:11434

**"Model not found"**
- Run: `ollama pull llama3.2`
- Wait for download to complete

**Slow responses**
- Try a smaller model: `ollama pull phi3`
- Or use: `ollama pull mistral` (faster)

## Available Models

| Model | Size | Speed | Quality |
|-------|------|-------|---------|
| `llama3.2` | Medium | Fast | ⭐⭐⭐⭐ |
| `mistral` | Medium | Very Fast | ⭐⭐⭐⭐ |
| `phi3` | Small | Very Fast | ⭐⭐⭐ |
| `gemma2` | Medium | Fast | ⭐⭐⭐⭐ |

Try different models:
```bash
ollama pull mistral
# Then update OLLAMA_MODEL in ollama_chat.py
```

## Need Help?

- Ollama Docs: https://ollama.ai/docs
- Check `server/api/ollama_chat.py` for code
- See `FREE_AI_ALTERNATIVES.md` for other options


