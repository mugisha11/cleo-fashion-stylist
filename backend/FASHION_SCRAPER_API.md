# Fashion Scraper API Documentation

## Overview

The Fashion Scraper API provides real-time product data from major fashion retailers:
- **ASOS** (asos.com)
- **H&M** (hm.com)
- **Zara** (zara.com)

Scraped data includes product URLs, prices, brands, categories, images, and customer ratings for trend analysis and product recommendations.

## Architecture

### Components

1. **Fashion Scraper Service** (`backend/app/services/fashion_scraper_service.py`)
   - Core async scraping logic using `httpx` (no Scrapy dependency)
   - Implements retailer-specific HTML parsing (regex-based)
   - Handles concurrent multi-retailer scraping
   - Data normalization utilities

2. **Fashion Scraper Router** (`backend/app/api/fashion_scraper.py`)
   - FastAPI endpoint definitions
   - Request/response schemas (Pydantic models)
   - Exception handling and logging
   - Resource dependency injection

3. **FastAPI Integration** (`backend/app/main.py`)
   - Router registration in main app
   - Lifespan manager for resource initialization

### Design Decisions

- **No Scrapy**: Avoids Windows event loop conflicts with FastAPI
- **Async/await**: Uses `httpx` + `asyncio` for concurrent scraping
- **Regex parsing**: Simpler than CSS selectors, fewer dependencies
- **Dict-based items**: `FashionProductItem` mirrors external pipeline schema

## API Endpoints

### Base URL
```
POST /fashion-scraper/scrape
POST /fashion-scraper/scrape-all
GET  /fashion-scraper/status
```

---

### Single Retailer Scrape

**Endpoint:** `POST /fashion-scraper/scrape`

**Query Parameters:**
```
retailer  : str  = "asos"   # Required: asos, hm, or zara
mode      : str  = "full"   # Required: full or new_arrivals
limit     : int  = 50       # Optional: 1-500 products
```

**Request:**
```bash
curl -X POST "http://localhost:8001/fashion-scraper/scrape?retailer=asos&mode=full&limit=20"
```

**Response (200 OK):**
```json
{
  "retailer": "asos",
  "mode": "full",
  "products_count": 20,
  "products": [
    {
      "product_url": "https://www.asos.com/asos-design/asos-design-...",
      "source_site": "asos.com",
      "scrape_timestamp": "2024-04-19T01:39:00",
      "scrape_mode": "full",
      "product_name": "ASOS DESIGN Cotton Blend Blazer",
      "price": 89.95,
      "brand": "ASOS DESIGN",
      "category": "Blazers",
      "image_urls": ["https://images.asos-media.com/..."],
      "customer_rating": 4.5
    },
    ...
  ],
  "message": "Successfully scraped 20 products from ASOS"
}
```

**Error Responses:**
```json
400 Bad Request
{
  "detail": "Unknown retailer: walmart. Use: asos, hm, or zara"
}

503 Service Unavailable
{
  "detail": "Resource manager unavailable"
}

500 Internal Server Error
{
  "detail": "Scraping failed: Connection timeout"
}
```

---

### Multi-Retailer Concurrent Scrape

**Endpoint:** `POST /fashion-scraper/scrape-all`

**Query Parameters:**
```
retailers           : List[str] = ["asos", "hm", "zara"]  # Which retailers to scrape
mode                : str       = "full"                  # full or new_arrivals
limit_per_retailer  : int       = 30                       # 1-500 products per retailer
```

**Request:**
```bash
curl -X POST "http://localhost:8001/fashion-scraper/scrape-all" \
  -G -d "retailers=asos" -d "retailers=zara" \
  -d "mode=full" -d "limit_per_retailer=25"
```

**Response (200 OK):**
```json
{
  "retailers": ["asos", "zara"],
  "mode": "full",
  "total_products": 50,
  "results": {
    "asos": [
      {
        "product_url": "https://www.asos.com/...",
        "source_site": "asos.com",
        "scrape_timestamp": "2024-04-19T01:39:00",
        "scrape_mode": "full",
        ...
      },
      ...
    ],
    "zara": [
      ...
    ]
  },
  "message": "Successfully scraped 50 products from 2 retailers"
}
```

