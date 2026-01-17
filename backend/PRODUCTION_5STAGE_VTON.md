# Production 5-Stage Hard Pipeline Virtual Try-On System

## Overview

This is a **production-grade virtual try-on system** built to commercial standards (Amazon, Google, Snapchat). It uses a **5-stage hard pipeline** with deterministic enforcement, not model guesswork.

## Architecture

### 5-Stage Hard Pipeline

```
User Image + Garment Images
    ↓
[STAGE 1] Vision Reasoning (GPT-4.1 via OpenRouter)
    ↓
[STAGE 2] Body Understanding (MediaPipe - LOCAL, FREE)
    ↓
[STAGE 3] Constraint Engine (CODE ONLY)
    ↓
[STAGE 4] Prompt Synthesis (GPT-4.1-mini)
    ↓
[STAGE 5] Image Generation (Gemini Imagen)
    ↓
Quality Gates
    ↓
Result Image
```

### Stage Details

#### Stage 1: Vision Reasoning
- **Technology**: GPT-4.1 via OpenRouter
- **Purpose**: Understand garments and placement logic
- **Output**: Strict JSON with garment analysis
- **Validation**: Confidence >= 0.9 required, ambiguous garments rejected

#### Stage 2: Body Understanding
- **Technology**: MediaPipe Pose + Selfie Segmentation (LOCAL, FREE)
- **Purpose**: Lock the human body permanently
- **Output**: Pose keypoints + immutable segmentation masks
- **Locked Regions**: Face, hair, hands (never editable)

#### Stage 3: Constraint Engine
- **Technology**: Code-only rules (NO AI)
- **Purpose**: Convert AI reasoning into enforceable law
- **Rules**: Hardcoded region mappings (tops → torso/arms, pants → hips/legs, etc.)
- **Enforcement**: AI suggestions CANNOT override code rules

#### Stage 4: Prompt Synthesis
- **Technology**: GPT-4.1-mini via OpenRouter
- **Purpose**: Generate Gemini-safe instruction
- **Output**: Plain text with explicit constraints, no creativity

#### Stage 5: Image Generation
- **Technology**: Gemini Imagen
- **Purpose**: Final controlled image synthesis
- **Requirements**: Original user image as base, prompt from Stage 4, constraints respected

### Multi-Garment Sequential Layering

Garments are applied **sequentially** in order:
1. Tops
2. Pants
3. Jacket
4. Shoes

Each step:
- Re-locks face & pose
- Uses previous image as base
- Re-validates constraints

## Directory Structure

```
backend/
 ├── app/
 │   ├── api/
 │   │   └── tryon.py          # API endpoint
 │   ├── stages/
 │   │   ├── reasoning.py      # Stage 1
 │   │   ├── body.py           # Stage 2
 │   │   ├── constraints.py    # Stage 3
 │   │   ├── prompt.py         # Stage 4
 │   │   └── generation.py    # Stage 5
 │   ├── core/
 │   │   ├── masks.py          # Mask management
 │   │   ├── quality.py        # Quality gates
 │   │   └── utils.py          # Utilities
 │   └── main.py
```

## Installation

### Dependencies

```bash
pip install fastapi uvicorn pydantic
pip install opencv-python numpy pillow
pip install mediapipe  # LOCAL, FREE
pip install httpx  # For API calls
pip install insightface  # Optional, for face similarity
```

### Environment Variables

```bash
# OpenRouter (for GPT-4.1 and GPT-4.1-mini)
OPENROUTER_API_KEY=your_openrouter_key

# Gemini (for Imagen)
GEMINI_API_KEY=your_gemini_key

# Optional: InsightFace (for face similarity)
INSIGHTFACE_MODEL_PATH=./models/insightface
```

## Usage

### API Endpoint

```python
POST /api/v1/tryon/production

Request:
{
  "user_image_url": "https://...",
  "garment_image_urls": ["https://...", "https://..."],
  "garment_ids": ["garment_1", "garment_2"],  # Optional
  "max_retries": 2
}

Response:
{
  "success": true,
  "message": "Virtual try-on completed successfully",
  "result_image_url": "https://...",
  "result_image_base64": "...",
  "metrics": {
    "face_similarity": 0.98,
    "pose_deviation": 2.5,
    "garment_coverage": 0.15
  },
  "garments_applied": ["garment_1", "garment_2"]
}
```

### Python Usage

```python
from app.stages.reasoning import Stage1VisionReasoning
from app.stages.body import Stage2BodyUnderstanding
from app.stages.constraints import Stage3ConstraintEngine
from app.stages.prompt import Stage4PromptSynthesis
from app.stages.generation import Stage5ImageGeneration
import cv2

# Load images
user_image = cv2.imread("user.jpg")
garment_image = cv2.imread("garment.jpg")

# Initialize stages
stage1 = Stage1VisionReasoning()
stage2 = Stage2BodyUnderstanding()
stage3 = Stage3ConstraintEngine()
stage4 = Stage4PromptSynthesis()
stage5 = Stage5ImageGeneration()

# Execute pipeline
stage1_result = await stage1.execute(user_image, [garment_image])
stage2_result = stage2.execute(user_image)
constraints = stage3.execute(stage1_result.garments, stage2_result.body_masks)
prompt = await stage4.execute(...)
result_image = await stage5.execute(user_image, garment_image, prompt, "top")
```

## Quality Gates

After generation, the system validates:

1. **Face Similarity** >= 0.98
2. **Pose Deviation** <= threshold
3. **Garment Coverage** >= minimum
4. **Forbidden Regions** unchanged

If any gate fails:
- Retry up to 2 times
- Then REJECT with structured error

## Constraints

### Hardcoded Rules

```python
RULES = {
    "top": {
        "allowed_regions": ["torso", "arms"],
        "forbidden_regions": ["face", "hair", "hands", "hips", "legs", "feet"]
    },
    "pants": {
        "allowed_regions": ["hips", "legs"],
        "forbidden_regions": ["face", "hair", "hands", "torso", "arms", "feet"]
    },
    "jacket": {
        "allowed_regions": ["torso", "arms"],
        "forbidden_regions": ["face", "hair", "hands", "hips", "legs", "feet"]
    },
    "shoes": {
        "allowed_regions": ["feet"],
        "forbidden_regions": ["face", "hair", "hands", "torso", "arms", "hips", "legs"]
    }
}

LOCKED_REGIONS = ["face", "hair", "hands"]  # NEVER EDITABLE
```

## Error Handling

All stages return structured errors:
- `ValueError`: Invalid input or processing failure
- `ConstraintViolation`: Constraint engine violation
- `QualityGateFailure`: Quality gate failure
- `HTTPException`: API-level errors

No silent fallbacks. No hallucinated success.

## Development Rules

1. **Every stage returns typed objects**
2. **Every failure returns structured errors**
3. **No silent fallbacks**
4. **No hallucinated success**
5. **Code must be production-ready**

## Forbidden Technologies

- ❌ Stable Diffusion
- ❌ Free image models
- ❌ "One-prompt" generation
- ❌ Letting any model decide placement alone

## Testing

```bash
# Run tests
pytest tests/

# Run with coverage
pytest --cov=app tests/
```

## Production Deployment

1. Set environment variables
2. Install dependencies
3. Deploy FastAPI app (uvicorn, gunicorn, etc.)
4. Monitor quality gate failures
5. Log all pipeline stages

## License

Proprietary - Production System
