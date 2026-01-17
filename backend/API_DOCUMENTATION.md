# Virtual Try-On API Documentation

## Overview

Production-grade Virtual Try-On API using OpenRouter.ai for multimodal AI tasks and Gemini for image generation.

## Endpoint

**POST** `/api/tryon`

## Authentication

No authentication required (add as needed for production).

## Request

### Headers

```
Content-Type: application/json
```

### Body

```json
{
  "user_image_url": "https://example.com/user-photo.jpg",
  "garment_image_urls": [
    "https://example.com/garment1.jpg",
    "https://example.com/garment2.jpg"
  ],
  "user_id": "user123",
  "trace_id": "optional-trace-id-for-logging"
}
```

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `user_image_url` | string | Yes* | URL of user photo |
| `user_image_base64` | string | Yes* | Base64 encoded user photo (alternative to URL) |
| `garment_image_urls` | array[string] | Yes | List of clothing image URLs |
| `user_id` | string | No | User ID for tracking |
| `trace_id` | string | No | Optional trace ID for logging |

*Either `user_image_url` or `user_image_base64` must be provided.

## Response

### Success Response (200 OK)

```json
{
  "status": "success",
  "result_image_url": "https://cdn.example.com/result.jpg",
  "result_image_base64": "base64-encoded-image-string",
  "metrics": {
    "face_similarity": 0.98,
    "garment_coverage": 0.15,
    "total_duration": 12.5,
    "garment_analysis": {
      "type": "T-shirt",
      "placement": "upper_body",
      "confidence": 0.96
    }
  },
  "trace_id": "550e8400-e29b-41d4-a716-446655440000",
  "stages": {
    "stage1": {
      "duration": 0.5,
      "status": "success"
    },
    "stage2": {
      "duration": 2.1,
      "status": "success",
      "garment_type": "T-shirt",
      "placement": "upper_body",
      "confidence": 0.96
    },
    "stage3": {
      "duration": 1.2,
      "status": "success",
      "garment_mask_coverage": 0.25,
      "allowed_mask_coverage": 0.30
    },
    "stage4": {
      "duration": 1.5,
      "status": "success",
      "prompt_length": 245
    },
    "stage5": {
      "duration": 6.2,
      "status": "success",
      "image_shape": [1024, 768, 3]
    },
    "stage6": {
      "duration": 1.0,
      "status": "success",
      "metrics": {
        "face_similarity": 0.98,
        "garment_coverage": 0.15
      }
    }
  }
}
```

### Error Response (400/500)

```json
{
  "status": "failed",
  "trace_id": "550e8400-e29b-41d4-a716-446655440000",
  "error": "Garment analysis confidence 0.85 below threshold 0.90",
  "stage_failed": "semantic_analysis"
}
```

## Pipeline Stages

### Stage 1: Image Validation
- Downloads and validates user and garment images
- Converts to appropriate format
- Duration: ~0.5s

### Stage 2: Semantic Analysis
- Uses OpenRouter vision models to analyze garments
- Returns structured JSON with:
  - Garment type
  - Placement regions
  - Confidence scores
  - Pose keypoints
  - Reasoning
- Duration: ~2-3s

### Stage 3: Mask Generation
- Removes background from garment (Remove.bg API)
- Segments garment using U²-Net/SAM
- Parses body regions (MediaPipe)
- Creates allowed/forbidden masks
- Duration: ~1-2s

### Stage 4: Prompt Synthesis
- Generates precise prompt for image generation
- Includes explicit constraints
- Duration: ~1-2s

### Stage 5: Image Generation
- Uses Gemini via OpenRouter to generate composite
- Falls back to alternative models if needed
- Duration: ~5-10s

### Stage 6: Quality Scoring
- Validates face similarity
- Checks garment alignment
- Verifies forbidden regions unchanged
- Duration: ~1s

## Example cURL Request

```bash
curl -X POST http://localhost:8000/api/tryon \
  -H "Content-Type: application/json" \
  -d '{
    "user_image_url": "https://example.com/user.jpg",
    "garment_image_urls": ["https://example.com/shirt.jpg"],
    "user_id": "user123"
  }'
```

## Example Python Request

```python
import requests
import json

url = "http://localhost:8000/api/tryon"
payload = {
    "user_image_url": "https://example.com/user.jpg",
    "garment_image_urls": ["https://example.com/shirt.jpg"],
    "user_id": "user123"
}

response = requests.post(url, json=payload)
result = response.json()

if result["status"] == "success":
    print(f"Result URL: {result['result_image_url']}")
    print(f"Face Similarity: {result['metrics']['face_similarity']}")
else:
    print(f"Error: {result['error']}")
    print(f"Failed at: {result['stage_failed']}")
```

## Error Handling

The API provides detailed error information:

- **400 Bad Request**: Invalid input (missing images, invalid URLs)
- **500 Internal Server Error**: Processing failure

All errors include:
- `error`: Human-readable error message
- `stage_failed`: Which stage failed
- `trace_id`: For debugging

## Rate Limiting

Currently no rate limiting (add as needed for production).

## Environment Variables

Required environment variables:

```bash
OPENROUTER_API_KEY=your_openrouter_key
REMOVE_BG_API_KEY=your_remove_bg_key
GEMINI_API_KEY=your_gemini_key  # Optional, uses OpenRouter by default
SUPABASE_URL=your_supabase_url  # For storage
SUPABASE_KEY=your_supabase_key
```

## Best Practices

1. **Image URLs**: Use CDN URLs for faster processing
2. **Trace IDs**: Include trace IDs for debugging
3. **Error Handling**: Always check `status` field
4. **Timeouts**: Set appropriate timeouts (recommended: 60s)
5. **Retries**: Implement retry logic for transient failures

## Support

For issues, include:
- Request payload
- Response body
- `trace_id` from response
