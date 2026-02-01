# AI Clothing Recognition Pipeline

A production-ready FastAPI service for recognizing clothing items from images, extracting fashion attributes, and storing structured results in Supabase.

## Features

- **Background-Aware Segmentation**: Uses YOLO + human parsing for accurate clothing detection
- **Smart Classification**: CLIP/ViT-based classification for 20+ clothing categories
- **Attribute Extraction**: Colors, patterns, fit, occasion, style
- **Confidence Validation**: Automatic retry with configurable thresholds
- **Supabase Integration**: Stores results with structured metadata

## API Endpoints

### POST `/api/v1/clothing/recognize`

Upload an image for recognition.

### POST `/api/v1/clothing/recognize-url`

Recognize from image URL.

### GET `/api/v1/clothing/health`

Health check.

## Setup

1. **Install dependencies**
   ```bash
   cd backend
   pip install -r requirements.txt
   ```

2. **Set up Supabase**
   - Run `supabase_clothing_recognition_schema.sql` in Supabase SQL Editor
   - Create `wardrobe-recognition` storage bucket
   - Set `SUPABASE_URL`, `SUPABASE_SERVICE_KEY`, `SUPABASE_STORAGE_BUCKET`

3. **Run**
   ```bash
   uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
   ```

## Configuration

See `.env.example` for environment variables.
