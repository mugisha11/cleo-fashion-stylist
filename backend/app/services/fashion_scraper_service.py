"""
Fashion Trend Analytics Integration Service
Adapts external Fashion-Trend-Analytics-Pipeline for FastAPI backend
- Supports Zara, H&M, ASOS scraping (without Scrapy dependency)
- Converts spider logic to async httpx-based functions
- Integrates with BigQuery for data storage
"""

import logging
import re
import json
from typing import List, Dict, Optional, Any
from datetime import datetime
from urllib.parse import urljoin, urlparse
import asyncio

logger = logging.getLogger(__name__)


# ============================================================================
# UTILITY FUNCTIONS (from external pipeline)
# ============================================================================

def clean_price(price_text: str) -> Optional[float]:
    """Extract numeric price from text"""
    if not price_text:
        return None
    price_match = re.search(r'[\d,]+\.?\d*', str(price_text).replace(',', ''))
    if price_match:
        try:
            return float(price_match.group().replace(',', ''))
        except ValueError:
            return None
    return None


def extract_currency(price_text: str) -> str:
    """Extract currency symbol from price text"""
    if not price_text:
        return 'USD'
    currency_symbols = {
        '$': 'USD',
        '€': 'EUR',
        '£': 'GBP',
        '¥': 'JPY',
        '₹': 'INR'
    }
    for symbol, currency in currency_symbols.items():
        if symbol in str(price_text):
            return currency
    return 'USD'


def normalize_size(size_text: str) -> List[str]:
    """Normalize size text to list of standard sizes"""
    if not size_text:
        return []
    size_pattern = r'\b(XS|S|M|L|XL|XXL|XXXL|\d+|\d+\s*[-/]\d+)\b'
    sizes = re.findall(size_pattern, str(size_text), re.IGNORECASE)
    return [s.strip().upper() for s in sizes if s.strip()]


def extract_materials(text: str) -> List[str]:
    """Extract material information from text"""
    if not text:
        return []
    common_materials = [
        'cotton', 'polyester', 'wool', 'silk', 'linen', 'denim',
        'leather', 'suede', 'cashmere', 'nylon', 'spandex', 'elastane',
        'viscose', 'rayon', 'modal', 'acrylic', 'polyamide'
    ]
    text_lower = text.lower()
    found_materials = []
    for material in common_materials:
        if material in text_lower:
            found_materials.append(material.capitalize())
    return found_materials


def extract_rating(rating_text: str) -> Optional[float]:
    """Extract numeric rating from text"""
    if not rating_text:
        return None
    rating_match = re.search(r'(\d+\.?\d*)\s*/?\s*\d*', str(rating_text))
    if rating_match:
        try:
            rating = float(rating_match.group(1))
            if rating > 5:
                rating = rating / 10 if rating <= 10 else rating / 20
            return min(5.0, max(0.0, rating))
        except ValueError:
            return None
    return None


# ============================================================================
# PRODUCT ITEM MODEL
# ============================================================================

class FashionProductItem:
    """Representation of a scraped fashion product"""
    def __init__(self, data: Dict[str, Any] = None):
        if data is None:
            data = {}
        self.data = data

    def __setitem__(self, key: str, value: Any):
        self.data[key] = value

    def __getitem__(self, key: str) -> Any:
        return self.data.get(key)

    def get(self, key: str, default: Any = None) -> Any:
        return self.data.get(key, default)

    def to_dict(self) -> Dict[str, Any]:
        return self.data.copy()


# ============================================================================
# ASYNC SCRAPER SERVICES
# ============================================================================

class ZaraScraper:
    """Zara scraper - uses async HTTP parsing"""
    
    name = 'zara'
    start_urls = {
        'full': [
            'https://www.zara.com/us/en/woman/view-all-c358006.html',
            'https://www.zara.com/us/en/man/view-all-c358010.html',
            'https://www.zara.com/us/en/kids/view-all-c358012.html',
        ],
        'new_arrivals': [
            'https://www.zara.com/us/en/woman/new-in-c358006.html',
            'https://www.zara.com/us/en/man/new-in-c358010.html',
        ]
    }

    def __init__(self, client, scrape_mode: str = 'full'):
        self.client = client
        self.scrape_mode = scrape_mode
        self.timestamp = datetime.utcnow().isoformat()

    async def scrape(self, limit: int = 50) -> List[FashionProductItem]:
        """Scrape Zara products"""
        products = []
        urls = self.start_urls.get(self.scrape_mode, self.start_urls['full'])[:2]
        
        for url in urls:
            try:
                async with self.client.stream('GET', url, timeout=10.0) as resp:
                    if resp.status_code != 200:
                        continue
                    html = await resp.aread()
                    items = self._parse_listing(html.decode('utf-8', errors='ignore'), url)
                    products.extend(items)
                    if len(products) >= limit:
                        break
            except Exception as e:
                logger.warning(f"Zara scrape error: {e}")
                continue
        
        return products[:limit]

    def _parse_listing(self, html: str, base_url: str) -> List[FashionProductItem]:
        """Extract product links from listing page"""
        products = []
        product_links = re.findall(r'href=["\'](/us/en/[^"\']*?/product/[^"\']+)["\']', html)
        
        for link in set(product_links):
            full_url = urljoin('https://www.zara.com', link)
            item = FashionProductItem({
                'product_url': full_url,
                'source_site': self.name,
                'scrape_timestamp': self.timestamp,
                'scrape_mode': self.scrape_mode,
            })
            products.append(item)
        
        return products


