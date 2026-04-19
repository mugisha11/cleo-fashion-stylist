"""
FastAPI Main Application - PRODUCTION-GRADE VTON API SERVER
Fixed event loop handling + proper async resource lifecycle management

KEY FIXES:
1. Explicit Windows event loop policy (SelectorEventLoopPolicy, not Proactor)
2. Centralized async resource management in lifespan
3. NO module-level async client creation
4. Proper dependency injection for all services
5. Correct graceful shutdown handling
"""
import sys
import logging

# CRITICAL: Setup event loop policy BEFORE any FastAPI imports
# This must be the very first import of asyncio-related code
from .core.event_loop_config import setup_event_loop
setup_event_loop()

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from .core.config import settings
from .core.exceptions import VTONException
from .core.lifespan_manager import lifespan, get_resource_manager
from .models.schemas import HealthResponse

# Import routers (NO module-level async instantiation)
from .api import recommend, openai_api
from .api import inspiration
from .api import tryon as tryon_api
from .api import try_on_compat
from .api import link_preview
from .api import product_search
from .api import proxy_image
from .api import try_on_openai
from .api import production_vton_v2
from .api import fashion_scraper

# Optional: clothing_recognition needs torch/scikit-learn (VC++ Build Tools on Windows)
try:
    from .api import clothing_recognition
    _has_clothing_recognition = True
except Exception as e:
    _has_clothing_recognition = False
    _clothing_recognition_error = e

# Configure logging BEFORE app creation
logging.basicConfig(
    level=logging.INFO if not settings.DEBUG else logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

logger.info("="*70)
logger.info("Cleo Fashion VTON Backend - Initializing")
logger.info("="*70)
logger.info(f"Python: {sys.version}")
logger.info(f"Platform: {sys.platform}")
logger.info(f"Debug Mode: {settings.DEBUG}")



app = FastAPI(
    title=settings.API_TITLE,
    version=settings.API_VERSION,
    description="Production Virtual Try-On API with Gemini + OpenRouter",
    lifespan=lifespan  # ✅ CRITICAL: Lifespan manager handles startup/shutdown
)

logger.info("✅ FastAPI app created with lifespan manager")


# ═══════════════════════════════════════════════════════════════════════════
# CORS MIDDLEWARE
# ═══════════════════════════════════════════════════════════════════════════
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

logger.info("✅ CORS middleware configured")


# ═══════════════════════════════════════════════════════════════════════════
# EXCEPTION HANDLERS
# ═══════════════════════════════════════════════════════════════════════════
@app.exception_handler(VTONException)
async def vton_exception_handler(request: Request, exc: VTONException):
    """Handle VTON-specific exceptions with proper error codes"""
    return JSONResponse(
        status_code=exc.http_status,
        content=exc.to_dict()
    )

logger.info("✅ Exception handlers registered")


# ═══════════════════════════════════════════════════════════════════════════
# HEALTH CHECK ENDPOINTS
# ═══════════════════════════════════════════════════════════════════════════
@app.get("/", response_model=HealthResponse)
async def health_check():
    """Root health check endpoint"""
    # Torch is optional in minimal installs; don't fail health if missing
    try:
        import torch  # type: ignore
        gpu_available = torch.cuda.is_available() and settings.USE_GPU
    except Exception:
        gpu_available = False
    return HealthResponse(
        status="healthy",
        version=settings.API_VERSION,
        gpu_available=gpu_available
    )


@app.get("/health", response_model=HealthResponse)
async def health_check_alias():
    """Health check endpoint (alias)"""
    return await health_check()


@app.get("/alive")
async def keep_alive():
    """Simple keep-alive endpoint"""
    return {"alive": True, "version": settings.API_VERSION}


logger.info("✅ Health check endpoints registered")


# ═══════════════════════════════════════════════════════════════════════════
# ROUTER REGISTRATION
# ═══════════════════════════════════════════════════════════════════════════
# CRITICAL: Routers are registered AFTER app creation, not at module level
# This ensures lifespan manager is ready before any async resources are used

app.include_router(recommend.router)
logger.info("✅ Registered: recommend router")

if _has_clothing_recognition:
    app.include_router(clothing_recognition.router)
    logger.info("✅ Registered: clothing_recognition router")
else:
    logger.warning("⚠️ clothing_recognition router skipped (missing deps, e.g. torch): %s", _clothing_recognition_error)

app.include_router(openai_api.router)
app.include_router(inspiration.router)
logger.info("✅ Registered: openai_api router")

app.include_router(tryon_api.router)
logger.info("✅ Registered: tryon router")

app.include_router(link_preview.router)
logger.info("✅ Registered: link_preview router")

app.include_router(product_search.router)
logger.info("✅ Registered: product_search router")

app.include_router(proxy_image.router)
logger.info("✅ Registered: proxy_image router")

app.include_router(try_on_openai.router)
logger.info("✅ Registered: try_on_openai router")

app.include_router(production_vton_v2.router)
logger.info("✅ Registered: production_vton_v2 router")

app.include_router(fashion_scraper.router)
logger.info("✅ Registered: fashion_scraper router")

try:
    from .api import vton_pipeline
    app.include_router(vton_pipeline.router)
    logger.info("✅ Registered: vton_pipeline router")
except Exception as e:
    logger.warning("⚠️  vton_pipeline not loaded: %s", e)

# try_on_compat disabled to avoid conflicts
logger.info("⚠️  try_on_compat router DISABLED (conflicts with tryon)")


# ═══════════════════════════════════════════════════════════════════════════
# DEPENDENCY INJECTION SETUP
# ═══════════════════════════════════════════════════════════════════════════
# After app creation, inject the managed httpx client into services that need it
# This happens BEFORE lifespan startup, so it's available when routes are called

def setup_service_dependencies():
    """
    Inject managed resources into services that need them.
    Called during app startup by lifespan manager.
    """
    try:
        # Get the resource manager
        resource_mgr = get_resource_manager()
        
        # Inject httpx client into Stage5ImageGeneration
        # (used by tryon router)
        if hasattr(tryon_api, 'stage5_generation') and tryon_api.stage5_generation:
            tryon_api.stage5_generation.set_httpx_client(resource_mgr.gemini_client)
            logger.info("✅ Injected httpx client into Stage5ImageGeneration")
        
        logger.info("✅ Service dependencies injected")
        
    except Exception as e:
        logger.warning(f"⚠️  Service dependency injection: {e}")


# Store dependency setup function for lifespan manager to call
app.state.setup_service_dependencies = setup_service_dependencies


logger.info("="*70)
logger.info("✅ BACKEND INITIALIZATION COMPLETE")
logger.info("="*70)
logger.info("Waiting for lifespan startup...")
logger.info("")


if __name__ == "__main__":
    import uvicorn
    
    # For local testing: python -m backend.app.main OR uvicorn backend.app.main:app
    # Production: Use launch script (see below)
    uvicorn.run(
        "backend.app.main:app",
        host="0.0.0.0",
        port=8001,
        reload=settings.DEBUG,
        workers=1 if settings.DEBUG else 4
    )

