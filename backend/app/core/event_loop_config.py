
import asyncio
import sys
import logging

logger = logging.getLogger(__name__)


def setup_event_loop():
    
    
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
