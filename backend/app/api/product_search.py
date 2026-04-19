"""
Product Search API - For AI-assisted shopping.
Returns product images + links so the app can show them in chat and let the user try on.
Always uses live retailer search; placeholder demo results are not returned.
"""
import asyncio
import json
import logging
import re
import urllib.parse
from typing import Any, List, Optional

from fastapi import APIRouter, Query
from pydantic import BaseModel

from ..core.config import settings
from ..core.lifespan_manager import get_resource_manager
from ..services.enhanced_openrouter_service import EnhancedOpenRouterService

logger = logging.getLogger(__name__)

openrouter_service = EnhancedOpenRouterService()

router = APIRouter(prefix="/product-search", tags=["product-search"])


class ProductItem(BaseModel):
    title: str
    image_url: str
    link: str
    images: List[str] = []
    price: Optional[str] = None
    brand: Optional[str] = None
    size: Optional[str] = None
    source: Optional[str] = None
    availability: Optional[str] = None
    description: Optional[str] = None


class ProductSearchResponse(BaseModel):
    products: List[ProductItem]
    query: str
    message: Optional[str] = None  # e.g. "Set OPENROUTER_API_KEY for live search"


class ProductSearchQueryResponse(BaseModel):
    query: str
    original_query: str
    retailer: Optional[str] = None
    message: Optional[str] = None


POPULAR_RETAILERS = [
    # Global / Europe
    "ASOS",
    "Zara",
    "H&M",
    "Mango",
    "Boohoo",
    "About You",
    "Topshop",
    "PrettyLittleThing",
    "Bershka",
    "Pull&Bear",
    "Stradivarius",
    "COS",
    "Massimo Dutti",
    "River Island",
    "Zalando",
    "SHEIN",

    # North America
    "Nordstrom",
    "Revolve",
    "Urban Outfitters",
    "Anthropologie",
    "Macy's",
    "Bloomingdale's",
    "Neiman Marcus",
    "Saks Fifth Avenue",
    "Nordstrom Rack",
    "Express",
    "American Eagle",
    "Forever 21",

    # Asia / APAC
    "Uniqlo",
    "Muji",
    "Zalora",
    "Taobao",
    "Lazada",
    "JapanLA",
    "YesStyle",

    # Africa
    "Jumia",
    "Jumia Rwanda",
    "Zando",
    "Superbalist",
    "Mr Price",
    "Woolworths SA",
    "Takealot",
    "Konga",
    "Spree",
    "Muricababa",

    # Specialty / Contemporary
    "Everlane",
    "Madewell",
    "Reformation",
    "All Saints",
    "Free People",
]


def _normalize_price(value: Optional[str]) -> Optional[str]:
    if value is None:
        return None
    if isinstance(value, str):
        return value.strip()
    return str(value)


CLOTHING_KEYWORDS = [
    "apparel",
    "clothing",
    "fashion",
    "dress",
    "skirt",
    "jean",
    "pants",
    "trouser",
    "short",
    "top",
    "shirt",
    "blouse",
    "t-shirt",
    "tee",
    "sweater",
    "cardigan",
    "hoodie",
    "jacket",
    "coat",
    "blazer",
    "suit",
    "outerwear",
    "activewear",
    "sportswear",
    "loungewear",
    "swimwear",
    "lingerie",
    "underwear",
    "socks",
    "shoes",
    "boots",
    "sneakers",
    "heels",
    "sandals",
    "bag",
    "belt",
    "scarf",
    "hat",
    "jewelry",
    "accessories",
]


def _normalize_gender(gender: Optional[str]) -> Optional[str]:
    if not gender:
        return None
    value = gender.strip().lower()
    if value in ("male", "man", "men", "boy", "male-presenting"):
        return "men"
    if value in ("female", "woman", "women", "girl", "female-presenting"):
        return "women"
    if value in ("unisex", "neutral", "non-binary", "nonbinary", "nb", "all", "all genders"):
        return "unisex"
    return value


def _contains_clothing_keywords(text: Optional[str]) -> bool:
    if not text:
        return False
    lower = text.lower()
    return any(keyword in lower for keyword in CLOTHING_KEYWORDS)


def _gather_item_text(item: dict) -> str:
    pieces = []
    for key in ("title", "name", "description", "category", "type", "brand", "merchant"):
        value = item.get(key)
        if isinstance(value, str) and value.strip():
            pieces.append(value)
        elif isinstance(value, list):
            pieces.extend(str(v) for v in value if isinstance(v, str) and v.strip())
        elif isinstance(value, dict):
            pieces.extend(str(v) for v in value.values() if isinstance(v, str) and v.strip())
    return " ".join(pieces)


def _is_clothing_item(item: dict, title: str, description: Optional[str]) -> bool:
    if _contains_clothing_keywords(title):
        return True
    if _contains_clothing_keywords(description):
        return True
    return _contains_clothing_keywords(_gather_item_text(item))


def _extract_redirect_target(link: str) -> str:
    try:
        parsed = urllib.parse.urlparse(link)
        if "google." in parsed.netloc:
            params = urllib.parse.parse_qs(parsed.query)
            for key in ("url", "u"):
                if key in params and params[key]:
                    target = params[key][0].strip()
                    if target and target.startswith(("http://", "https://")):
                        return target
            if "q" in params and params["q"]:
                target = params["q"][0].strip()
                if target.startswith(("http://", "https://")):
                    return target
        return link
    except Exception:
        return link


def _sanitize_product_link(link: Optional[str]) -> Optional[str]:
    if not link or not isinstance(link, str):
        return None
    link = link.strip()
    if link.startswith("/url?q="):
        link = urllib.parse.unquote(link[7:].split("&")[0])
    if link.startswith("/search?") or link.startswith("/images?"):
        return None
    if not _is_valid_url(link):
        return None
    try:
        parsed = urllib.parse.urlparse(link)
        if parsed.scheme and parsed.netloc:
            if parsed.query == "" and "&tbm=" in parsed.path:
                link = link.split("&tbm=")[0]
            if parsed.query == "" and "&num=" in link:
                link = link.split("&num=")[0]
            return link
    except Exception:
        return None
    return None


def _is_valid_url(value: Optional[str]) -> bool:
    return isinstance(value, str) and value.startswith(("http://", "https://"))


def _resolve_relative_url(base_url: str, target: str) -> Optional[str]:
    if not target or not isinstance(target, str):
        return None
    target = target.strip()
    if target.startswith("//"):
        return f"https:{target}"
    if target.startswith("/"):
        try:
            parsed_base = urllib.parse.urlparse(base_url)
            if parsed_base.scheme and parsed_base.netloc:
                return f"{parsed_base.scheme}://{parsed_base.netloc}{target}"
        except Exception:
            return None
    if _is_valid_url(target):
        return target
    return None


def _find_meta_content(html: str, keys: list[str]) -> Optional[str]:
    for key in keys:
        regex = re.compile(
            r'<meta[^>]+(?:property|name)=["\']%s["\'][^>]+content=["\']([^"\']+)["\']' % re.escape(key),
            re.IGNORECASE | re.DOTALL,
        )
        match = regex.search(html)
        if match:
            return match.group(1).strip()
    return None


