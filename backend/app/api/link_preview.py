"""
Link Preview API - Fetch product image and title from external product URLs.
Used by the app to display outfit images from Zalando, OTTO, etc. when user pastes a link.
"""
import re
import logging
from typing import Optional
from urllib.parse import urljoin, urlparse

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel

from ..core.lifespan_manager import get_resource_manager

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/link-preview", tags=["link-preview"])


class LinkPreviewResponse(BaseModel):
    image_url: str
    title: Optional[str] = None
    page_url: str


# Match og:image, og:title in HTML (allow single/double quotes, multiline)
_OG_IMAGE_RE = re.compile(
    r'<meta[^>]+property=["\']og:image["\'][^>]+content=["\']([^"\']+)["\']',
    re.IGNORECASE | re.DOTALL,
)
_OG_IMAGE_RE_2 = re.compile(
    r'<meta[^>]+content=["\']([^"\']+)["\'][^>]+property=["\']og:image["\']',
    re.IGNORECASE | re.DOTALL,
)
_OG_TITLE_RE = re.compile(
    r'<meta[^>]+property=["\']og:title["\'][^>]+content=["\']([^"\']+)["\']',
    re.IGNORECASE | re.DOTALL,
)
_OG_TITLE_RE_2 = re.compile(
    r'<meta[^>]+content=["\']([^"\']+)["\'][^>]+property=["\']og:title["\']',
    re.IGNORECASE | re.DOTALL,
)
# Fallback: first large img with product-like src
_IMG_SRC_RE = re.compile(r'<img[^>]+src=["\']([^"\']+)["\']', re.IGNORECASE)

USER_AGENT = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
)


@router.get("", response_model=LinkPreviewResponse)
async def get_link_preview(
    url: str = Query(..., description="Product or page URL to fetch image from"),
):
    """
    Fetch the main image and title from a product/page URL (og:image, og:title).
    Returns image URL so the app can display it in chat and run try-on.
    """
    url = url.strip()
    if not url.startswith(("http://", "https://")):
        url = "https://" + url
    try:
        parsed = urlparse(url)
        if not parsed.netloc:
            raise HTTPException(status_code=400, detail="Invalid URL")
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid URL")

    resource_mgr = get_resource_manager()
    if not resource_mgr or not resource_mgr.httpx_client:
        raise HTTPException(status_code=503, detail="HTTP client not available")

    try:
        resp = await resource_mgr.httpx_client.get(
            url,
            headers={"User-Agent": USER_AGENT},
            timeout=15.0,
            follow_redirects=True,
        )
        resp.raise_for_status()
        html = resp.text
        base_url = str(resp.url)
    except Exception as e:
        logger.warning("Link preview fetch failed for %s: %s", url, e)
        raise HTTPException(status_code=422, detail="Could not fetch URL") from e

    image_url: Optional[str] = None
    m = _OG_IMAGE_RE.search(html) or _OG_IMAGE_RE_2.search(html)
    if m:
        image_url = m.group(1).strip()
        if image_url and not image_url.startswith("http"):
            image_url = urljoin(base_url, image_url)

    if not image_url:
        # Fallback: first img with data or http src (skip tracking pixels)
        for m in _IMG_SRC_RE.finditer(html):
            src = m.group(1).strip()
            if src.startswith("http") and "logo" not in src.lower() and "icon" not in src.lower():
                image_url = src if not src.startswith("//") else "https:" + src
                break
        if not image_url:
            for m in _IMG_SRC_RE.finditer(html):
                src = m.group(1).strip()
                if src.startswith("http"):
                    image_url = src if not src.startswith("//") else "https:" + src
                    break

    if not image_url:
        raise HTTPException(status_code=404, detail="No image found on page")

    title: Optional[str] = None
    tm = _OG_TITLE_RE.search(html) or _OG_TITLE_RE_2.search(html)
    if tm:
        title = tm.group(1).strip() or None

    return LinkPreviewResponse(
        image_url=image_url,
        title=title,
        page_url=url,
    )
