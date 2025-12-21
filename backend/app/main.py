"""
FastAPI Main Application
Production-grade VTON API server
"""
import logging
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .core.config import settings
from .api import tryon, recommend, clothing_recognition, vton_pipeline
from .models.schemas import HealthResponse

# Configure logging
logging.basicConfig(
    level=logging.INFO if not settings.DEBUG else logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

logger = logging.getLogger(__name__)

# Create FastAPI app
app = FastAPI(
    title=settings.API_TITLE,
    version=settings.API_VERSION,
    debug=settings.DEBUG
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(tryon.router)
app.include_router(recommend.router)
app.include_router(clothing_recognition.router)
app.include_router(vton_pipeline.router)  # Production pipeline endpoints


@app.get("/", response_model=HealthResponse)
async def health_check():
    """Health check endpoint"""
    import torch
    return HealthResponse(
        status="healthy",
        version=settings.API_VERSION,
        gpu_available=torch.cuda.is_available() and settings.USE_GPU
    )


@app.on_event("startup")
async def startup_event():
    """Initialize services on startup"""
    logger.info(f"Starting {settings.API_TITLE} v{settings.API_VERSION}")
    logger.info(f"GPU Available: {settings.USE_GPU}")
    logger.info(f"Debug Mode: {settings.DEBUG}")


@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on shutdown"""
    logger.info("Shutting down API server")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.DEBUG
    )

