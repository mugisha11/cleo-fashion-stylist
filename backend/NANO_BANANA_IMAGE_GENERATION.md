# Nano Banana Image Generation - How It Works

## ✅ Yes, Nano Banana Returns Generated Images!

**Nano Banana** (Gemini 2.5 Flash Image) **DOES support image generation** and returns images in the response.

## How It Works

### Direct Gemini API (Recommended)

Nano Banana should be accessed via **direct Gemini API**, not OpenRouter:

```python
POST https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent
```

**Response Format:**
```json
{
  "candidates": [{
    "content": {
      "parts": [{
        "inlineData": {
          "mimeType": "image/png",
          "data": "base64_encoded_image_data..."
        }
      }]
    }
  }]
}
```

### Image Extraction

The generated image is returned as **base64-encoded data** in the `inlineData.data` field.

## Current Implementation

### ✅ Working: Direct Gemini API
- **File**: `backend/app/stages/generation.py`
- **Class**: `Stage5ImageGeneration`
- **Method**: Uses direct Gemini API
- **Model**: `gemini-2.5-flash-image` (Nano Banana)
- **Status**: ✅ Should work correctly

### ⚠️ Problem: OpenRouter Route
- **File**: `backend/app/api/tryon.py`
- **Function**: `generate_tryon_via_openrouter()`
- **Issue**: OpenRouter may not support `gemini-2.5-flash-image` properly
- **Models tried**: `google/gemini-2.0-flash-exp`, etc. (not Nano Banana)

## Fix Applied

Updated `/tryon` endpoint to:
1. **Use direct Gemini API first** (Nano Banana)
2. **Fallback to OpenRouter** if direct API fails

This ensures Nano Banana is used correctly and returns images.

## Testing

To verify Nano Banana returns images:

```python
# Test direct API
from app.stages.generation import Stage5ImageGeneration
import cv2
import numpy as np

stage5 = Stage5ImageGeneration(use_pro_model=False)
# Create test images
user_img = np.ones((512, 512, 3), dtype=np.uint8) * 255
garment_img = np.ones((512, 512, 3), dtype=np.uint8) * 128

result = await stage5.execute(
    user_image=user_img,
    garment_image=garment_img,
    prompt="Redraw person wearing the clothing",
    garment_type="shirt"
)

# result should be a numpy array (the generated image)
print(f"Generated image shape: {result.shape}")
```

## Summary

✅ **Nano Banana DOES return generated images**
✅ **Use direct Gemini API** (not OpenRouter)
✅ **Image is in `inlineData.data`** field as base64
✅ **Fix applied**: `/tryon` now uses direct API first

The endpoint should now work correctly with Nano Banana!