class HMScraper:
    """H&M scraper - uses async HTTP parsing"""
    
    name = 'hm'
    start_urls = {
        'full': [
            'https://www2.hm.com/en_us/women/shop-by-product/view-all.html',
            'https://www2.hm.com/en_us/men/shop-by-product/view-all.html',
            'https://www2.hm.com/en_us/kids/shop-by-product/view-all.html',
        ],
        'new_arrivals': [
            'https://www2.hm.com/en_us/women/new-arrivals/view-all.html',
            'https://www2.hm.com/en_us/men/new-arrivals/view-all.html',
        ]
    }

    def __init__(self, client, scrape_mode: str = 'full'):
        self.client = client
        self.scrape_mode = scrape_mode
        self.timestamp = datetime.utcnow().isoformat()

    async def scrape(self, limit: int = 50) -> List[FashionProductItem]:
        """Scrape H&M products"""
        products = []
        urls = self.start_urls.get(self.scrape_mode, self.start_urls['full'])[:2]
        
        for url in urls:
            try:
                async with self.client.stream('GET', url, timeout=10.0) as resp:
                    if resp.status_code != 200:
                        continue
                    html = await resp.aread()
                    items = self._parse_listing(html.decode('utf-8', errors='ignore'), url)
                    products.extend(items)
                    if len(products) >= limit:
                        break
            except Exception as e:
                logger.warning(f"H&M scrape error: {e}")
                continue
        
        return products[:limit]

    def _parse_listing(self, html: str, base_url: str) -> List[FashionProductItem]:
        """Extract product links from listing page"""
        products = []
        product_links = re.findall(r'href=["\'](/en_us/productpage\.[^"\']+)["\']', html)
        
        for link in set(product_links):
            full_url = urljoin('https://www2.hm.com', link)
            item = FashionProductItem({
                'product_url': full_url,
                'source_site': self.name,
                'scrape_timestamp': self.timestamp,
                'scrape_mode': self.scrape_mode,
            })
            products.append(item)
        
        return products


class ASOSScraper:
    """ASOS scraper - uses async HTTP parsing"""
    
    name = 'asos'
    start_urls = {
        'full': [
            'https://www.asos.com/women/ctas/cat/?cid=13528',
            'https://www.asos.com/men/ctas/cat/?cid=5760',
        ],
        'new_arrivals': [
            'https://www.asos.com/women/new-in/cat/?cid=2637',
            'https://www.asos.com/men/new-in/cat/?cid=5760',
        ]
    }

    def __init__(self, client, scrape_mode: str = 'full'):
        self.client = client
        self.scrape_mode = scrape_mode
        self.timestamp = datetime.utcnow().isoformat()

    async def scrape(self, limit: int = 50) -> List[FashionProductItem]:
        """Scrape ASOS products"""
        products = []
        urls = self.start_urls.get(self.scrape_mode, self.start_urls['full'])[:2]
        
        for url in urls:
            try:
                async with self.client.stream('GET', url, timeout=10.0) as resp:
                    if resp.status_code != 200:
                        continue
                    html = await resp.aread()
                    items = self._parse_listing(html.decode('utf-8', errors='ignore'), url)
                    products.extend(items)
                    if len(products) >= limit:
                        break
            except Exception as e:
                logger.warning(f"ASOS scrape error: {e}")
                continue
        
        return products[:limit]

    def _parse_listing(self, html: str, base_url: str) -> List[FashionProductItem]:
        """Extract product links from listing page"""
        products = []
        product_links = re.findall(r'href=["\'](/prd/[^"\']+)["\']', html)
        
        for link in set(product_links):
            full_url = urljoin('https://www.asos.com', link)
            item = FashionProductItem({
                'product_url': full_url,
                'source_site': self.name,
                'scrape_timestamp': self.timestamp,
                'scrape_mode': self.scrape_mode,
            })
            products.append(item)
        
        return products


# ============================================================================
# ORCHESTRATOR
# ============================================================================

class FashionScraperService:
    """Coordinate multi-site fashion scraping"""
    
    def __init__(self, httpx_client):
        self.client = httpx_client

    async def scrape_all(
        self,
        retailers: List[str] = None,
        mode: str = 'full',
        limit_per_retailer: int = 50
    ) -> Dict[str, List[FashionProductItem]]:
        """Scrape all specified retailers concurrently"""
        if retailers is None:
            retailers = ['zara', 'hm', 'asos']

        scrapers = {
            'zara': ZaraScraper(self.client, mode),
            'hm': HMScraper(self.client, mode),
            'asos': ASOSScraper(self.client, mode),
        }

        tasks = {}
        for name in retailers:
            if name.lower() in scrapers:
                tasks[name] = scrapers[name.lower()].scrape(limit_per_retailer)

        results = {}
        if tasks:
            task_results = await asyncio.gather(*tasks.values(), return_exceptions=True)
            for (name, _), result in zip(tasks.items(), task_results):
                if isinstance(result, Exception):
                    logger.error(f"Scrape error for {name}: {result}")
                    results[name] = []
                else:
                    results[name] = result
        
        return results

    async def scrape_one(
        self,
        retailer: str,
        mode: str = 'full',
        limit: int = 50
    ) -> List[FashionProductItem]:
        """Scrape a single retailer"""
        scrapers = {
            'zara': ZaraScraper(self.client, mode),
            'hm': HMScraper(self.client, mode),
            'asos': ASOSScraper(self.client, mode),
        }

        scraper = scrapers.get(retailer.lower())
        if not scraper:
            logger.error(f"Unknown retailer: {retailer}")
            return []

        return await scraper.scrape(limit)
