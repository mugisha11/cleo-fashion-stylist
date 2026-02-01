"""
FastAPI Lifespan Manager
Centralized management of all async resources (httpx clients, connections, etc.)

CRITICAL: All async resources MUST be created here, not at module level
This ensures proper cleanup on shutdown and prevents orphaned tasks
"""
import logging
import asyncio
from contextlib import asynccontextmanager
from typing import AsyncGenerator
import httpx
from fastapi import FastAPI

logger = logging.getLogger(__name__)


class AsyncResourceManager:
    """
    Manages all async resources for the FastAPI application.
    This prevents orphaned async tasks and ensures proper cleanup.
    """
    
    def __init__(self):
        self.httpx_client: httpx.AsyncClient = None
        self.gemini_client: httpx.AsyncClient = None
        self.openrouter_client: httpx.AsyncClient = None
        self.is_initialized = False
    
    async def initialize(self):
        """
        Initialize all async resources.
        Called during FastAPI startup.
        """
        if self.is_initialized:
            logger.warning("AsyncResourceManager already initialized, skipping")
            return
        
        logger.info("Initializing async resources...")
        
        try:
            # Create shared httpx client for API calls
            # Timeout: 30s for most APIs, 60s for image generation
            self.httpx_client = httpx.AsyncClient(
                timeout=httpx.Timeout(30.0, connect=10.0),
                limits=httpx.Limits(max_keepalive_connections=100)
            )
            logger.info("✅ Main httpx client initialized")
            
            # Separate clients for Gemini (image gen takes longer)
            self.gemini_client = httpx.AsyncClient(
                timeout=httpx.Timeout(120.0, connect=10.0),  # 2 min timeout for image generation
                limits=httpx.Limits(max_keepalive_connections=50)
            )
            logger.info("✅ Gemini httpx client initialized (timeout: 120s)")
            
            # OpenRouter client
            self.openrouter_client = httpx.AsyncClient(
                timeout=httpx.Timeout(60.0, connect=10.0),   # 1 min for reasoning
                limits=httpx.Limits(max_keepalive_connections=50)
            )
            logger.info("✅ OpenRouter httpx client initialized (timeout: 60s)")
            
            self.is_initialized = True
            logger.info("✅ All async resources initialized successfully")
            
        except Exception as e:
            logger.error(f"❌ Failed to initialize async resources: {e}", exc_info=True)
            raise
    
    async def cleanup(self):
        """
        Clean up all async resources.
        Called during FastAPI shutdown.
        """
        logger.info("Cleaning up async resources...")
        
        try:
            # Close all httpx clients gracefully
            clients = [
                ("main", self.httpx_client),
                ("gemini", self.gemini_client),
                ("openrouter", self.openrouter_client),
            ]
            
            for name, client in clients:
                if client is not None:
                    try:
                        await client.aclose()
                        logger.info(f"✅ Closed {name} httpx client")
                    except Exception as e:
                        logger.warning(f"⚠️ Error closing {name} client: {e}")
            
            self.is_initialized = False
            logger.info("✅ All async resources cleaned up")
            
        except Exception as e:
            logger.error(f"❌ Error during cleanup: {e}", exc_info=True)


# Global resource manager instance
_resource_manager = AsyncResourceManager()


def get_resource_manager() -> AsyncResourceManager:
    """Get the global resource manager instance"""
    return _resource_manager


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator:
    """
    FastAPI lifespan context manager.
    
    Handles:
    1. Startup: Initialize all async resources
    2. Runtime: App serves requests
    3. Shutdown: Clean up all resources gracefully
    
    CRITICAL: This is the ONLY place where async resources are created.
    All routers and services MUST use get_resource_manager() to access clients.
    """
    
    # ─── STARTUP PHASE ───
    logger.info("=" * 70)
    logger.info("APPLICATION STARTUP")
    logger.info("=" * 70)
    
    try:
        # 1. Initialize async resources
        await _resource_manager.initialize()
        
        # 2. Inject managed clients into services (e.g. Stage5ImageGeneration)
        setup = getattr(app.state, "setup_service_dependencies", None)
        if callable(setup):
            setup()
        else:
            logger.warning("⚠️ setup_service_dependencies not found on app.state")
        
        # 3. Log startup info
        from ..core.config import settings
        logger.info(f"✅ Cleo Fashion VTON API v{settings.API_VERSION}")
        gk = (settings.GEMINI_API_KEY or "")[:20]
        ok = (settings.OPENROUTER_API_KEY or "")[:20]
        logger.info(f"✅ Gemini API Key: {gk}..." if gk else "✅ Gemini API Key: (not set)")
        logger.info(f"✅ OpenRouter API Key: {ok}..." if ok else "✅ OpenRouter API Key: (not set)")
        logger.info(f"✅ GPU Available: {settings.USE_GPU}")
        logger.info(f"✅ Debug Mode: {settings.DEBUG}")
        logger.info("=" * 70)
        logger.info("✅ SERVER READY TO ACCEPT REQUESTS")
        logger.info("=" * 70)
        
    except Exception as e:
        logger.critical(f"❌ Startup failed: {e}", exc_info=True)
        raise
    
    # ─── RUNTIME PHASE ───
    # Yield control to Uvicorn to serve requests
    try:
        yield
    except Exception as e:
        logger.error(f"Error during request handling: {e}", exc_info=True)
        raise
    
    # ─── SHUTDOWN PHASE ───
    finally:
        logger.info("=" * 70)
        logger.info("APPLICATION SHUTDOWN")
        logger.info("=" * 70)
        
        try:
            # Clean up all resources
            await _resource_manager.cleanup()
            
            logger.info("✅ Shutdown complete")
            logger.info("=" * 70)
            
        except Exception as e:
            logger.error(f"Error during shutdown: {e}", exc_info=True)


__all__ = ["lifespan", "get_resource_manager", "AsyncResourceManager"]