def _extract_title(html: str) -> Optional[str]:
    match = re.search(r'<title>(.*?)</title>', html, re.IGNORECASE | re.DOTALL)
    if match:
        return match.group(1).strip()
    return None


def _extract_jsonld_objects(html: str) -> list[Any]:
    jsonld = []
    for match in re.finditer(r'<script[^>]+type=["\']application/ld\+json["\'][^>]*>(.*?)</script>', html, re.IGNORECASE | re.DOTALL):
        block = match.group(1).strip()
        try:
            data = json.loads(block)
            jsonld.append(data)
        except Exception:
            continue
    return jsonld


def _recursive_json_search(data: Any, keys: list[str]) -> Optional[Any]:
    if isinstance(data, dict):
        for k, v in data.items():
            if any(k.lower() == target.lower() for target in keys):
                return v
            result = _recursive_json_search(v, keys)
            if result is not None:
                return result
    elif isinstance(data, list):
        for item in data:
            result = _recursive_json_search(item, keys)
            if result is not None:
                return result
    return None


def _extract_page_metadata(html: str, base_url: str) -> dict[str, Optional[str]]:
    image = _find_meta_content(html, ["og:image", "twitter:image", "image"])
    if image and image.startswith("//"):
        image = "https:" + image
    if image and image.startswith("/"):
        image = urllib.parse.urljoin(base_url, image)
    if image:
        image = _normalize_image_url(image)

    title = _find_meta_content(html, ["og:title", "twitter:title"]) or _extract_title(html)
    description = _find_meta_content(html, ["og:description", "twitter:description", "description"])

    jsonld = _extract_jsonld_objects(html)
    brand = _find_meta_content(html, ["product:brand"]) or _recursive_json_search(jsonld, ["brand"])
    if isinstance(brand, dict):
        brand = brand.get("name") or brand.get("@type")
    price = _find_meta_content(html, ["product:price:amount", "og:price:amount", "price"])
    if price is None:
        price = _recursive_json_search(jsonld, ["price", "priceAmount"])
        if isinstance(price, dict):
            price = price.get("value") or price.get("price")
    availability = _find_meta_content(html, ["product:availability"]) or _recursive_json_search(jsonld, ["availability"])
    if isinstance(availability, dict):
        availability = availability.get("name") or availability.get("availability")

    images = []
    if image:
        images.append(image)
    return {
        "image_url": image,
        "images": images,
        "title": title,
        "description": description,
        "brand": brand if isinstance(brand, str) else None,
        "price": str(price).strip() if price is not None else None,
        "availability": availability if isinstance(availability, str) else None,
    }


def _extract_image_urls(html: str, base_url: str) -> List[str]:
    urls: List[str] = []

    def add_url(candidate: Optional[str]) -> None:
        if not candidate:
            return
        candidate = candidate.strip()
        if candidate.startswith("//"):
            candidate = "https:" + candidate
        if candidate.startswith("/"):
            candidate = urllib.parse.urljoin(base_url, candidate)
        if _is_valid_url(candidate) and candidate not in urls:
            urls.append(candidate)

    add_url(_normalize_image_url(_find_meta_content(html, ["og:image", "twitter:image", "image", "twitter:image:src"])))
    add_url(_normalize_image_url(_find_meta_content(html, ["og:image:secure_url", "twitter:image:secure_url"])))

    for jsonld in _extract_jsonld_objects(html):
        image_data = _recursive_json_search(jsonld, ["image"])
        if isinstance(image_data, str):
            add_url(image_data)
        elif isinstance(image_data, list):
            for item in image_data:
                if isinstance(item, str):
                    add_url(item)
                elif isinstance(item, dict):
                    add_url(item.get("url"))
        elif isinstance(image_data, dict):
            add_url(image_data.get("url"))

    for match in re.finditer(r'<link[^>]+rel=["\'](?:image_src|preload|icon|apple-touch-icon)["\'][^>]+href=["\']([^"\']+)["\']', html, re.IGNORECASE):
        add_url(match.group(1))

    for match in re.finditer(r'<img[^>]+src=["\']([^"\']+)["\']', html, re.IGNORECASE):
        src = match.group(1).strip()
        if src and not src.lower().startswith("data:"):
            add_url(src)
            if len(urls) >= 6:
                break

    return [_normalize_image_url(url) for url in urls]


async def _fetch_product_page_metadata(client, link: str) -> dict[str, Optional[str]]:
    resp = await client.get(
        link,
        headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"},
        timeout=15.0,
        follow_redirects=True,
    )
    resp.raise_for_status()
    html = resp.text
    base_url = str(resp.url)
    metadata = _extract_page_metadata(html, base_url)
    metadata["images"] = _extract_image_urls(html, base_url)
    if not metadata["image_url"]:
        for match in re.finditer(r'<img[^>]+src=["\']([^"\']+)["\']', html, re.IGNORECASE | re.DOTALL):
            src = match.group(1).strip()
            if src.startswith("http") and "logo" not in src.lower() and "icon" not in src.lower():
                metadata["image_url"] = src
                if src not in metadata["images"]:
                    metadata["images"].insert(0, src)
                break
    return metadata


async def _enrich_product_item(client, item: ProductItem) -> None:
    try:
        metadata = await _fetch_product_page_metadata(client, item.link)
        if metadata.get("image_url"):
            item.image_url = _normalize_image_url(metadata["image_url"])
        if metadata.get("images"):
            for image_url in metadata["images"]:
                if isinstance(image_url, str) and image_url not in item.images:
                    item.images.append(_normalize_image_url(image_url))
        if metadata.get("title"):
            item.title = metadata["title"]
        if metadata.get("description"):
            item.description = metadata["description"]
        if metadata.get("brand") and not item.brand:
            item.brand = metadata["brand"]
        if metadata.get("price") and not item.price:
            item.price = metadata["price"]
        if metadata.get("availability") and not item.availability:
            item.availability = metadata["availability"]
    except Exception:
        pass


def _extract_size(item: dict) -> Optional[str]:
    size = item.get("size") or item.get("sizes")
    if isinstance(size, list) and size:
        first = size[0]
        if isinstance(first, str):
            return first.strip() or None
        if isinstance(first, dict):
            return first.get("name")
    if isinstance(size, str):
        return size.strip() or None
    if isinstance(size, dict):
        return size.get("name") or size.get("value")
    return None


def _extract_brand(item: dict) -> Optional[str]:
    for key in ("brand", "merchant", "source", "website", "domain"):
        value = item.get(key)
        if isinstance(value, str) and value.strip():
            return value.strip()
        if isinstance(value, dict):
            name = value.get("name") or value.get("value")
            if isinstance(name, str) and name.strip():
                return name.strip()
    return None


