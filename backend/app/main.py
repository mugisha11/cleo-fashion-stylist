"""
FastAPI Main Application
Production-grade VTON API server
"""
import logging
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .core.config import settings
from .core.validation import validate_all_configurations
from .core.exceptions import VTONException
from .api import recommend, clothing_recognition, openai_api
from .api import tryon as tryon_api
from .api import try_on_compat
from .models.schemas import HealthResponse
from .services.daily_recommendation_scheduler import DailyRecommendationScheduler
from fastapi import Request
from fastapi.responses import JSONResponse

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


# Global exception handler for VTON exceptions
@app.exception_handler(VTONException)
async def vton_exception_handler(request: Request, exc: VTONException):
    """Handle VTON exceptions with proper error codes"""
    return JSONResponse(
        status_code=exc.http_status,
        content=exc.to_dict()
    )

# Include routers
app.include_router(recommend.router)
app.include_router(clothing_recognition.router)
app.include_router(openai_api.router)  # OpenAI API endpoints
app.include_router(tryon_api.router)  # Simple Virtual Try-On API (OpenRouter + Gemini Nano Banana)
# try_on_compat router disabled to avoid conflicts - Flutter uses /tryon from tryon.py
# app.include_router(try_on_compat.router)  # Flutter compatibility endpoint


@app.get("/", response_model=HealthResponse)
async def health_check():
    """Health check endpoint"""
    import torch
    return HealthResponse(
        status="healthy",
        version=settings.API_VERSION,
        gpu_available=torch.cuda.is_available() and settings.USE_GPU
    )


# Initialize daily recommendation scheduler
recommendation_scheduler = DailyRecommendationScheduler()

@app.get("/health", response_model=HealthResponse)
async def health_check_alias():
    """Health check endpoint (alias for /)"""
    return await health_check()


@app.on_event("startup")
async def startup_event():
    """Initialize services on startup"""
    logger.info(f"Starting {settings.API_TITLE} v{settings.API_VERSION}")
    logger.info(f"GPU Available: {settings.USE_GPU}")
    logger.info(f"Debug Mode: {settings.DEBUG}")
    
    # CRITICAL: Validate AI configuration before starting
    try:
        await validate_all_configurations()
    except VTONException as e:
        logger.error(f"❌ Configuration validation failed: {e.message}")
        logger.error(f"   Details: {e.details}")
        logger.error("Server will not start with invalid configuration.")
        raise  # Fail fast - don't start server with invalid config
    
    # Start recommendation scheduler in background
    import asyncio
    asyncio.create_task(recommendation_scheduler.start())
    logger.info("Background tasks started")


@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on shutdown"""
    recommendation_scheduler.stop()
    logger.info("Background tasks stopped")
    logger.info("Shutting down API server")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.DEBUG
    )

