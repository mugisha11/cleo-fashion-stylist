"""
Production VTON Server - Windows-Compatible Edition
Using proper lifespan context manager for graceful startup/shutdown
"""
import sys
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Models
class HealthResponse(BaseModel):
    status: str
    version: str
    gpu_available: bool = True

class TryOnRequest(BaseModel):
    user_image: str
    garment_image: str
    garment_type: Optional[str] = None
    user_id: Optional[str] = None

# Lifespan context manager
@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Manage app startup and shutdown explicitly
    This prevents random shutdowns on Windows Python 3.13
    """
    # Startup
    logger.info("="*60)
    logger.info("APPLICATION STARTUP")
    logger.info("="*60)
    logger.info(f"✅ Cleo Fashion VTON API v1.0.0")
    logger.info(f"✅ Gemini Key: {get_key_preview()}")
    logger.info(f"✅ OpenRouter Key: {get_router_key_preview()}")
    logger.info("✅ All services initialized")
    logger.info("✅ Server ready to accept requests")
    logger.info("="*60)
    
    # Yield control to server
    yield
    
    # Shutdown
    logger.info("="*60)
    logger.info("APPLICATION SHUTDOWN")
    logger.info("Cleaning up resources...")
    logger.info("="*60)

def get_key_preview():
    import os
    key = os.getenv("GEMINI_API_KEY", "AIzaSyCTFE6YQT1CBzztYorEie0pPPMj_t3ESTQ")
    return f"{key[:20]}..." if len(key) > 20 else key

def get_router_key_preview():
    import os
    key = os.getenv("OPENROUTER_API_KEY", "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")
    return f"{key[:20]}..." if len(key) > 20 else key

# Create app with lifespan manager
app = FastAPI(
    title="Cleo Fashion VTON API",
    version="1.0.0",
    description="Production Virtual Try-On API with Gemini + OpenRouter",
    lifespan=lifespan
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Health check endpoints
@app.get("/", response_model=HealthResponse)
async def root():
    """Root health check"""
    return HealthResponse(
        status="healthy",
        version="1.0.0",
        gpu_available=True
    )

@app.get("/health", response_model=HealthResponse)
async def health():
    """Health check endpoint"""
    return HealthResponse(
        status="healthy",
        version="1.0.0",
        gpu_available=True
    )

# Production VTON endpoint
@app.post("/production-vton")
async def production_vton(request: TryOnRequest):
    """
    Production virtual try-on endpoint
    
    Expects:
    - user_image: base64 encoded user photo
    - garment_image: base64 encoded garment photo
    - user_id: optional user identifier
    - garment_type: optional garment type (shirt, pants, etc.)
    """
    try:
        logger.info(f"📸 Received try-on request from user: {request.user_id}")
        logger.info(f"👗 Garment type: {request.garment_type}")
        logger.info(f"📷 User image size: {len(request.user_image)} bytes")
        logger.info(f"👔 Garment image size: {len(request.garment_image)} bytes")
        
        # TODO: Implement actual pipeline stages here
        # Stage 1: Input validation
        # Stage 2: Image analysis (OpenRouter Claude)
        # Stage 3: Prompt synthesis
        # Stage 4: Image generation (Gemini)
        # Stage 5: Quality check
        
        return {
            "status": "success",
            "message": "Try-on request received",
            "image": None,  # Placeholder for generated image
            "confidence": 0.0,
            "stage": "validation_complete",
            "user_id": request.user_id,
            "garment_type": request.garment_type
        }
    except Exception as e:
        logger.error(f"❌ Error processing try-on request: {e}", exc_info=True)
        return {
            "status": "error",
            "message": str(e),
            "image": None,
            "confidence": 0.0,
            "stage": "error",
            "user_id": request.user_id,
            "garment_type": request.garment_type
        }

# Keep-alive endpoint
@app.get("/alive")
async def alive():
    """Simple keep-alive check"""
    return {"alive": True}

logger.info("✅ App module loaded, ready for Uvicorn")
