# Gemini API Key - Implementation Files

## Where Your Gemini API Key is Used

### 1. Configuration – `backend/app/core/config.py`

```python
GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "...")
GEMINI_MODEL: str = os.getenv("GEMINI_MODEL", "gemini-2.5-flash-image")
GEMINI_USE_PRO_MODEL: bool = os.getenv("GEMINI_USE_PRO_MODEL", "False").lower() == "true"
```

### 2. Validation – `backend/app/core/validation.py`

Validates that `GEMINI_API_KEY` and `GEMINI_MODEL` are set at startup.

### 3. Image Generation – `backend/app/stages/generation.py`

Main image generation stage. Sends API key in `x-goog-api-key` header.

### 4. Try-On API – `backend/app/api/tryon.py`

Health check returns `gemini_configured` status. Catches missing API key errors.

---

## Environment Configuration

**Option 1: Environment variable**
```bash
export GEMINI_API_KEY="your-api-key-here"
```

**Option 2: .env file**
```
GEMINI_API_KEY=your-api-key-here
GEMINI_MODEL=gemini-2.5-flash-image
```

**Option 3: Docker**
```yaml
environment:
  - GEMINI_API_KEY=${GEMINI_API_KEY}
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| 401 Unauthorized | Check API key is valid |
| 404 Not Found | Check model: `gemini-2.5-flash-image` |
| 429 Rate Limited | Wait and retry |
| No response | Check internet connection |

Get your key: https://ai.google.dev/
