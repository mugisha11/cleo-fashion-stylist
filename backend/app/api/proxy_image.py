"""
Image proxy - fetch external image URLs and return bytes.
Fixes CORS/referrer blocking so Flutter web can display Google Shopping & other CDN images.
"""
import logging
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
    url = url.strip()
    if not url.startswith(("http://", "https://")):
        return Response(status_code=400, content=b"Invalid URL")
    try:
        parsed = urlparse(url)
        if not parsed.netloc:
            return Response(status_code=400, content=b"Invalid URL")
    except Exception:
        return Response(status_code=400, content=b"Invalid URL")

    resource_mgr = get_resource_manager()
    if not resource_mgr or not resource_mgr.httpx_client:
        return Response(status_code=503, content=b"Service unavailable")

    try:
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
        return Response(content=content, media_type=content_type)
    except Exception as e:
        logger.warning("Proxy image failed for %s: %s", url[:80], e)
        return Response(status_code=502, content=b"Failed to fetch image")
