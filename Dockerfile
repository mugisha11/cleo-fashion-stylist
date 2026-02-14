# Minimal Railway Dockerfile - production try-on only (Gemini + OpenRouter)
# No torch, opencv, dlib - avoids apt-get failures
FROM python:3.10-slim

WORKDIR /app

# Minimal deps - no heavy ML
COPY backend/requirements-railway.txt .
RUN pip install --no-cache-dir -r requirements-railway.txt

# Copy only app code (production_vton_v2 + config)
COPY backend/app/ ./app/

ENV PYTHONUNBUFFERED=1

EXPOSE 8000

# Railway sets PORT at runtime
CMD ["sh", "-c", "uvicorn app.main_railway:app --host 0.0.0.0 --port ${PORT:-8000}"]
