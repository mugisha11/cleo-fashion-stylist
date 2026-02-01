"""
Minimal FastAPI VTON Server
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
import os
import httpx
import logging

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create app
app = FastAPI(title="Cleo Fashion VTON", version="1.0.0")

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# API Keys
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "AIzaSyCTFE6YQT1CBzztYorEie0pPPMj_t3ESTQ")
OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY", "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")

print(f"✅ Gemini Key: {GEMINI_API_KEY[:20]}...")
print(f"✅ OpenRouter Key: {OPENROUTER_API_KEY[:20]}...")


class HealthResponse(BaseModel):
    status: str
    version: str
    gpu_available: bool = True


class TryOnRequest(BaseModel):
    user_image: str
    garment_image: str
    garment_type: Optional[str] = None
    user_id: Optional[str] = None


@app.get("/", response_model=HealthResponse)
async def root():
    return HealthResponse(
        status="healthy",
        version="1.0.0",
        gpu_available=True
    )


@app.get("/health", response_model=HealthResponse)
async def health():
    return HealthResponse(
        status="healthy",
        version="1.0.0",
        gpu_available=True
    )


@app.post("/production-vton")
async def production_vton(request: TryOnRequest):
    """Production VTON endpoint"""
    logger.info(f"Received try-on request for user {request.user_id}")
    logger.info(f"Garment type: {request.garment_type}")
    
    # For now, return a simple success response
    return {
        "status": "success",
        "image": "placeholder",
        "confidence": 0.95,
        "stage": "completed"
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