def _extract_source(item: dict, link: str) -> Optional[str]:
    for key in ("source", "merchant", "brand", "website", "domain"):
        value = item.get(key)
        if isinstance(value, str) and value.strip():
            source = value.strip()
            if source.lower() != "google":
                return source
    try:
        parsed = urllib.parse.urlparse(link)
        host = parsed.netloc.replace("www.", "")
        if host:
            return host
    except Exception:
        pass
    return None


def _extract_availability(item: dict) -> Optional[str]:
    availability = item.get("availability") or item.get("stock") or item.get("availability_status")
    if isinstance(availability, dict):
        value = availability.get("value") or availability.get("status")
        if isinstance(value, str):
            availability = value
    if isinstance(availability, list) and availability:
        first = availability[0]
        if isinstance(first, str):
            availability = first
        elif isinstance(first, dict):
            availability = first.get("value") or first.get("status")
    if isinstance(availability, str):
        availability = availability.strip()
        return availability if availability else None
    return None


def _normalize_image_url(url: str) -> str:
    """Clean and normalize image URLs."""
    if not url:
        return url
    
    # Fix single slash protocols (https:/ -> https://)
    url = re.sub(r'https?:/([^/])', r'https://\1', url)
    
    # Remove extra slashes in path (but preserve //)
    url = re.sub(r'https?://([^/]+)//+', r'https://\1/', url)
    url = re.sub(r'http://([^/]+)//+', r'http://\1/', url)
    
    # Clean up multiple slashes in path (but not protocol)
    url = re.sub(r'([^:])//+', r'\1/', url)
    
    return url


def _is_sold_out_text(availability: Optional[str]) -> bool:
    if not availability:
        return False
    value = availability.lower()
    return ('sold out' in value or 'out of stock' in value or 'unavailable' in value)


async def _fallback_google_images_search(client, query: str, limit: int) -> List[ProductItem]:
    """Fallback to Google Images for clothing items from retailer sites."""
    try:
        search_query = f"{query} clothing"
        num_results = min(max(limit * 5, 20), 100)
        url = f"https://www.google.com/search?q={urllib.parse.quote(search_query)}&tbm=isch&num={num_results}"
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        }
        response = await client.get(url, headers=headers, timeout=8.0, follow_redirects=True)
        response.raise_for_status()
        html = response.text

        images = []
        seen_pairs = set()

        def add_image(image_url: str, source_url: Optional[str], title: Optional[str]) -> None:
            if not image_url:
                return
            
            # Fix malformed URLs from search results
            original_url = image_url
            image_url = image_url.strip()
            if image_url.startswith("//"):
                image_url = "https:" + image_url
            elif image_url.startswith("https:/") and not image_url.startswith("https://"):
                image_url = image_url.replace("https:/", "https://", 1)
            elif image_url.startswith("http:/") and not image_url.startswith("http://"):
                image_url = image_url.replace("http:/", "http://", 1)
            
            # Normalize the URL
            image_url = _normalize_image_url(image_url)
            
            if original_url != image_url:
                logger.debug(f"Fixed URL: {original_url} -> {image_url}")
            
            if not _is_valid_url(image_url):
                logger.debug(f"Invalid URL after fixing: {image_url}")
                return
            if source_url:
                source_url = _extract_redirect_target(source_url)
                source_url = _sanitize_product_link(source_url)
            if source_url and 'google.' in urllib.parse.urlparse(source_url).netloc:
                source_url = None
            host = None
            if source_url:
                try:
                    host = urllib.parse.urlparse(source_url).netloc.replace('www.', '').lower()
                except Exception:
                    host = None
            elif _is_valid_url(image_url):
                try:
                    host = urllib.parse.urlparse(image_url).netloc.replace('www.', '').lower()
                except Exception:
                    host = None
            title = (title or '').strip() or f"Clothing from {host or 'Google Images'}"
            key = (image_url, source_url or '')
            if key in seen_pairs:
                return
            seen_pairs.add(key)
            images.append({
                'image_url': image_url,
                'source_url': source_url or image_url,
                'title': title,
                'host': host or 'google images',
            })

        for img_match in re.finditer(r'<img[^>]+(?:src|data-src|data-iurl)=\s*["\']([^"\']+)["\']', html, re.IGNORECASE):
            img_url = img_match.group(1).strip()
            if not img_url or 'google' in img_url.lower() or img_url.startswith('data:'):
                continue
            logger.debug(f"Extracted img URL: {img_url}")
            segment = html[max(0, img_match.start() - 800): img_match.end() + 800]
            source_match = re.search(r'href=["\'](/url\?q=[^"\']+)["\']', segment)
            source_url = None
            if source_match:
                source_url = source_match.group(1)
            add_image(img_url, source_url, None)
            if len(images) >= limit * 2:
                break

        if len(images) < limit:
            redirect_links = []
            for link_match in re.finditer(r'href=["\'](/url\?q=[^"\']+)["\']', html):
                raw_link = urllib.parse.unquote(link_match.group(1)[7:].split('&')[0])
                if _is_valid_url(raw_link) and 'google.' not in urllib.parse.urlparse(raw_link).netloc:
                    redirect_links.append(raw_link)
            img_urls = []
            for img_match in re.finditer(r'<img[^>]+(?:src|data-src|data-iurl)=\s*["\']([^"\']+)["\']', html, re.IGNORECASE):
                img_url = img_match.group(1).strip()
                if _is_valid_url(img_url) and 'google' not in img_url.lower() and not img_url.startswith('data:'):
                    img_urls.append(img_url)
            for img_url in img_urls:
                source_url = redirect_links.pop(0) if redirect_links else None
                add_image(img_url, source_url, None)
                if len(images) >= limit * 2:
                    break

        products = []
        for img in images[:limit]:
            products.append(ProductItem(
                title=(img['title'] or 'Fashion item').strip(),
                image_url=_normalize_image_url(img['image_url']),
                images=[_normalize_image_url(img['image_url'])],
                link=img['source_url'] or img['image_url'],
                price=None,
                brand=None,
                source=img['host'],
                description=None,
            ))

        return products
    except Exception as e:
        logger.warning(f"Google Images fallback failed: {e}")
        return []


