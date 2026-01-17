"""
Test script to verify try-on endpoint is available and receiving requests
"""
import sys
import asyncio
from app.main import app
from fastapi.testclient import TestClient

def test_endpoint_availability():
    """Test if endpoints are registered and accessible"""
    print("=" * 60)
    print("TESTING ENDPOINT AVAILABILITY")
    print("=" * 60)
    
    # Create test client
    client = TestClient(app)
    
    # Get all routes
    routes = []
    for route in app.routes:
        if hasattr(route, 'path') and hasattr(route, 'methods'):
            routes.append({
                'path': route.path,
                'methods': list(route.methods)
            })
    
    print(f"\n✅ Found {len(routes)} total routes\n")
    
    # Filter try-on routes
    tryon_routes = [r for r in routes if '/try-on' in r['path']]
    
    print("TRY-ON ENDPOINTS:")
    print("-" * 60)
    for route in tryon_routes:
        methods = ', '.join([m for m in route['methods'] if m != 'HEAD'])
        print(f"  {route['path']} [{methods}]")
    
    if not tryon_routes:
        print("  ❌ NO /try-on ROUTES FOUND!")
        return False
    
    print("\n" + "=" * 60)
    print("TESTING HEALTH ENDPOINT")
    print("=" * 60)
    
    # Test health endpoint
    try:
        response = client.get("/try-on/health")
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.json()}")
        
        if response.status_code == 200:
            print("✅ Health endpoint is working!")
        else:
            print(f"❌ Health endpoint returned {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Health endpoint test failed: {e}")
        return False
    
    print("\n" + "=" * 60)
    print("TESTING MAIN ENDPOINT (POST /try-on)")
    print("=" * 60)
    
    # Test main endpoint with minimal request
    test_request = {
        "user_image_url": "https://example.com/user.jpg",
        "cloth_image_url": "https://example.com/garment.jpg"
    }
    
    try:
        response = client.post("/try-on", json=test_request)
        print(f"Status Code: {response.status_code}")
        
        # Even if it fails, if we get a response (not 404), the endpoint exists
        if response.status_code == 404:
            print("❌ Endpoint not found (404)")
            return False
        else:
            print(f"✅ Endpoint exists and responded with {response.status_code}")
            print("   (This is expected - request will fail due to invalid URLs)")
            if response.status_code != 200:
                try:
                    error_data = response.json()
                    print(f"   Error: {error_data.get('error', 'Unknown error')}")
                except:
                    print(f"   Response: {response.text[:200]}")
    except Exception as e:
        print(f"❌ Endpoint test failed: {e}")
        import traceback
        traceback.print_exc()
        return False
    
    print("\n" + "=" * 60)
    print("✅ ALL TESTS PASSED - ENDPOINT IS AVAILABLE!")
    print("=" * 60)
    return True

if __name__ == "__main__":
    success = test_endpoint_availability()
    sys.exit(0 if success else 1)
