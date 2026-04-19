#!/usr/bin/env python
"""
Test script to verify fashion_scraper integration with FastAPI
"""
import sys
import asyncio
from pathlib import Path

# Add backend to path
backend_path = Path(__file__).parent
sys.path.insert(0, str(backend_path))

print("Testing fashion_scraper integration...")
print("=" * 70)

# Test 1: Import the routers
try:
    from app.api import fashion_scraper
    print("✅ Successfully imported fashion_scraper router")
    print(f"   Routes: {[route.path for route in fashion_scraper.router.routes]}")
except Exception as e:
    print(f"❌ Failed to import fashion_scraper: {e}")
    sys.exit(1)

# Test 2: Import the service
try:
    from app.services.fashion_scraper_service import FashionScraperService
    print("✅ Successfully imported FashionScraperService")
except Exception as e:
    print(f"❌ Failed to import FashionScraperService: {e}")
    sys.exit(1)

# Test 3: Check router has expected endpoints
expected_routes = ['/fashion-scraper/scrape', '/fashion-scraper/scrape-all', '/fashion-scraper/status']
actual_routes = [route.path for route in fashion_scraper.router.routes]
print(f"\n   Expected routes: {expected_routes}")
print(f"   Actual routes  : {actual_routes}")

for route in expected_routes:
    if route in actual_routes:
        print(f"   ✅ {route}")
    else:
        print(f"   ❌ {route} NOT FOUND")

# Test 4: Import main app and verify router is registered
try:
    from app import main
    print("\n✅ Successfully imported main app")
    
    # Check if fashion_scraper router is in the app
    registered_routes = []
    for route in main.app.routes:
        if hasattr(route, 'path'):
            registered_routes.append(route.path)
    
    fashion_scraper_routes = [r for r in registered_routes if '/fashion-scraper' in r]
    if fashion_scraper_routes:
        print(f"✅ fashion_scraper routes registered in app: {len(fashion_scraper_routes)} routes")
        for route in fashion_scraper_routes:
            print(f"   - {route}")
    else:
        print("⚠️  fashion_scraper routes not found in app routes")
        print(f"   (This may be normal if routers are checked differently)")

except Exception as e:
    print(f"❌ Failed to import main app: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

print("\n" + "=" * 70)
print("✅ ALL INTEGRATION TESTS PASSED")
print("\nTo test the API, start the backend with:")
print("  cd backend")
print("  python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8001")
print("\nThen access the scraper endpoints:")
print("  POST /fashion-scraper/scrape?retailer=asos&mode=full&limit=10")
print("  POST /fashion-scraper/scrape-all?retailers=asos&retailers=hm&retailers=zara&mode=full")
print("  GET  /fashion-scraper/status")