async def _fallback_bing_images_search(client, query: str, limit: int) -> List[ProductItem]:
    """Fallback to Bing Images for clothing items when Google images do not produce enough results."""
    try:
        search_query = f"{query} clothing"
        num_results = min(max(limit * 8, 40), 200)
        url = f"https://www.bing.com/images/search?q={urllib.parse.quote(search_query)}&count={num_results}"
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        }
        response = await client.get(url, headers=headers, timeout=8.0, follow_redirects=True)
        response.raise_for_status()
        html = response.text

        images = []
        seen_pairs = set()

        for match in re.finditer(r'<a[^>]+class=["\']iusc["\'][^>]+m=["\']([^"\']+)["\']', html, re.IGNORECASE):
            raw_payload = match.group(1).replace('&quot;', '"')
            try:
                payload = json.loads(raw_payload)
            except Exception:
                continue
            img_url = payload.get('murl') or payload.get('turl') or payload.get('purl')
            source_url = payload.get('purl') or payload.get('surl')
            
            # Fix malformed URLs from Bing results
            if img_url:
                img_url = img_url.strip()
                if img_url.startswith("//"):
                    img_url = "https:" + img_url
                elif img_url.startswith("https:/") and not img_url.startswith("https://"):
                    img_url = img_url.replace("https:/", "https://", 1)
                elif img_url.startswith("http:/") and not img_url.startswith("http://"):
                    img_url = img_url.replace("http:/", "http://", 1)
                img_url = _normalize_image_url(img_url)
            
            if not _is_valid_url(img_url):
                continue
            
            source_url = _sanitize_product_link(source_url)
            if source_url and 'bing.com' in urllib.parse.urlparse(source_url).netloc.lower():
                source_url = None
            host = None
            if source_url:
                host = urllib.parse.urlparse(source_url).netloc.replace('www.', '').lower()
            else:
                host = urllib.parse.urlparse(img_url).netloc.replace('www.', '').lower()
            key = (img_url, source_url or '')
            if key in seen_pairs:
                continue
            seen_pairs.add(key)
            images.append({
                'image_url': img_url,
                'source_url': source_url or img_url,
                'title': f"Clothing from {host or 'Bing Images'}",
                'host': host or 'bing images',
            })
            if len(images) >= limit * 2:
                break

        products = []
        for img in images[:limit]:
            products.append(ProductItem(
                title=(img['title'] or 'Fashion item').strip(),
                image_url=_normalize_image_url(img['image_url']),
                images=[_normalize_image_url(img['image_url'])],
                link=img['source_url'] or img['image_url'],
                price=None,
                brand=None,
                source=img['host'],
                description=None,
            ))

        return products
    except Exception as e:
        logger.warning(f"Bing Images fallback failed: {e}")
        return []


def _extract_serper_price(item: dict) -> Optional[str]:
    if not isinstance(item, dict):
        return None
    for key in ("price", "formattedPrice", "displayedPrice", "priceText", "amount", "value"):
        value = item.get(key)
        if isinstance(value, str) and value.strip():
            return value.strip()
        if isinstance(value, (int, float)):
            return str(value)
        if isinstance(value, dict):
            for sub in ("current", "value", "amount", "displayPrice"):
                nested = value.get(sub)
                if isinstance(nested, str) and nested.strip():
                    return nested.strip()
                if isinstance(nested, (int, float)):
                    return str(nested)
    return None


async def _fallback_serper_search(client, query: str, limit: int) -> List[ProductItem]:
    """Fallback to Serper.dev when OpenRouter search is unavailable or lacks results."""
    if not settings.SERPER_API_KEY or not query:
        return []
    try:
        url = settings.SERPER_API_BASE_URL
        params = {"q": query, "apiKey": settings.SERPER_API_KEY}
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        }
        response = await client.get(url, headers=headers, params=params, timeout=10.0)
        response.raise_for_status()
        data = response.json()

        results = []
        if isinstance(data.get("shopping_results"), list):
            results = data.get("shopping_results")
        elif isinstance(data.get("organic_results"), list):
            results = data.get("organic_results")
        elif isinstance(data.get("images"), list):
            results = data.get("images")
        elif isinstance(data, dict) and data.get("results"):
            results = data.get("results")

        products: List[ProductItem] = []
        seen_links = set()

        for item in results:
            if not isinstance(item, dict):
                continue
            title = (item.get("title") or item.get("name") or item.get("snippet") or "Fashion item").strip()
            link = item.get("link") or item.get("url") or item.get("source") or item.get("destinationUrl") or item.get("target")
            if isinstance(link, str):
                link = link.strip()
                if link.startswith("/url?q="):
                    link = _extract_redirect_target(link)
            if isinstance(link, dict):
                link = link.get("url") or link.get("href")
            image_url = item.get("thumbnail") or item.get("image") or item.get("imageUrl") or item.get("img")
            if isinstance(image_url, dict):
                image_url = image_url.get("src") or image_url.get("url")
            if isinstance(image_url, list) and image_url:
                image_url = image_url[0]
            if isinstance(image_url, str):
                image_url = image_url.strip()
                if image_url.startswith("//"):
                    image_url = f"https:{image_url}"
            if not _is_valid_url(image_url) or not _is_valid_url(link):
                continue
            if link in seen_links:
                continue

            products.append(ProductItem(
                title=title,
                image_url=_normalize_image_url(image_url),
                images=[_normalize_image_url(image_url)],
                link=link,
                price=_extract_serper_price(item),
                brand=(item.get("source") or item.get("merchant") or item.get("domain")) if isinstance(item.get("source"), str) else None,
                source="serper",
                description=(item.get("description") if isinstance(item.get("description"), str) else None),
            ))
            seen_links.add(link)
            if len(products) >= limit:
                break

        return products
    except Exception as e:
        logger.warning(f"Serper fallback failed: {e}")
        return []


async def _fallback_zara_search(client, query: str, limit: int) -> List[ProductItem]:
    """Custom Zara scraper fallback for brand-specific product search."""
    if not query:
        return []
    try:
        search_url = f"https://www.zara.com/us/en/search?searchTerm={urllib.parse.quote(query)}"
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        }
        response = await client.get(search_url, headers=headers, timeout=10.0, follow_redirects=True)
        response.raise_for_status()
        html = response.text

        products: List[ProductItem] = []
        seen_links = set()
        pattern = re.compile(
            r'<a[^>]+href=["\'](?P<href>[^"\']+)["\'][^>]*>.*?<img[^>]+(?:data-src|src|srcset)=["\'](?P<src>[^"\']+)["\']',
            re.IGNORECASE | re.DOTALL,
        )

        for match in pattern.finditer(html):
            href = match.group("href")
            src = match.group("src").split()[0]
            link = _resolve_relative_url(search_url, href)
            image_url = _resolve_relative_url(search_url, src)
            if not link or not image_url:
                continue
            if link in seen_links:
                continue
            if not _is_product_page_link(link):
                continue
            seen_links.add(link)
            products.append(ProductItem(
                title=query.strip(),
                image_url=_normalize_image_url(image_url),
                images=[_normalize_image_url(image_url)],
                link=link,
                price=None,
                brand="Zara",
                source="zara-scraper",
            ))
            if len(products) >= limit:
                break

        return products
    except Exception as e:
        logger.debug(f"Zara scraper failed: {e}")
        return []


