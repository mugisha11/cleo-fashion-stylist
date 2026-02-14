# Root Dockerfile - builds the Python FastAPI backend from backend/
# Railway uses this when building from repo root (avoids Node.js detection)
FROM python:3.10-slim

RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    libopenblas-dev \
    liblapack-dev \
    libx11-dev \
    libgtk-3-dev \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    libv4l-dev \
    libxvidcore-dev \
    libx264-dev \
    libjpeg-dev \
    libpng-dev \
    libtiff-dev \
    libatlas-base-dev \
    python3-dev \
    wget \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install dlib==19.24.2

COPY backend/app/ ./app/

RUN mkdir -p /tmp/vton

ENV PYTHONUNBUFFERED=1
ENV USE_GPU=False
ENV TEMP_DIR=/tmp/vton

EXPOSE 8000

# Railway sets PORT at runtime
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000} --workers 1"]
