#!/usr/bin/env python3
"""Test ASOS RapidAPI integration for product image fetching"""

import asyncio
import sys
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

sys.path.insert(0, '.')

async def test_asos_search():
    """Test the ASOS search functionality"""
    import httpx
    from app.api.product_search import _fallback_asos_search
    from app.core.config import settings
    
    print(f"ASOS API Key configured: {bool(settings.ASOS_RAPIDAPI_KEY)}")
    print(f"ASOS API Host: {settings.ASOS_RAPIDAPI_HOST}")
    
    if not settings.ASOS_RAPIDAPI_KEY:
        print("ERROR: ASOS_RAPIDAPI_KEY not configured")
        return
    
    async with httpx.AsyncClient(timeout=30.0) as client:
        # Test various search queries
        queries = [
            "minimalist accessories for work and travel",
            "white blazer women",
            "casual dresses",
            "formal shirts"
        ]
        
        for query in queries:
            print(f"\n{'='*60}")
            print(f"Testing ASOS search for: '{query}'")
            print('='*60)
            
            try:
                products = await _fallback_asos_search(client, query, limit=5)
                
                if products:
                    print(f"\n✅ Found {len(products)} products:")
                    for i, product in enumerate(products, 1):
                        print(f"\n  {i}. {product.title}")
                        print(f"     Brand: {product.brand or 'N/A'}")
                        print(f"     Price: {product.price or 'N/A'}")
                        print(f"     Image: {product.image_url[:100]}...")
                        print(f"     Link: {product.link[:100]}...")
                        print(f"     Source: {product.source}")
                else:
                    print("⚠️  No products found")
            except Exception as e:
                print(f"❌ Error: {e}")
                import traceback
                traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(test_asos_search())