async def _fallback_hm_search(client, query: str, limit: int) -> List[ProductItem]:
    """Custom H&M scraper fallback for brand-specific product search."""
    if not query:
        return []
    try:
        search_url = f"https://www2.hm.com/en_us/search-results.html?q={urllib.parse.quote(query)}"
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        }
        response = await client.get(search_url, headers=headers, timeout=10.0, follow_redirects=True)
        response.raise_for_status()
        html = response.text

        products: List[ProductItem] = []
        seen_links = set()
        pattern = re.compile(
            r'<a[^>]+href=["\'](?P<href>[^"\']+)["\'][^>]*>.*?<img[^>]+(?:data-src|src|srcset)=["\'](?P<src>[^"\']+)["\']',
            re.IGNORECASE | re.DOTALL,
        )

        for match in pattern.finditer(html):
            href = match.group("href")
            src = match.group("src").split()[0]
            link = _resolve_relative_url(search_url, href)
            image_url = _resolve_relative_url(search_url, src)
            if not link or not image_url:
                continue
            if link in seen_links:
                continue
            if not _is_product_page_link(link):
                continue
            seen_links.add(link)
            products.append(ProductItem(
                title=query.strip(),
                image_url=_normalize_image_url(image_url),
                images=[_normalize_image_url(image_url)],
                link=link,
                price=None,
                brand="H&M",
                source="hm-scraper",
            ))
            if len(products) >= limit:
                break

        return products
    except Exception as e:
        logger.debug(f"H&M scraper failed: {e}")
        return []


async def _fallback_google_retail_search(client, query: str, limit: int) -> List[ProductItem]:
    """Optional fallback to Google Cloud Retail when a configured catalog is available."""
    if not settings.GOOGLE_RETAIL_API_KEY or not settings.GOOGLE_RETAIL_PROJECT_ID:
        return []
    try:
        search_query = f"{query} clothing"
        url = (
            f"https://retail.googleapis.com/v2/projects/{settings.GOOGLE_RETAIL_PROJECT_ID}"
            f"/locations/{settings.GOOGLE_RETAIL_LOCATION}"
            f"/catalogs/{settings.GOOGLE_RETAIL_CATALOG}"
            f"/placements/{settings.GOOGLE_RETAIL_PLACEMENT}:search?key={settings.GOOGLE_RETAIL_API_KEY}"
        )
        payload = {
            "query": search_query,
            "visitorId": "cleo-fashion-fallback",
            "pageSize": min(max(limit, 1), 50),
            "branch": (
                f"projects/{settings.GOOGLE_RETAIL_PROJECT_ID}"
                f"/locations/{settings.GOOGLE_RETAIL_LOCATION}"
                f"/catalogs/{settings.GOOGLE_RETAIL_CATALOG}"
                f"/branches/{settings.GOOGLE_RETAIL_BRANCH}"
            ),
            "userInfo": {"visitorId": "cleo-fashion-fallback"},
        }
        response = await client.post(url, json=payload, timeout=8.0)
        response.raise_for_status()
        data = response.json()
        raw_results = data.get("results") or []
        products: List[ProductItem] = []
        seen_links = set()

        for result in raw_results:
            if not isinstance(result, dict):
                continue
            product_data = result.get("product") or {}
            title = (
                product_data.get("title")
                or product_data.get("name")
                or product_data.get("displayName")
                or "Fashion item"
            )
            link = (
                product_data.get("uri")
                or product_data.get("canonicalUri")
                or product_data.get("availableUri")
                or result.get("uri")
            )
            if isinstance(link, str):
                link = _sanitize_product_link(link) or link.strip()
            if not _is_valid_url(link):
                continue

            images: List[str] = []
            image_url = None
            for image_data in product_data.get("images") or []:
                candidate = None
                if isinstance(image_data, dict):
                    candidate = image_data.get("uri") or image_data.get("imageUri") or image_data.get("url")
                elif isinstance(image_data, str):
                    candidate = image_data
                if isinstance(candidate, str) and _is_valid_url(candidate):
                    normalized = _normalize_image_url(candidate)
                    if normalized not in images:
                        images.append(normalized)
                    if image_url is None:
                        image_url = normalized
            if not image_url:
                continue

            price = None
            price_info = product_data.get("priceInfo") or result.get("priceInfo") or {}
            if isinstance(price_info, dict):
                amount = price_info.get("price") or price_info.get("amount") or price_info.get("value")
                if amount is not None:
                    price = str(amount).strip()

            source = "google retail"
            products.append(ProductItem(
                title=str(title).strip(),
                image_url=image_url,
                images=images or [image_url],
                link=link,
                price=price,
                brand=(product_data.get("brand") if isinstance(product_data.get("brand"), str) else None),
                source=source,
                description=(product_data.get("description") if isinstance(product_data.get("description"), str) else None),
            ))
            if len(products) >= limit:
                break

        return products
    except Exception as e:
        logger.warning(f"Google Retail fallback failed: {e}")
        return []


async def _fallback_asos_search(client, query: str, limit: int) -> List[ProductItem]:
    """Fallback to ASOS RapidAPI for real product image fetching."""
    if not settings.ASOS_RAPIDAPI_KEY:
        return []
    
    try:
        products: List[ProductItem] = []
        seen_links = set()
        
        # Try multiple ASOS API endpoints
        headers = {
            "x-rapidapi-host": settings.ASOS_RAPIDAPI_HOST,
            "x-rapidapi-key": settings.ASOS_RAPIDAPI_KEY,
            "Content-Type": "application/json"
        }
        
        # Endpoint 1: Search products
        search_endpoints = [
            f"https://{settings.ASOS_RAPIDAPI_HOST}/products/v2/list",  # v2 search
            f"https://{settings.ASOS_RAPIDAPI_HOST}/products/list",  # v1 search
            f"https://{settings.ASOS_RAPIDAPI_HOST}/marketplace/search",  # marketplace search
        ]
        
        for endpoint_url in search_endpoints:
            try:
                # Try search with different parameter combinations
                search_params = {
                    "q": query,
                    "country": "US",
                    "store": "US",
                    "limit": min(limit - len(products), 50),
                    "offset": 0
                }
                
                logger.debug(f"Trying ASOS endpoint: {endpoint_url}")
                response = await client.get(endpoint_url, headers=headers, params=search_params, timeout=8.0)
                
                if response.status_code == 200:
                    data = response.json()
                    results = data.get("results") or data.get("data") or data.get("products") or []
                    
                    logger.debug(f"ASOS response: {len(results)} results from {endpoint_url}")
                    
                    for item in results if isinstance(results, list) else []:
                        if not isinstance(item, dict):
                            continue
                        
                        # Extract product info - flexible field names
                        title = (
                            item.get("name") or 
                            item.get("title") or 
                            item.get("product_name") or
                            "Fashion item"
                        )
                        
                        link = (
                            item.get("url") or 
                            item.get("link") or 
                            item.get("product_url")
                        )
                        
                        if not link:
                            # Try to construct link from ID
                            item_id = item.get("id")
                            if item_id:
                                link = f"https://www.asos.com/api/product/{item_id}/"
                        
                        # Get image - try multiple field names
                        image_url = None
                        for img_field in ["image", "imageUrl", "image_url", "image_link", "img", "thumbnail", "thumbnailUrl"]:
                            candidate = item.get(img_field)
                            if candidate:
                                if isinstance(candidate, list) and len(candidate) > 0:
                                    image_url = candidate[0]
                                elif isinstance(candidate, str):
                                    image_url = candidate
                                break
                        
                        if not image_url:
                            # Try nested image paths
                            images_obj = item.get("images")
                            if isinstance(images_obj, dict):
                                image_url = images_obj.get("url") or images_obj.get("image_url")
                            elif isinstance(images_obj, list) and len(images_obj) > 0:
                                if isinstance(images_obj[0], dict):
                                    image_url = images_obj[0].get("url") or images_obj[0].get("image_url")
                                else:
                                    image_url = images_obj[0]
                        
                        if not image_url or not link:
                            continue
                        
                        # Normalize image URL (handle protocol-relative URLs)
                        if isinstance(image_url, str):
                            if image_url.startswith("//"):
                                image_url = f"https:{image_url}"
                        
                        if not _is_valid_url(image_url) or not _is_valid_url(link):
                            continue
                        
                        # Extract price
                        price = None
                        for price_field in ["price", "pricePrice", "price_price", "salePrice", "cost"]:
                            candidate = item.get(price_field)
                            if candidate:
                                if isinstance(candidate, dict):
                                    price = candidate.get("current") or candidate.get("value") or candidate.get("amount")
                                else:
                                    price = candidate
                                break
                        
                        if link not in seen_links:
                            products.append(ProductItem(
                                title=str(title).strip(),
                                image_url=_normalize_image_url(image_url),
                                images=[_normalize_image_url(image_url)],
                                link=link if _is_valid_url(link) else f"https://www.asos.com/search/?q={query}",
                                price=str(price).strip() if price else None,
                                brand=item.get("brand") or item.get("brandName"),
                                source="asos",
                                description=item.get("description") or item.get("productDescription"),
                            ))
                            seen_links.add(link)
                            
                            if len(products) >= limit:
                                logger.info(f"ASOS search: found {len(products)} products for '{query}' via {endpoint_url}")
                                return products
                    
                    if products:
                        logger.info(f"ASOS search: found {len(products)} products for '{query}'")
                        return products
                        
            except Exception as e:
                logger.debug(f"ASOS endpoint {endpoint_url} failed: {e}")
                continue
        
        logger.debug(f"ASOS: No products found for '{query}' after trying all endpoints")
        return products
    
    except Exception as e:
        logger.debug(f"ASOS fallback search failed: {e}")
        return []


