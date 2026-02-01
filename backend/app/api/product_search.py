"""
Product Search API - For AI-assisted shopping.
Returns product images + links so the app can show them in chat and let the user try on.
Uses SerpAPI Google Shopping if SERP_API_KEY is set; otherwise returns demo results.
"""
import logging
from typing import List, Optional

from fastapi import APIRouter, Query
from pydantic import BaseModel

from ..core.config import settings
from ..core.lifespan_manager import get_resource_manager

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/product-search", tags=["product-search"])


class ProductItem(BaseModel):
    title: str
    image_url: str
    link: str
    price: Optional[str] = None


class ProductSearchResponse(BaseModel):
    products: List[ProductItem]
    query: str
    message: Optional[str] = None  # e.g. "Set SERP_API_KEY for live search"


def _demo_products(query: str, limit: int) -> List[ProductItem]:
    """Demo results when SerpAPI is not configured."""
    q = (query or "clothing").lower()[:30]
    # Return a few placeholder products so the UI flow works
    return [
        ProductItem(
            title=f"Fashion {q} – Option 1",
            image_url="https://images.unsplash.com/photo-1558769132-cb1aea913ec9?w=400",
            link="https://www.zalando.de/",
            price="—",
        ),
        ProductItem(
            title=f"Fashion {q} – Option 2",
            image_url="https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?w=400",
            link="https://www.asos.com/",
            price="—",
        ),
        ProductItem(
            title=f"Fashion {q} – Option 3",
            image_url="https://images.unsplash.com/photo-1445205170230-053b83016050?w=400",
            link="https://www.aboutyou.de/",
            price="—",
        ),
    ][:limit]


@router.get("", response_model=ProductSearchResponse)
async def search_products(
    q: str = Query(..., min_length=1, description="Search query (e.g. white blazer women)"),
    limit: int = Query(8, ge=1, le=20),
):
    """
    Search for fashion products. Returns image URL, title, and buy link for each.
    Used when the user asks for shopping help — AI outputs SEARCH_PRODUCTS=<query>, app calls this, then shows images with Try on + Buy.
    """
    query = (q or "").strip()
    if not query:
        return ProductSearchResponse(products=[], query="", message="Missing query")

    if not settings.SERP_API_KEY:
        products = _demo_products(query, limit)
        return ProductSearchResponse(
            products=products,
            query=query,
            message="Demo results. Set SERP_API_KEY for live Google Shopping search.",
        )

    resource_mgr = get_resource_manager()
    if not resource_mgr or not resource_mgr.httpx_client:
        products = _demo_products(query, limit)
        return ProductSearchResponse(products=products, query=query, message="Demo results.")

    try:
        import urllib.parse
        params = {
            "engine": "google_shopping",
            "q": query,
            "api_key": settings.SERP_API_KEY,
            "num": limit,
        }
        url = "https://serpapi.com/search?" + urllib.parse.urlencode(params)
        resp = await resource_mgr.httpx_client.get(url, timeout=15.0)
        resp.raise_for_status()
        data = resp.json()
    except Exception as e:
        logger.warning("SerpAPI product search failed: %s", e)
        products = _demo_products(query, limit)
        return ProductSearchResponse(products=products, query=query, message="Search failed; showing demo results.")

    products = []
    shopping_results = data.get("shopping_results") or data.get("organic_results") or []
    for item in shopping_results[:limit]:
        if not isinstance(item, dict):
            continue
        title = item.get("title") or item.get("name") or ""
        link = item.get("product_link") or item.get("link") or ""
        thumb = item.get("thumbnail") or item.get("image")
        if isinstance(thumb, list) and thumb:
            thumb = thumb[0] if isinstance(thumb[0], str) else (thumb[0].get("image") if isinstance(thumb[0], dict) else "")
        image_url = (thumb if isinstance(thumb, str) and thumb else "") or link
        price = item.get("price") or item.get("extracted_price")
        if price is not None and not isinstance(price, str):
            price = str(price)
        if title and (image_url or link):
            products.append(ProductItem(title=title, image_url=image_url or link, link=link, price=price))

    if not products:
        products = _demo_products(query, limit)
        return ProductSearchResponse(products=products, query=query)

    return ProductSearchResponse(products=products, query=query)
