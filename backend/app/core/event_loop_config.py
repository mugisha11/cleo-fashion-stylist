"""
Event Loop Configuration - CRITICAL for Windows async support

PROBLEM:
- Windows ProactorEventLoopPolicy (default) uses IOCP internally
- IOCP doesn't properly track/manage long-lived async resources
- Multiple httpx.AsyncClient objects created at module-level leak sockets
- Event loop doesn't wait for them during shutdown

SOLUTION:
- Use SelectorEventLoopPolicy on Windows (uses select(), not IOCP)
- SelectorEventLoopPolicy properly tracks and waits for async resources
- Centralize ALL async client creation in lifespan manager
- NO module-level async instantiation
"""
import asyncio
import sys
import logging

logger = logging.getLogger(__name__)


def setup_event_loop():
    """
    Setup proper event loop policy BEFORE any async code runs.
    
    This must be called at the very top of main.py, before ANY imports
    of FastAPI, httpx, or other async libraries.
    
    Windows ProactorEventLoopPolicy BROKEN for long-lived async resources:
    - Doesn't properly track socket cleanup
    - Doesn't wait for lifespan shutdown
    - Causes "Coroutine was never awaited" warnings
    
    SelectorEventLoopPolicy is more reliable for our use case.
    """
    
    # Windows-specific: Use SelectorEventLoopPolicy instead of Proactor
    if sys.platform == 'win32':
        try:
            asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
            logger.info("✅ Event Loop Policy: WindowsSelectorEventLoopPolicy (FIXED)")
        except Exception as e:
            logger.warning(f"⚠️  Failed to set WindowsSelectorEventLoopPolicy: {e}")
            logger.info("   Using default event loop policy")
    else:
        # Linux/Mac: Default is fine, but can explicitly use SelectorEventLoopPolicy
        asyncio.set_event_loop_policy(asyncio.DefaultEventLoopPolicy())
        logger.info(f"✅ Event Loop Policy: DefaultEventLoopPolicy ({sys.platform})")
    
    logger.debug("✅ Event loop initialization complete")


__all__ = ["setup_event_loop"]