async def _fallback_supabase_images(query: str, limit: int) -> List[ProductItem]:
    """Fallback to Supabase product catalog cache when available."""
    try:
        from supabase import create_client
        client = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)
        
        # Query image metadata from Supabase products table (if exists)
        response = client.table("products").select("*").ilike("tags", f"%{query.lower()}%").limit(limit).execute()
        
        products: List[ProductItem] = []
        for item in response.data:
            image_url = item.get("image_url")
            if not image_url or not _is_valid_url(image_url):
                continue
            
            products.append(ProductItem(
                title=item.get("title", "Product"),
                image_url=_normalize_image_url(image_url),
                images=[_normalize_image_url(image_url)] if image_url else [],
                link=item.get("link", image_url),
                price=item.get("price"),
                brand=item.get("brand"),
                source="supabase-catalog",
                description=item.get("description"),
            ))
            if len(products) >= limit:
                break
        
        return products
    except Exception as e:
        logger.debug(f"Supabase catalog fallback unavailable: {e}")
        return []


async def _fallback_static_catalog(query: str, limit: int) -> List[ProductItem]:
    """Fallback to local static product catalog (no API calls needed)."""
    try:
        import os
        catalog_path = os.path.join(os.path.dirname(__file__), "..", "..", "data", "products.json")
        
        if not os.path.exists(catalog_path):
            return []
        
        with open(catalog_path, "r", encoding="utf-8") as f:
            catalog = json.load(f)
        
        search_lower = query.lower()
        search_terms = search_lower.split()
        
        matches = []
        for item in catalog:
            if not isinstance(item, dict):
                continue
            
            item_text = " ".join([
                item.get("title", ""),
                item.get("brand", ""),
                item.get("tags", "")
            ]).lower()
            
            # Match if any search term appears in the item
            if any(term in item_text for term in search_terms):
                matches.append(item)
        
        # Sort by relevance (more matching terms = higher priority)
        matches.sort(key=lambda item: sum(
            1 for term in search_terms 
            if term in " ".join([
                item.get("title", ""),
                item.get("brand", ""),
                item.get("tags", "")
            ]).lower()
        ), reverse=True)
        
        products: List[ProductItem] = []
        for item in matches[:limit]:
            image_url = item.get("image_url", "")
            if not _is_valid_url(image_url):
                continue
            
            products.append(ProductItem(
                title=item.get("title", "Fashion item"),
                image_url=_normalize_image_url(image_url),
                images=[_normalize_image_url(image_url)],
                link=item.get("link", image_url),
                price=item.get("price"),
                brand=item.get("brand"),
                source="local-catalog",
                description=item.get("description"),
            ))
        
        logger.info(f"Static catalog: found {len(products)} matches for '{query}'")
        return products
    except Exception as e:
        logger.debug(f"Static catalog fallback failed: {e}")
        return []


async def _fallback_fashion_scraper(httpx_client, query: str, limit: int) -> List[ProductItem]:
    """Fallback to fashion scraper service for real-time retailer data."""
    if not httpx_client:
        return []
    
    try:
        from ..services.fashion_scraper_service import FashionScraperService
        scraper = FashionScraperService(httpx_client)
        
        # Determine which retailer to scrape based on query
        query_lower = query.lower()
        retailer = None
        
        if "zara" in query_lower:
            retailer = "zara"
        elif "h&m" in query_lower or "hm" in query_lower:
            retailer = "hm"
        elif "asos" in query_lower:
            retailer = "asos"
        else:
            # Default to ASOS for general fashion queries
            retailer = "asos"
        
        # Scrape products
        scraped_products = await scraper.scrape_one(retailer, "full", min(limit, 10))
        
        products: List[ProductItem] = []
        for item in scraped_products:
            if not isinstance(item, dict):
                continue
            
            image_url = item.get("image_urls", [""])[0] if item.get("image_urls") else ""
            if not image_url or not _is_valid_url(image_url):
                continue
            
            product = ProductItem(
                title=item.get("product_name", "Fashion item"),
                image_url=_normalize_image_url(image_url),
                images=[_normalize_image_url(image_url)],
                link=item.get("product_url", ""),
                price=item.get("price", ""),
                brand=item.get("brand", ""),
                source=item.get("source_site", retailer),
                description=item.get("category", ""),
            )
            
            products.append(product)
            if len(products) >= limit:
                break
        
        logger.info(f"Fashion scraper: found {len(products)} products from {retailer} for '{query}'")
        return products
    except Exception as e:
        logger.debug(f"Fashion scraper fallback failed: {e}")
        return []