---

### Check Scraper Status

**Endpoint:** `GET /fashion-scraper/status`

**Request:**
```bash
curl -X GET "http://localhost:8001/fashion-scraper/status"
```

**Response (200 OK):**
```json
{
  "status": "ready",
  "message": "Fashion scraper service is ready",
  "retailers": ["asos", "hm", "zara"],
  "modes": ["full", "new_arrivals"]
}
```

---

## Scrape Modes

### `full` Mode
- **Purpose**: Complete inventory scrape
- **Coverage**: All products across multiple category pages
- **Speed**: Slower (multiple HTTP requests)
- **Update Frequency**: Daily (recommended)
- **Use Case**: Comprehensive trend analysis, bulk product import

### `new_arrivals` Mode
- **Purpose**: Only new/recently added items
- **Coverage**: New/trending sections
- **Speed**: Faster (fewer pages to crawl)
- **Update Frequency**: Hourly (recommended)
- **Use Case**: Quick trend detection, real-time recommendations

---

## Response Schema

### `ScrapedProduct` Model

| Field | Type | Description |
|-------|------|-------------|
| `product_url` | `str` | Direct link to product on retailer website |
| `source_site` | `str` | Retailer domain (asos.com, hm.com, zara.com) |
| `scrape_timestamp` | `str` | ISO 8601 timestamp when product was scraped |
| `scrape_mode` | `str` | Mode used for scraping (full or new_arrivals) |
| `product_name` | `str` | Product title/name |
| `price` | `float` | Current price in retailer currency |
| `brand` | `str` | Brand/designer name |
| `category` | `str` | Product category (e.g., "Blazers", "Dresses") |
| `image_urls` | `List[str]` | URLs to product images |
| `customer_rating` | `float` | Average customer rating (if available) |

---

## Error Handling

| Status | Error | Solution |
|--------|-------|----------|
| 400 | Unknown retailer | Use: asos, hm, or zara |
| 400 | Unknown mode | Use: full or new_arrivals |
| 400 | Invalid limit range | Use 1-500 |
| 503 | Resource manager unavailable | Restart backend service |
| 500 | Scraping failed | Check network connectivity, retry |

---

## Usage Examples

### Python with `requests`
```python
import requests

# Single retailer
response = requests.post(
    "http://localhost:8001/fashion-scraper/scrape",
    params={
        "retailer": "zara",
        "mode": "new_arrivals",
        "limit": 50
    }
)
data = response.json()
for product in data["products"]:
    print(f"{product['product_name']} - ${product['price']}")

# Multiple retailers
response = requests.post(
    "http://localhost:8001/fashion-scraper/scrape-all",
    params={
        "retailers": ["asos", "hm", "zara"],
        "mode": "full",
        "limit_per_retailer": 25
    }
)
data = response.json()
for retailer, products in data["results"].items():
    print(f"\n{retailer}: {len(products)} products")
```

### JavaScript/TypeScript with `fetch`
```typescript
// Single retailer
const response = await fetch(
  "/fashion-scraper/scrape?retailer=asos&mode=full&limit=30",
  { method: "POST" }
);
const data = await response.json();

// Multi-retailer
const params = new URLSearchParams([
  ["retailers", "asos"],
  ["retailers", "hm"],
  ["mode", "full"],
  ["limit_per_retailer", "25"]
]);
const response = await fetch(
  `/fashion-scraper/scrape-all?${params}`,
  { method: "POST" }
);
const data = await response.json();
```

### Scheduled Scraping (APScheduler)
```python
from apscheduler.schedulers.background import BackgroundScheduler
import requests

scheduler = BackgroundScheduler()

def hourly_new_arrivals():
    """Check new arrivals every hour"""
    response = requests.post(
        "http://localhost:8001/fashion-scraper/scrape-all",
        params={
            "retailers": ["asos", "hm", "zara"],
            "mode": "new_arrivals",
            "limit_per_retailer": 50
        }
    )
    print(f"Hourly check: {response.json()['total_products']} new products")

def daily_full_scrape():
    """Full inventory check daily"""
    response = requests.post(
        "http://localhost:8001/fashion-scraper/scrape-all",
        params={
            "retailers": ["asos", "hm", "zara"],
            "mode": "full",
            "limit_per_retailer": 100
        }
    )
    print(f"Daily check: {response.json()['total_products']} total products")

scheduler.add_job(hourly_new_arrivals, "cron", hour="*")
scheduler.add_job(daily_full_scrape, "cron", hour=0)
scheduler.start()
```

