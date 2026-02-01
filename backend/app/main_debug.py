"""
Minimal Production VTON Server - Debug Edition
Testing exact FastAPI + Uvicorn behavior on Windows Python 3.13
"""
import sys
import asyncio
import logging

# Configure logging FIRST
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("main")
logger.info("="*60)
logger.info("STARTUP: Python version: " + sys.version)
logger.info("STARTUP: Event loop policy before FastAPI import")

try:
    # FastAPI must be imported after logging setup
    from fastapi import FastAPI
    from fastapi.middleware.cors import CORSMiddleware
    from pydantic import BaseModel
    from typing import Optional
    import os
    
    logger.info("STARTUP: FastAPI imported successfully")
    
    # Create app IMMEDIATELY
    app = FastAPI(
        title="Cleo Fashion VTON",
        version="1.0.0",
        docs_url="/docs",
        openapi_url="/openapi.json"
    )
    logger.info("STARTUP: FastAPI app created")
    
    # Add CORS
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    logger.info("STARTUP: CORS middleware added")
    
    # Define models
    class HealthResponse(BaseModel):
        status: str
        version: str
        gpu_available: bool = True
    
    # Define endpoints BEFORE router includes
    @app.get("/", response_model=HealthResponse)
    async def root():
        logger.info("ENDPOINT: GET /")
        return HealthResponse(
            status="healthy",
            version="1.0.0",
            gpu_available=True
        )
    
    @app.get("/health", response_model=HealthResponse)
    async def health():
        logger.info("ENDPOINT: GET /health")
        return HealthResponse(
            status="healthy",
            version="1.0.0",
            gpu_available=True
        )
    
    logger.info("STARTUP: All endpoints defined")
    
    # Now try importing routers - ONLY IF NEEDED
    try:
        logger.info("STARTUP: About to import production_vton_v2 router...")
        from backend.app.api import production_vton_v2
        logger.info(f"STARTUP: Router imported, has {len(production_vton_v2.router.routes)} routes")
        app.include_router(production_vton_v2.router)
        logger.info("STARTUP: Router included successfully")
    except Exception as e:
        logger.error(f"STARTUP: Failed to import router: {e}", exc_info=True)
        # Continue without this router
        pass
    
    logger.info("STARTUP: App configuration complete - ready for Uvicorn")
    
except Exception as e:
    logger.critical(f"STARTUP FAILED: {e}", exc_info=True)
    sys.exit(1)


if __name__ == "__main__":
    logger.info("MAIN: Starting Uvicorn...")
    import uvicorn
    
    # Explicit event loop policy for Windows Python 3.13
    if sys.platform == "win32":
        logger.info("MAIN: Windows detected, setting ProactorEventLoop")
        asyncio.set_event_loop_policy(asyncio.WindowsProactorEventLoopPolicy())
    
    try:
        uvicorn.run(
            app,
            host="0.0.0.0",
            port=8001,
            log_level="debug",
            access_log=True,
        )
    except KeyboardInterrupt:
        logger.info("MAIN: Received KeyboardInterrupt, shutting down")
    except Exception as e:
        logger.error(f"MAIN: Uvicorn failed: {e}", exc_info=True)
        sys.exit(1)