def _retailer_host_contains(site: str) -> Optional[str]:
    provider = site.strip().lower()
    if provider == "asos":
        return "asos.com"
    if provider == "zara":
        return "zara.com"
    if provider == "h&m" or provider == "hm":
        return "hm.com"
    if provider == "nordstrom":
        return "nordstrom.com"
    if provider == "mango":
        return "mango.com"
    if provider == "revolve":
        return "revolve.com"
    if provider == "boohoo":
        return "boohoo.com"
    if provider == "urban outfitters" or provider == "urbanoutfitters":
        return "urbanoutfitters.com"
    if provider == "shein":
        return "shein.com"
    if provider == "jumia":
        return "jumia.com"
    if provider == "jumia rwanda":
        return "jumia.rw"
    if provider == "zando":
        return "zando.co.za"
    if provider == "superbalist":
        return "superbalist.com"
    if provider == "mr price" or provider == "mrprice":
        return "mrprice.com"
    if provider == "woolworths sa" or provider == "woolworths":
        return "woolworths.co.za"
    if provider == "takealot":
        return "takealot.com"
    if provider == "konga":
        return "konga.com"
    if provider == "spree":
        return "spree.co.za"
    if provider == "muricababa":
        return "muricababa.com"
    return None


def _build_search_query(query: str, site: Optional[str], gender: Optional[str] = None) -> str:
    base_query = query.strip()
    if not base_query:
        return ''
    normalized_gender = _normalize_gender(gender)
    if normalized_gender and normalized_gender != 'unisex' and normalized_gender not in base_query.lower():
        base_query = f"{base_query} {normalized_gender}"

    if not any(keyword in base_query.lower() for keyword in CLOTHING_KEYWORDS):
        base_query = f"{base_query} clothing"

    if site and site.lower() != 'any store':
        host = _retailer_host_contains(site)
        if host:
            return f"{base_query} site:{host}"
    return base_query


def _is_retailer_link(link: str, site: str) -> bool:
    host_filter = _retailer_host_contains(site)
    if not host_filter:
        return True
    try:
        parsed = urllib.parse.urlparse(link)
        host = parsed.netloc.replace("www.", "").lower()
        return host_filter in host
    except Exception:
        return False


def _is_product_page_link(link: str) -> bool:
    try:
        parsed = urllib.parse.urlparse(link)
        path = parsed.path.lower()
        if not path or path == "/":
            return False
        if any(token in path for token in ("/search", "/shop/", "/browse", "/category", "/collections", "/filter", "/catalog", "/explore", "/wishlist", "/cart", "/checkout")):
            return False
        return True
    except Exception:
        return True


async def _is_link_reachable(client, link: str) -> bool:
    try:
        response = await client.head(link, follow_redirects=True, timeout=5.0)
        if 200 <= response.status_code < 400:
            return True

        if response.status_code in (405, 403):
            response = await client.get(link, follow_redirects=True, timeout=10.0)
            if 200 <= response.status_code < 400:
                return True
            if response.status_code == 403:
                parsed = urllib.parse.urlparse(link)
                host = parsed.netloc.replace('www.', '').lower()
                # Many retailer sites block automated bot requests but still represent valid product pages.
                if any(known in host for known in [
                    'zara.com', 'hm.com', 'asos.com', 'revolve.com',
                    'nordstrom.com', 'urbanoutfitters.com', 'shein.com',
                    'mango.com', 'boohoo.com', 'zalando.com', 'uniqlo.com',
                ]):
                    return True
        return False
    except Exception:
        return False


def _parse_shopping_results(data: dict, limit: int) -> List[ProductItem]:
    products = []
    shopping_results = data.get("shopping_results") or data.get("organic_results") or []
    for item in shopping_results[:limit]:
        if not isinstance(item, dict):
            continue
        title = item.get("title") or item.get("name") or ""
        raw_link = item.get("product_link") or item.get("link") or ""
        link = _extract_redirect_target(raw_link)
        if not _is_valid_url(link) and isinstance(raw_link, str) and _is_valid_url(raw_link):
            link = raw_link
        thumb = item.get("thumbnail") or item.get("image")
        if isinstance(thumb, list) and thumb:
            thumb = thumb[0] if isinstance(thumb[0], str) else (thumb[0].get("image") if isinstance(thumb[0], dict) else "")
        image_url = (thumb if isinstance(thumb, str) and thumb else "") or link
        if isinstance(thumb, list) and thumb:
            thumb = thumb[0] if isinstance(thumb[0], str) else (thumb[0].get("image") if isinstance(thumb[0], dict) else "")
            if isinstance(thumb, str) and thumb:
                image_url = thumb
        images: List[str] = []
        raw_images = item.get("images")
        if isinstance(raw_images, list):
            for entry in raw_images:
                if isinstance(entry, str) and entry.strip():
                    images.append(entry.strip())
                elif isinstance(entry, dict):
                    if isinstance(entry.get("url"), str) and entry["url"].strip():
                        images.append(entry["url"].strip())
        if not images and image_url:
            images.append(image_url)

        price = _normalize_price(item.get("price") or item.get("extracted_price"))
        brand = _extract_brand(item)
        size = _extract_size(item)
        source = _extract_source(item, link)
        availability = _extract_availability(item)
        if title and (image_url or link):
            products.append(
                ProductItem(
                    title=title,
                    image_url=image_url or link,
                    images=images,
                    link=link,
                    price=price,
                    brand=brand,
                    size=size,
                    source=source,
                    availability=availability,
                    description=item.get("description") if isinstance(item.get("description"), str) else None,
                )
            )
    return products


@router.get("/rewrite", response_model=ProductSearchQueryResponse)
async def rewrite_search_query(
    q: str = Query(..., min_length=1, description="User search request (e.g. find a summer dress for brunch)"),
    site: Optional[str] = Query(None, description="Optional retailer name to bias the query."),
    gender: Optional[str] = Query(None, description="Optional user gender preference for search relevance."),
):
    original_query = (q or "").strip()
    if not original_query:
        return ProductSearchQueryResponse(
            query="",
            original_query="",
            retailer=site,
            message="Please provide a search request.",
        )

    if not settings.OPENROUTER_API_KEY:
        rewritten = _build_search_query(original_query, site, gender)
        return ProductSearchQueryResponse(
            query=rewritten,
            original_query=original_query,
            retailer=site,
            message="OpenRouter is not configured; returning fallback query.",
        )

    try:
        rewritten = await openrouter_service.rewrite_shopping_query(original_query, site, gender, trace_id="query-rewrite")
        return ProductSearchQueryResponse(
            query=rewritten,
            original_query=original_query,
            retailer=site,
        )
    except Exception as e:
        logger.warning("Shopping query rewrite failed: %s", e)
        rewritten = _build_search_query(original_query, site, gender)
        return ProductSearchQueryResponse(
            query=rewritten,
            original_query=original_query,
            retailer=site,
            message="Query rewrite failed; using fallback search query.",
        )


