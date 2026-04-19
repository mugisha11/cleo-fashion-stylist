# Cleo Fashion VTON Backend

Production-grade Virtual Try-On (VTON) API service with face preservation and quality assurance.

## Features

- ✅ **Face Preservation**: 98%+ similarity guarantee
- ✅ **Quality Control**: Automatic retry on quality failures
- ✅ **Production-Ready**: Docker deployment, error handling, logging
- ✅ **Scalable**: Modular architecture, GPU support
- ✅ **Supabase Integration**: Storage and metadata management

## Architecture

```
backend/
├── app/
│   ├── main.py              # FastAPI application
│   ├── api/
│   │   ├── tryon.py         # Try-on endpoints
│   │   └── recommend.py     # Recommendation endpoints
│   ├── services/
│   │   ├── pose.py          # MediaPipe pose estimation
│   │   ├── parsing.py       # Human parsing (SCHP)
│   │   ├── face_lock.py     # Face preservation (CRITICAL)
│   │   ├── viton.py         # VTON inference
│   │   └── storage.py       # Supabase storage
│   ├── core/
│   │   ├── config.py        # Configuration
│   │   ├── quality.py       # Quality checks
│   │   └── retry.py         # Retry logic
│   └── models/
│       └── schemas.py        # Pydantic schemas
├── requirements.txt
├── Dockerfile
└── .env.example
```

## Setup

### 1. Install Dependencies

```bash
pip install -r requirements.txt
```

### 2. Configure Environment

Copy `.env.example` to `.env` and configure:

```bash
cp .env.example .env
# Edit .env with your Supabase credentials
```

### 3. Run Server

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 4. Docker Deployment

```bash
docker build -t vton-api .
docker run -p 8000:8000 --env-file .env vton-api
```

## API Endpoints

### POST `/try-on`

Process virtual try-on with face preservation.

**Request:**
```json
{
  "user_image_url": "https://...",
  "cloth_image_url": "https://...",
  "source": "wardrobe",
  "user_id": "user123",
  "preserve_face": true,
  "preserve_resolution": true
}
```

**Response:**
```json
{
  "success": true,
  "result_url": "https://...",
  "session_id": "uuid",
  "face_similarity": 0.99,
  "quality_scores": {
    "face_similarity": 0.99,
    "sharpness": 0.85,
    "pose_consistency": 0.92,
    "clothing_coverage": 0.95
  }
}
```

### POST `/recommend`

Generate outfit recommendations.

**Request:**
```json
{
  "prompt": "wedding outfit",
  "wardrobe_only": false,
  "user_id": "user123"
}
```

## Online Product Sources

The backend uses **real-time fashion retailer scraping** for authentic product data:

- **Live retailer data** – Direct scraping from ASOS, H&M, and Zara
- **Real product images** – Actual photos from retailer websites
- **Direct buy links** – Links go straight to product purchase pages
- **Always current** – No stale static data, always fresh products

### Supported Retailers

- **ASOS** (`asos.com`) – Global fashion retailer
- **H&M** (`hm.com`) – Fast fashion brand
- **Zara** (`zara.com`) – Premium fashion retailer

### Fallback Search Order

When OpenRouter returns fewer than requested products:

1. **Google Retail API** (if `GOOGLE_RETAIL_API_KEY` is set)
2. **Supabase Catalog** (if connected to products table)
3. **Fashion Scraper Service** (real-time retailer scraping)
4. **Serper.dev Search** (if `SERPER_API_KEY` is set)
5. **Custom Retailer Scrapers** (Zara/H&M direct scraping)
6. **Google Images** (free web scraping, no API key needed)
7. **Bing Images** (free web scraping, no API key needed)

This ensures authentic product images and direct purchase links are always returned.

## Quality Assurance

The system automatically:

1. **Checks face similarity** (must be ≥ 98%)
2. **Validates image sharpness** (no blur)
3. **Verifies pose consistency** (body alignment preserved)
4. **Ensures clothing coverage** (no missing pixels)
5. **Retries up to 3 times** if any check fails

## Face Preservation

The face locking system:

- Detects face region automatically
- Creates protection mask (face + hair)
- Locks face pixels (NO modifications)
- Verifies 98%+ similarity before returning
- Rejects results that fail face check

## Production Deployment

### Environment Variables

- `SUPABASE_URL`: Your Supabase project URL
- `SUPABASE_SERVICE_KEY`: Service role key
- `USE_GPU`: Enable GPU acceleration
- `FACE_SIMILARITY_THRESHOLD`: Minimum face similarity (default: 0.98)
- `GOOGLE_RETAIL_API_KEY`: Optional Google Cloud Retail API key for live product catalog fallback
- `GOOGLE_RETAIL_PROJECT_ID`: Optional Google Cloud project ID for Retail API requests
- `GOOGLE_RETAIL_LOCATION`: Optional Retail API location (default: `global`)
- `GOOGLE_RETAIL_CATALOG`: Optional Retail catalog name (default: `default_catalog`)
- `GOOGLE_RETAIL_BRANCH`: Optional Retail branch ID (default: `0`)
- `GOOGLE_RETAIL_PLACEMENT`: Optional Retail placement name (default: `default_search`)

### GPU Support

For GPU acceleration:

```bash
# Install CUDA-enabled PyTorch
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu118
```

Set `USE_GPU=True` in `.env`

## Model Integration

To use actual VTON models:

1. Download HR-VITON or diffusion model
2. Place in `./models/hr-viton/`
3. Update `VTON_MODEL_PATH` in `.env`
4. Implement model loading in `services/vton.py`

## License

Proprietary - Cleo Fashion App

