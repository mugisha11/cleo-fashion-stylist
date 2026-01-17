# Gemini Virtual Try-On Improvements

## Overview
This document describes the incredible virtual try-on implementation based on the official [Gemini API Image Generation documentation](https://ai.google.dev/gemini-api/docs/image-generation).

## Key Improvements

### 1. **Direct Gemini API Integration**
- **Before**: Used OpenRouter as intermediary (slower, less control)
- **After**: Direct integration with Gemini's native image generation API
- **Benefits**: Faster, more reliable, better quality, follows official patterns

### 2. **Nano Banana Models Support**
- **Nano Banana** (`gemini-2.5-flash-image`): Fast, efficient, 1024px resolution
  - Optimized for high-volume, low-latency tasks
  - Perfect for real-time try-on applications
  
- **Nano Banana Pro** (`gemini-3-pro-image-preview`): Professional quality, up to 4K
  - Advanced reasoning ("Thinking") for complex instructions
  - Higher fidelity text rendering
  - Up to 4K resolution support
  - Enable with: `GEMINI_USE_PRO_MODEL=true`

### 3. **Image Editing Method (Text-and-Image-to-Image)**
Following the official documentation pattern:
```python
contents=[
    garment_pil,      # First image: garment
    user_pil,         # Second image: user/model
    fashion_prompt    # Text instruction
]
```

This method is perfect for virtual try-on because it:
- Combines multiple images (garment + user)
- Uses text instructions for precise control
- Generates realistic results with natural lighting
- Maintains original pose and facial features

### 4. **Image Configuration**
Added support for aspect ratio control:
- Auto-detects aspect ratio from user image
- Supports standard ratios: 1:1, 4:3, 16:9, 2:3, 3:2, etc.
- For Pro model: Can specify imageSize (1K, 2K, 4K)

### 5. **Improved Prompt Engineering**
Professional try-on prompts that:
- Clearly specify garment from first image
- Apply to person in second image
- Maintain pose, facial features, body proportions
- Preserve natural lighting and shadows
- Ensure realistic fabric draping
- Keep background consistent

### 6. **Better Error Handling**
- Proper response parsing using `part.as_image()` method
- Fallback to raw data extraction if needed
- Clear error messages with context
- OpenRouter fallback if direct API fails

### 7. **SDK-First Approach**
- Uses Gemini SDK when available (preferred method)
- Falls back to REST API if SDK unavailable
- Both methods follow official documentation exactly

## Implementation Details

### File: `backend/app/stages/generation.py`
- Updated to follow official Gemini API documentation
- Supports both Nano Banana and Nano Banana Pro
- Implements Image Editing method for try-on
- Auto-detects aspect ratio
- Better error handling and logging

### File: `backend/app/api/try_on_compat.py`
- Updated to use direct Gemini API (Stage5ImageGeneration)
- Falls back to OpenRouter if direct API fails
- Better integration with Flutter app format

### File: `backend/app/core/config.py`
- Added `GEMINI_USE_PRO_MODEL` setting
- Enables switching between fast (Flash) and quality (Pro) models

## Usage

### Basic Usage (Fast - Nano Banana)
```python
stage5 = Stage5ImageGeneration(use_pro_model=False)
result = await stage5.execute(
    user_image=user_img,
    garment_image=garment_img,
    prompt=synthesized_prompt,
    garment_type="shirt"
)
```

### High Quality Usage (Pro - Nano Banana Pro)
```python
stage5 = Stage5ImageGeneration(use_pro_model=True)
result = await stage5.execute(
    user_image=user_img,
    garment_image=garment_img,
    prompt=synthesized_prompt,
    garment_type="dress",
    aspect_ratio="16:9"  # Optional
)
```

### Environment Variables
```bash
# Required
GEMINI_API_KEY=your_api_key

# Optional - Use Pro model for high quality
GEMINI_USE_PRO_MODEL=true

# Optional - Override model
GEMINI_MODEL=gemini-3-pro-image-preview
```

## API Endpoints

### `/try-on` (Flutter Compatibility)
- Accepts Flutter app request format
- Uses direct Gemini API for best results
- Falls back to OpenRouter if needed

### `/api/tryon` (Production)
- Full 6-stage pipeline
- Uses direct Gemini API
- Quality scoring included

### `/api/v1/tryon/production` (5-Stage Pipeline)
- Hard pipeline with multi-garment support
- Uses direct Gemini API
- Sequential garment layering

## Technical Details

### Image Generation Flow
1. **Input**: User image + Garment image + Text prompt
2. **Processing**: Gemini combines images using Image Editing method
3. **Output**: Professional try-on result with:
   - Natural lighting and shadows
   - Realistic fabric draping
   - Preserved pose and facial features
   - Consistent background

### Response Handling
- Uses `part.as_image()` method (official SDK method)
- Falls back to raw data extraction if needed
- Proper error messages for debugging

### Aspect Ratio Support
- Auto-detects from user image dimensions
- Maps to closest standard ratio
- Supports: 1:1, 4:3, 16:9, 2:3, 3:2, 9:16, 21:9

## Performance

### Nano Banana (Flash)
- **Speed**: Fast (optimized for low latency)
- **Resolution**: 1024px (various aspect ratios)
- **Use Case**: Real-time try-on, high volume

### Nano Banana Pro
- **Speed**: Slower (advanced reasoning)
- **Resolution**: Up to 4K (1K, 2K, 4K options)
- **Use Case**: Professional asset production, high quality

## References

- [Official Gemini API Image Generation Docs](https://ai.google.dev/gemini-api/docs/image-generation)
- [Nano Banana Models](https://ai.google.dev/gemini-api/docs/image-generation#model-selection)
- [Image Editing Method](https://ai.google.dev/gemini-api/docs/image-generation#image-editing-text-and-image-to-image)
- [Image Configuration](https://ai.google.dev/gemini-api/docs/image-generation#image-configuration)

## Next Steps

1. Test with various garment types
2. Tune prompts for specific use cases
3. Monitor performance and quality metrics
4. Consider Pro model for premium features
5. Add aspect ratio preferences from user input

## Summary

This implementation follows the official Gemini API documentation exactly, providing:
- ✅ Direct API integration (faster, more reliable)
- ✅ Support for both fast and quality models
- ✅ Professional try-on results
- ✅ Better error handling
- ✅ Aspect ratio control
- ✅ Improved prompt engineering

The virtual try-on now uses Gemini's native image generation capabilities for incredible, realistic results! 🎨✨
