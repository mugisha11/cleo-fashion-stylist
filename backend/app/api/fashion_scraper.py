"""
Fashion Scraper API Endpoint
Exposes fashion trend analytics scraping capabilities via REST API
- Supports on-demand Zara, H&M, ASOS scraping
- Returns scraped product data with trend analytics
"""

import logging
from typing import List, Dict, Optional
from fastapi import APIRouter, Query, HTTPException
from pydantic import BaseModel

from ..core.lifespan_manager import get_resource_manager
from ..services.fashion_scraper_service import FashionScraperService

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/fashion-scraper", tags=["fashion-scraper"])


# ============================================================================
# SCHEMAS
# ============================================================================

class ScrapedProduct(BaseModel):
    """Scraped fashion product"""
    product_url: str
    source_site: str
    scrape_timestamp: str
    scrape_mode: str
    product_name: Optional[str] = None
    price: Optional[float] = None
    brand: Optional[str] = None
    category: Optional[str] = None
    image_urls: Optional[List[str]] = None
    customer_rating: Optional[float] = None


class ScraperResponse(BaseModel):
    """Response from scraper endpoint"""
    retailer: str
    mode: str
    products_count: int
    products: List[ScrapedProduct]
    message: Optional[str] = None


class ScraperMultiResponse(BaseModel):
    """Response from multi-retailer scraper endpoint"""
    retailers: List[str]
    mode: str
    total_products: int
    results: Dict[str, List[ScrapedProduct]]
    message: Optional[str] = None


# ============================================================================
# ENDPOINTS
# ============================================================================

@router.post("/scrape", response_model=ScraperResponse)
async def scrape_fashion(
    retailer: str = Query("asos", description="Retailer to scrape: zara, hm, or asos"),
    mode: str = Query("full", description="Scrape mode: full or new_arrivals"),
    limit: int = Query(50, ge=1, le=500, description="Max products to return"),
):
    """
    Scrape fashion products from a single retailer.
    
    Retailers:
    - `asos`: ASOS.com
    - `hm`: H&M.com
    - `zara`: Zara.com
    
    Modes:
    - `full`: Complete inventory scrape
    - `new_arrivals`: New items only
    """
    retailer = retailer.lower().strip()
    mode = mode.lower().strip()

    if retailer not in ["asos", "hm", "zara"]:
        raise HTTPException(status_code=400, detail=f"Unknown retailer: {retailer}. Use: asos, hm, or zara")

    if mode not in ["full", "new_arrivals"]:
        raise HTTPException(status_code=400, detail=f"Unknown mode: {mode}. Use: full or new_arrivals")

    try:
        resource_mgr = get_resource_manager()
        if not resource_mgr or not resource_mgr.httpx_client:
            raise HTTPException(status_code=503, detail="Resource manager unavailable")

        scraper_service = FashionScraperService(resource_mgr.httpx_client)
        products = await scraper_service.scrape_one(retailer, mode, limit)

        scraped_products = [
            ScrapedProduct(
                product_url=p.get("product_url", ""),
                source_site=p.get("source_site", ""),
                scrape_timestamp=p.get("scrape_timestamp", ""),
                scrape_mode=p.get("scrape_mode", ""),
                product_name=p.get("product_name"),
                price=p.get("price"),
                brand=p.get("brand"),
                category=p.get("category"),
                image_urls=p.get("image_urls"),
                customer_rating=p.get("customer_rating"),
            )
            for p in products
        ]

        return ScraperResponse(
            retailer=retailer,
            mode=mode,
            products_count=len(scraped_products),
            products=scraped_products,
            message=f"Successfully scraped {len(scraped_products)} products from {retailer.upper()}",
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Scraper error: {e}")
        raise HTTPException(status_code=500, detail=f"Scraping failed: {str(e)}")


@router.post("/scrape-all", response_model=ScraperMultiResponse)
async def scrape_all_retailers(
    retailers: List[str] = Query(
        ["asos", "hm", "zara"],
        description="List of retailers to scrape"
    ),
    mode: str = Query("full", description="Scrape mode: full or new_arrivals"),
    limit_per_retailer: int = Query(30, ge=1, le=500, description="Max products per retailer"),
):
    """
    Scrape fashion products from multiple retailers concurrently.
    
    Retailers:
    - `asos`: ASOS.com
    - `hm`: H&M.com
    - `zara`: Zara.com
    
    Modes:
    - `full`: Complete inventory scrape (slower)
    - `new_arrivals`: New items only (faster)
    """
    retailers = [r.lower().strip() for r in retailers]
    mode = mode.lower().strip()

    # Validate retailers
    valid_retailers = {"asos", "hm", "zara"}
    invalid = set(retailers) - valid_retailers
    if invalid:
        raise HTTPException(status_code=400, detail=f"Unknown retailers: {invalid}. Use: asos, hm, or zara")

    if mode not in ["full", "new_arrivals"]:
        raise HTTPException(status_code=400, detail=f"Unknown mode: {mode}. Use: full or new_arrivals")

    if not retailers:
        raise HTTPException(status_code=400, detail="At least one retailer must be specified")

    try:
        resource_mgr = get_resource_manager()
        if not resource_mgr or not resource_mgr.httpx_client:
            raise HTTPException(status_code=503, detail="Resource manager unavailable")

        scraper_service = FashionScraperService(resource_mgr.httpx_client)
        all_results = await scraper_service.scrape_all(retailers, mode, limit_per_retailer)

        results = {}
        total = 0
        for retailer, products in all_results.items():
            scraped_products = [
                ScrapedProduct(
                    product_url=p.get("product_url", ""),
                    source_site=p.get("source_site", ""),
                    scrape_timestamp=p.get("scrape_timestamp", ""),
                    scrape_mode=p.get("scrape_mode", ""),
                    product_name=p.get("product_name"),
                    price=p.get("price"),
                    brand=p.get("brand"),
                    category=p.get("category"),
                    image_urls=p.get("image_urls"),
                    customer_rating=p.get("customer_rating"),
                )
                for p in products
            ]
            results[retailer] = scraped_products
            total += len(scraped_products)

        return ScraperMultiResponse(
            retailers=retailers,
            mode=mode,
            total_products=total,
            results=results,
            message=f"Successfully scraped {total} products from {len(retailers)} retailers",
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Multi-scraper error: {e}")
        raise HTTPException(status_code=500, detail=f"Multi-scraping failed: {str(e)}")


@router.get("/status")
async def scraper_status():
    """Check scraper service status"""
    try:
        resource_mgr = get_resource_manager()
        if not resource_mgr or not resource_mgr.httpx_client:
            return {
                "status": "unavailable",
                "message": "Resource manager not ready"
            }

        return {
            "status": "ready",
            "message": "Fashion scraper service is ready",
            "retailers": ["asos", "hm", "zara"],
            "modes": ["full", "new_arrivals"],
        }
    except Exception as e:
        logger.error(f"Status check error: {e}")
        return {
            "status": "error",
            "message": str(e)
        }
