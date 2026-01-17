"""
Retry Logic System
Automatic retry with exponential backoff for quality failures
"""
import asyncio
import logging
from typing import Callable, TypeVar, Optional
from functools import wraps

T = TypeVar('T')

logger = logging.getLogger(__name__)


class RetryHandler:
    """Production-grade retry handler with exponential backoff"""
    
    def __init__(
        self,
        max_retries: int = 3,
        base_delay: float = 1.0,
        max_delay: float = 10.0,
        exponential_base: float = 2.0
    ):
        self.max_retries = max_retries
        self.base_delay = base_delay
        self.max_delay = max_delay
        self.exponential_base = exponential_base
    
    async def retry_async(
        self,
        func: Callable[..., T],
        *args,
        quality_check: Optional[Callable[[T], tuple[bool, str]]] = None,
        **kwargs
    ) -> T:
        """
        Retry async function until quality check passes or max retries reached
        
        Args:
            func: Async function to retry
            quality_check: Function that returns (passed: bool, error: str)
            *args, **kwargs: Arguments for func
        
        Returns:
            Result from func
        
        Raises:
            Exception: If all retries fail
        """
        last_error = None
        
        for attempt in range(self.max_retries):
            try:
                result = await func(*args, **kwargs)
                
                # If quality check provided, validate result
                if quality_check:
                    passed, error_msg = quality_check(result)
                    if passed:
                        logger.info(f"Quality check passed on attempt {attempt + 1}")
                        return result
                    else:
                        logger.warning(
                            f"Quality check failed on attempt {attempt + 1}: {error_msg}"
                        )
                        last_error = Exception(f"Quality check failed: {error_msg}")
                else:
                    # No quality check, return immediately
                    return result
                
            except Exception as e:
                logger.error(f"Attempt {attempt + 1} failed: {str(e)}")
                last_error = e
            
            # Calculate delay with exponential backoff
            if attempt < self.max_retries - 1:
                delay = min(
                    self.base_delay * (self.exponential_base ** attempt),
                    self.max_delay
                )
                logger.info(f"Retrying in {delay:.2f}s...")
                await asyncio.sleep(delay)
        
        # All retries exhausted
        raise Exception(
            f"Failed after {self.max_retries} attempts. Last error: {str(last_error)}"
        )
    
    def retry_sync(
        self,
        func: Callable[..., T],
        *args,
        quality_check: Optional[Callable[[T], tuple[bool, str]]] = None,
        **kwargs
    ) -> T:
        """Synchronous version of retry"""
        import time
        
        last_error = None
        
        for attempt in range(self.max_retries):
            try:
                result = func(*args, **kwargs)
                
                if quality_check:
                    passed, error_msg = quality_check(result)
                    if passed:
                        logger.info(f"Quality check passed on attempt {attempt + 1}")
                        return result
                    else:
                        logger.warning(
                            f"Quality check failed on attempt {attempt + 1}: {error_msg}"
                        )
                        last_error = Exception(f"Quality check failed: {error_msg}")
                else:
                    return result
                
            except Exception as e:
                logger.error(f"Attempt {attempt + 1} failed: {str(e)}")
                last_error = e
            
            if attempt < self.max_retries - 1:
                delay = min(
                    self.base_delay * (self.exponential_base ** attempt),
                    self.max_delay
                )
                logger.info(f"Retrying in {delay:.2f}s...")
                time.sleep(delay)
        
        raise Exception(
            f"Failed after {self.max_retries} attempts. Last error: {str(last_error)}"
        )


def retry_on_quality_failure(max_retries: int = 3):
    """Decorator for automatic retry on quality failures"""
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            handler = RetryHandler(max_retries=max_retries)
            return await handler.retry_async(func, *args, **kwargs)
        return wrapper
    return decorator


def retry_with_backoff(max_retries: int = 3, base_delay: float = 1.0):
    """Simple retry decorator with exponential backoff"""
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            handler = RetryHandler(max_retries=max_retries, base_delay=base_delay)
            return await handler.retry_async(func, *args, **kwargs)
        return wrapper
    return decorator