---

## Performance Characteristics

### Response Times (Approximate)

| Scenario | Time | Notes |
|----------|------|-------|
| Single retailer, 10 products, new_arrivals | 3-5s | Quick check |
| Single retailer, 50 products, full | 10-15s | Standard scrape |
| All 3 retailers, 30 each, full (concurrent) | 12-18s | Parallel requests |
| All 3 retailers, 100 each, full (concurrent) | 25-35s | Larger dataset |

### Throughput
- **Concurrent requests**: Uses `asyncio.gather()` for parallel scraping
- **Rate limiting**: Built-in delays to avoid retailer rate limiting
- **Max products per request**: 500 (configurable)

---

## Data Pipeline Integration

These endpoints are designed to feed data into a data pipeline for:
- Trend analysis
- Price tracking
- Inventory monitoring
- Recommendation engine
- Competitor intelligence

### BigQuery Integration (Future)
```
Raw scraped data → FashionProductItem → BigQuery partitioned/clustered table
```

---

## Debugging

### Check Service Status
```bash
curl -X GET "http://localhost:8001/fashion-scraper/status"
```

### View Logs
```bash
tail -f backend/app.log | grep "fashion_scraper"
```

### Test Single Retailer
```bash
# Test ASOS
curl -X POST "http://localhost:8001/fashion-scraper/scrape?retailer=asos&mode=new_arrivals&limit=5"

# Test H&M
curl -X POST "http://localhost:8001/fashion-scraper/scrape?retailer=hm&mode=new_arrivals&limit=5"

# Test Zara
curl -X POST "http://localhost:8001/fashion-scraper/scrape?retailer=zara&mode=new_arrivals&limit=5"
```

---

## Integration with Existing Backend

### Product Search Fallback Chain
```
GET /products/search?q=blazer
  1. OpenRouter AI Shopping Search (primary)
  2. Google Retail API (if configured)
  3. Supabase Catalog (if configured)
  4. Fashion Scraper Service (real-time retailer scraping)
  5. Serper.dev search fallback (if configured)
  6. Custom Zara/H&M scrapers (direct scraping)
  ↓
  Google/Bing image fallbacks (if all else fails)
```

### Real-Time Product Data
The fashion scraper service is now integrated as a primary fallback in the product search endpoint, providing:
- **Authentic retailer data** from ASOS, H&M, and Zara
- **Real product images** directly from retailer websites
- **Direct purchase links** to actual product pages
- **Current pricing** and availability
- **No static data** - always fresh, real-time results

### Placeholder Images
All products in local catalog use `via.placeholder.com` URLs:
```
https://via.placeholder.com/400x500?text=Product+Name
```

---

## Known Limitations

1. **JavaScript-heavy sites**: Regex parsing works for static HTML only
   - Zara preview: Uses basic HTML parsing (may miss some products)
   - H&M/ASOS: Full product data extraction
   
2. **Rate limiting**: Retailer sites may rate limit concurrent requests
   - Mitigation: Built-in delays between requests
   
3. **Structure changes**: If retailer HTML structure changes, scrapers need updates
   - Monitored and maintained in `fashion_scraper_service.py`

---

## Future Enhancements

- [ ] Selenium support for JavaScript-heavy sites (optional, separate service)
- [ ] BigQuery persistent storage and querying
- [ ] Background task scheduler for automated scraping
- [ ] Price history tracking and alerts
- [ ] Image download and CDN storage
- [ ] Machine learning trend prediction
- [ ] Web scraper admin dashboard
- [ ] Retailer-specific authentication handling

---

## Support

For issues, refer to:
- **Service code**: [backend/app/services/fashion_scraper_service.py](backend/app/services/fashion_scraper_service.py)
- **Router code**: [backend/app/api/fashion_scraper.py](backend/app/api/fashion_scraper.py)
- **Main integration**: [backend/app/main.py](backend/app/main.py)
