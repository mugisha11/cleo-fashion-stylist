# AI Clothing Recognition Pipeline

A production-ready FastAPI service for recognizing clothing items from images, extracting fashion attributes, and storing structured results in Supabase.

## Features

- **Background-Aware Segmentation**: Uses YOLO + human parsing for accurate clothing detection
- **Smart Classification**: CLIP/ViT-based classification for 20+ clothing categories
- **Attribute Extraction**: 
  - Colors (dominant colors using K-means)
  - Patterns (stripes, dots, floral, solid)
  - Fit estimation (loose/regular/tight/fitted)
  - Occasion detection (casual/formal/party)
  - Style classification (vintage/minimalist/bohemian/modern)
- **Confidence Validation**: Automatic retry logic with configurable thresholds
- **Supabase Integration**: Stores results with structured metadata
- **Production-Ready**: Error handling, logging, and scalability optimizations

## API Endpoints

### POST `/api/v1/clothing/recognize`

Upload an image file for recognition.

**Request:**
- `file`: Image file (JPEG, PNG, WebP)
- `user_id` (optional): User ID for storing results
- `store_result` (optional): Whether to store in Supabase (default: true)

**Response:**
```json
{
  "success": true,
  "category": "top",
  "subcategory": "t-shirt",
  "colors": ["blue", "white"],
  "patterns": ["stripes"],
  "fit": "regular",
  "occasion": ["casual"],
  "style": "modern",
  "confidence": 0.85,
  "bbox": [100, 150, 200, 300],
  "image_url": "https://...",
  "result_id": "uuid",
  "metadata": {}
}
```

### POST `/api/v1/clothing/recognize-url`

Recognize clothing from an image URL.

**Request Body:**
```json
{
  "image_url": "https://example.com/image.jpg",
  "user_id": "user123",
  "store_result": true
}
```

### GET `/api/v1/clothing/health`

Health check endpoint.

## Setup

### 1. Install Dependencies

```bash
cd backend
pip install -r requirements.txt
```

### 2. Set Up Supabase

1. Create the `clothing_recognitions` table by running:
   ```bash
   # Copy contents of supabase_clothing_recognition_schema.sql
   # Run in Supabase SQL Editor
   ```

2. Create storage bucket for recognition images:
   - Bucket name: `wardrobe-recognition`
   - Public: Yes
   - File size limit: 10MB

3. Set environment variables:
   ```env
   SUPABASE_URL=your_supabase_url
   SUPABASE_SERVICE_KEY=your_service_key
   SUPABASE_STORAGE_BUCKET=wardrobe-recognition
   ```

### 3. Configure Models

The pipeline will automatically download models on first use:
- YOLOv8n-seg (for segmentation)
- CLIP ViT-B/32 (for classification)

For GPU support:
```bash
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu118
```

Set `USE_GPU=True` in environment variables.

### 4. Run the Server

```bash
cd backend
python -m app.main
```

Or with uvicorn:
```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

## Architecture

### Pipeline Components

1. **ImagePreprocessor**: OpenCV-based preprocessing
   - Resizing
   - Contrast enhancement
   - Background removal (GrabCut)

2. **ClothingSegmentation**: YOLO + human parsing
   - Object detection
   - Mask generation
   - Bounding box extraction

3. **ClothingClassifier**: CLIP/ViT classification
   - 20+ clothing categories
   - Confidence scoring
   - Fallback heuristics

4. **AttributeExtractor**: Fashion attribute extraction
   - Color analysis (K-means clustering)
   - Pattern detection (FFT + blob detection)
   - Fit estimation
   - Occasion/style classification

5. **ConfidenceValidator**: Quality assurance
   - Confidence thresholding
   - Retry logic
   - Error handling

### Retry Logic

The pipeline implements intelligent retry:
- Minimum confidence threshold: 0.6 (configurable)
- Max retries: 3 (configurable)
- Automatic retry with different preprocessing
- Graceful degradation on failure

## Usage Example (Flutter)

```dart
import 'package:http/http.dart' as http;
import 'dart:io';

Future<Map<String, dynamic>> recognizeClothing(File imageFile) async {
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('http://your-api/api/v1/clothing/recognize'),
  );
  
  request.files.add(
    await http.MultipartFile.fromPath('file', imageFile.path),
  );
  request.fields['user_id'] = 'user123';
  request.fields['store_result'] = 'true';
  
  var response = await request.send();
  var responseData = await response.stream.bytesToString();
  
  return jsonDecode(responseData);
}
```

## Configuration

Environment variables in `.env`:

```env
# API
DEBUG=False
API_VERSION=1.0.0

# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_KEY=your_service_key
SUPABASE_STORAGE_BUCKET=wardrobe-recognition

# Models
USE_GPU=True
GPU_DEVICE=0

# Quality
MIN_CONFIDENCE=0.6
MAX_RETRIES=3
RETRY_DELAY=1.0

# Processing
MAX_IMAGE_SIZE=2048
TEMP_DIR=/tmp/clothing-recognition
```

## Performance

- **Processing Time**: 2-5 seconds per image (CPU), 0.5-1 second (GPU)
- **Throughput**: ~10-20 images/minute (CPU), ~60-120 images/minute (GPU)
- **Memory**: ~2GB RAM (CPU), ~4GB VRAM (GPU)

## Error Handling

The pipeline handles:
- Invalid image formats
- Corrupted images
- No clothing detected
- Low confidence results
- Network failures (Supabase)
- Model loading errors

All errors are logged and return appropriate HTTP status codes.

## Future Enhancements

- [ ] Support for batch processing
- [ ] Real-time video processing
- [ ] Custom model fine-tuning
- [ ] Multi-garment detection
- [ ] Brand recognition
- [ ] Price estimation
- [ ] Style recommendations based on attributes

## License

Part of the Virtual Twin Fashion App.

