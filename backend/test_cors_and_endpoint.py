"""
Test CORS and endpoint accessibility from Flutter web perspective
"""
import requests
import json

BASE_URL = "http://localhost:8000"

def test_cors():
    """Test CORS headers"""
    print("=" * 60)
    print("TESTING CORS")
    print("=" * 60)
    
    # Test OPTIONS (preflight)
    try:
        response = requests.options(
            f"{BASE_URL}/tryon",
            headers={
                'Origin': 'http://localhost:61715',
                'Access-Control-Request-Method': 'POST',
                'Access-Control-Request-Headers': 'Content-Type'
            }
        )
        print(f"OPTIONS Status: {response.status_code}")
        print(f"CORS Headers:")
        for key, value in response.headers.items():
            if 'access-control' in key.lower():
                print(f"  {key}: {value}")
    except Exception as e:
        print(f"OPTIONS failed: {e}")

def test_endpoint():
    """Test actual endpoint"""
    print("\n" + "=" * 60)
    print("TESTING /tryon ENDPOINT")
    print("=" * 60)
    
    payload = {
        "user_image_url": "https://example.com/user.jpg",
        "garment_image_urls": ["https://example.com/garment.jpg"]
    }
    
    try:
        response = requests.post(
            f"{BASE_URL}/tryon",
            json=payload,
            headers={
                'Content-Type': 'application/json',
                'Origin': 'http://localhost:61715'
            },
            timeout=10
        )
        
        print(f"Status: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)[:500]}")
        
        # Check CORS headers in response
        print(f"\nCORS Headers in response:")
        for key, value in response.headers.items():
            if 'access-control' in key.lower():
                print(f"  {key}: {value}")
                
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_cors()
    test_endpoint()