@router.get("", response_model=ProductSearchResponse)
async def search_products(
    q: str = Query(..., min_length=1, description="Search query (e.g. white blazer women)"),
    limit: int = Query(12, ge=1, le=50),
    site: Optional[str] = Query(None, description="Optional retailer name to bias the search."),
    gender: Optional[str] = Query(None, description="Optional user gender preference for the search."),
):
    """
    Search for fashion products. Returns image URL, title, and buy link for each.
    Used when the user asks for shopping help — AI outputs SEARCH_PRODUCTS=<query>, app calls this, then shows images with Try on + Buy.
    """
    original_query = (q or "").strip()
    site = (site or "").strip()
    if not original_query:
        return ProductSearchResponse(products=[], query="", message="Tell us what you want to wear.")
    query = original_query
    if site and site.lower() != 'any store':
        query = f"{query} {site}"

    if not settings.OPENROUTER_API_KEY:
        return ProductSearchResponse(
            products=[],
            query=query,
            message="Live runway search is not configured. Set OPENROUTER_API_KEY and try again.",
        )

    resource_mgr = get_resource_manager()
    httpx_client = resource_mgr.httpx_client if resource_mgr and resource_mgr.httpx_client else None

    try:
        raw_products: List[ProductItem] = []
        seen_links = set()
        seen_hosts = set()
        try:
            search_query = await asyncio.wait_for(
                openrouter_service.rewrite_shopping_query(
                    original_query,
                    site if site and site.lower() != 'any store' else None,
                    gender,
                    trace_id="query-rewrite",
                ),
                timeout=8.0,
            )
        except Exception as e:
            logger.warning("Shopping query rewrite failed or timed out: %s", e)
            search_query = _build_search_query(original_query, site if site and site.lower() != 'any store' else None, gender)

        try:
            raw_results = await asyncio.wait_for(
                openrouter_service.search_shopping_products(
                    search_query,
                    retailer=site if site and site.lower() != 'any store' else None,
                    gender=gender,
                    limit=min(max(limit, 20), 30),
                    trace_id="openrouter-product-search",
                ),
                timeout=12.0,  # Increased from 8.0 to 12.0 seconds
            )
        except Exception as e:
            logger.warning("Shopping product search failed or timed out: %s", e)
            raw_results = []

        for item in raw_results:
            if not isinstance(item, dict):
                continue

            title = item.get("title") or item.get("name") or "Fashion piece"
            raw_link = item.get("link") or item.get("url") or ""
            link = _extract_redirect_target(str(raw_link).strip()) if raw_link else ""
            if not _is_valid_url(link) and isinstance(raw_link, str) and _is_valid_url(raw_link.strip()):
                link = raw_link.strip()

            image_url = item.get("image_url") or item.get("thumbnail") or item.get("image") or ""
            if isinstance(image_url, list) and image_url:
                image_url = image_url[0]
            image_url = image_url.strip() if isinstance(image_url, str) else ""

            images: List[str] = []
            raw_images = item.get("images")
            if isinstance(raw_images, list):
                for entry in raw_images:
                    if isinstance(entry, str) and entry.strip():
                        images.append(entry.strip())
                    elif isinstance(entry, dict):
                        if isinstance(entry.get("url"), str) and entry["url"].strip():
                            images.append(entry["url"].strip())
            if not images and image_url:
                images.append(image_url)

            if not link and image_url:
                link = image_url

            if not title or not image_url:
                continue
            if link and not _is_product_page_link(link):
                # allow image links as fallback even if not a classic product page
                if not link.lower().endswith(('.jpg', '.jpeg', '.png', '.webp')):
                    continue

            product = ProductItem(
                title=title.strip(),
                image_url=_normalize_image_url(image_url or link),
                images=[_normalize_image_url(img) for img in images if img],
                link=link,
                price=_normalize_price(item.get("price") or item.get("cost")),
                brand=item.get("brand") if isinstance(item.get("brand"), str) else None,
                source=item.get("source") if isinstance(item.get("source"), str) else _extract_source(item, link),
                availability=item.get("availability") if isinstance(item.get("availability"), str) else None,
                description=item.get("description") if isinstance(item.get("description"), str) else None,
            )

            if product.link in seen_links:
                continue

            raw_products.append(product)
            if product.link:
                seen_links.add(product.link)

        products = raw_products[:limit]

        # If not enough products, try a fallback search path.
        if len(products) < limit:
            try:
                fallback_tasks = []
                # Always try local sources first (no API required)
                fallback_tasks.extend([
                    _fallback_supabase_images(original_query, limit - len(products)),
                    _fallback_fashion_scraper(httpx_client, original_query, limit - len(products)),
                ])
                if search_query != original_query:
                    fallback_tasks.extend([
                        _fallback_supabase_images(search_query, limit - len(products)),
                        _fallback_fashion_scraper(httpx_client, search_query, limit - len(products)),
                    ])
                
                # Try external API fallbacks if httpx_client available
                if httpx_client:
                    if settings.SERPER_API_KEY:
                        fallback_tasks.append(_fallback_serper_search(httpx_client, search_query, limit - len(products)))

                    if site and site.lower() == "zara":
                        fallback_tasks.append(_fallback_zara_search(httpx_client, original_query, limit - len(products)))
                    elif site and site.lower() in ("h&m", "hm"):
                        fallback_tasks.append(_fallback_hm_search(httpx_client, original_query, limit - len(products)))
                    else:
                        query_lower = search_query.lower()
                        if "zara" in query_lower:
                            fallback_tasks.append(_fallback_zara_search(httpx_client, original_query, limit - len(products)))
                        if "h&m" in query_lower or "hm" in query_lower:
                            fallback_tasks.append(_fallback_hm_search(httpx_client, original_query, limit - len(products)))

                    if settings.GOOGLE_RETAIL_API_KEY and settings.GOOGLE_RETAIL_PROJECT_ID:
                        fallback_tasks.append(_fallback_google_retail_search(httpx_client, search_query, limit - len(products)))
                    
                    # Add ASOS RapidAPI search for real product images
                    if settings.ASOS_RAPIDAPI_KEY:
                        fallback_tasks.append(_fallback_asos_search(httpx_client, search_query, limit - len(products)))
                    
                    fallback_tasks.extend([
                        _fallback_google_images_search(httpx_client, search_query, limit - len(products)),
                        _fallback_bing_images_search(httpx_client, search_query, limit - len(products)),
                    ])
                
                fallback_results = await asyncio.gather(*fallback_tasks, return_exceptions=True)
                for result in fallback_results:
                    if isinstance(result, Exception):
                        logger.warning("Fallback search failed: %s", result)
                        continue
                    for fb_product in result:
                        if len(products) >= limit:
                            break
                        if fb_product.link not in seen_links:
                            products.append(fb_product)
                            seen_links.add(fb_product.link)
            except Exception as e:
                logger.warning("Fallback search gather failed: %s", e)

        if products:
            products.sort(key=lambda item: _is_sold_out_text(item.availability))

        if not products:
            return ProductSearchResponse(
                products=[],
                query=query,
                message="No runway-ready matches were found for that look.",
            )

        return ProductSearchResponse(products=products, query=query)
    except Exception as e:
        logger.warning("OpenRouter product search failed: %s", e)
        return ProductSearchResponse(
            products=[],
            query=query,
            message="Our fashion search missed the beat. Please try again.",
        )
