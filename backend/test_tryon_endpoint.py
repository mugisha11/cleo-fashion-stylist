"""
Test script for the simple try-on endpoint
"""
import asyncio
import httpx
import json

async def test_tryon_endpoint():
    """Test the /tryon endpoint"""
    base_url = "http://localhost:8000"
    
    # Test data - use placeholder images
    test_data = {
        "user_image_url": "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400",
        "garment_image_urls": ["https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400"]
    }
    
    print("=" * 60)
    print("TESTING /tryon ENDPOINT")
    print("=" * 60)
    print(f"\n1. Testing endpoint availability...")
    
    # First check if server is running
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            health_response = await client.get(f"{base_url}/health")
            print(f"   ✅ Server is running (status: {health_response.status_code})")
    except Exception as e:
        print(f"   ❌ Server not reachable: {e}")
        print(f"   Make sure to start the server with: uvicorn app.main:app --reload")
        return
    
    print(f"\n2. Testing /tryon endpoint...")
    print(f"   Request: POST {base_url}/tryon")
    print(f"   Payload: {json.dumps(test_data, indent=2)}")
    
    try:
        async with httpx.AsyncClient(timeout=120.0) as client:
            response = await client.post(
                f"{base_url}/tryon",
                headers={"Content-Type": "application/json"},
                json=test_data
            )
            
            print(f"\n   Response Status: {response.status_code}")
            print(f"   Response Headers: {dict(response.headers)}")
            
            if response.status_code == 200:
                result = response.json()
                print(f"\n   ✅ SUCCESS!")
                print(f"   Status: {result.get('status')}")
                if result.get('result_image_url'):
                    url = result['result_image_url']
                    if url.startswith('data:image'):
                        print(f"   Result: Base64 image (length: {len(url)} chars)")
                    else:
                        print(f"   Result URL: {url[:100]}...")
                else:
                    print(f"   ⚠️  No result_image_url in response")
                    print(f"   Full response: {json.dumps(result, indent=2)}")
            else:
                print(f"\n   ❌ FAILED")
                print(f"   Response body: {response.text[:500]}")
                
    except httpx.TimeoutException:
        print(f"\n   ❌ Request timed out after 120 seconds")
    except Exception as e:
        print(f"\n   ❌ Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(test_tryon_endpoint())
