"""
Image proxy - fetch external image URLs and return bytes.
Fixes CORS/referrer blocking so Flutter web can display Google Shopping & other CDN images.
"""
import logging
import urllib.parse
from urllib.parse import urlparse

from fastapi import APIRouter, Query
from fastapi.responses import Response

from ..core.lifespan_manager import get_resource_manager

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/proxy-image", tags=["proxy-image"])

USER_AGENT = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
)


@router.get("")
async def proxy_image(url: str = Query(..., description="Image URL to fetch and return")):
    """
    Fetch an image from an external URL and return it. Use this so the app can display
    images from CDNs that block direct browser requests (CORS/referrer).
    """
    # Decode and clean URL
    url = (url or "").strip()
    try:
        decoded_url = urllib.parse.unquote(url)
        if decoded_url != url:
            url = decoded_url.strip()
    except Exception:
        pass

    # Fix malformed scheme slashes like https:/path or http:/path
    if url.startswith("https:/") and not url.startswith("https://"):
        url = url.replace("https:/", "https://", 1)
    if url.startswith("http:/") and not url.startswith("http://"):
        url = url.replace("http:/", "http://", 1)

    # Validate URL format
    if not url.startswith(("http://", "https://")):
        logger.warning(f"Invalid URL prefix: {url[:100]}")
        return Response(status_code=400, content=b"Invalid URL format")
    
    try:
        parsed = urlparse(url)
        if not parsed.netloc or not parsed.scheme:
            logger.warning(f"Invalid parsed URL: {url[:100]}")
            return Response(status_code=400, content=b"Invalid URL format")
    except Exception as e:
        logger.warning(f"URL parse error: {e}, URL: {url[:100]}")
        return Response(status_code=400, content=b"Invalid URL format")

    resource_mgr = get_resource_manager()
    if not resource_mgr or not resource_mgr.httpx_client:
        logger.error("Resource manager or httpx_client not available")
        return Response(status_code=503, content=b"Service unavailable")

    try:
        logger.info(f"Fetching image from: {url[:100]}")
        resp = await resource_mgr.httpx_client.get(
            url,
            headers={"User-Agent": USER_AGENT},
            timeout=10.0,
            follow_redirects=True,
        )
        resp.raise_for_status()
        content = resp.content
        content_type = resp.headers.get("content-type", "image/jpeg")
        # Sanity: only allow image types
        if "image/" not in content_type and "octet-stream" not in content_type:
            content_type = "image/jpeg"
        logger.info(f"✅ Image proxy successful: {url[:100]} ({len(content)} bytes)")
        return Response(content=content, media_type=content_type)
    except Exception as e:
        logger.warning(f"Proxy image failed for {url[:100]}: {type(e).__name__}: {e}")
        return Response(status_code=502, content=b"Failed to fetch image")
