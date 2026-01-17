"""
Direct test of /tryon endpoint to find the actual problem
"""
import sys
import requests
import json

def test_endpoint():
    print("=" * 60)
    print("TESTING /tryon ENDPOINT DIRECTLY")
    print("=" * 60)
    
    base_url = "http://localhost:8000"
    
    # Test 1: Check if server is running
    print("\n[TEST 1] Checking if server is running...")
    try:
        response = requests.get(f"{base_url}/health", timeout=2)
        print(f"✅ Server is running (status: {response.status_code})")
    except requests.exceptions.ConnectionError:
        print("❌ SERVER IS NOT RUNNING!")
        print("   Start the server with: python -m uvicorn app.main:app --reload")
        return False
    except Exception as e:
        print(f"❌ Error connecting to server: {e}")
        return False
    
    # Test 2: Check if /tryon endpoint exists
    print("\n[TEST 2] Checking if /tryon endpoint exists...")
    try:
        # Try to get OpenAPI docs to see available endpoints
        response = requests.get(f"{base_url}/openapi.json", timeout=2)
        if response.status_code == 200:
            openapi = response.json()
            paths = openapi.get("paths", {})
            
            if "/tryon" in paths:
                print("✅ /tryon endpoint found in OpenAPI spec")
                print(f"   Methods: {list(paths['/tryon'].keys())}")
            else:
                print("❌ /tryon endpoint NOT FOUND in OpenAPI spec")
                print(f"   Available paths: {list(paths.keys())[:10]}")
                return False
        else:
            print(f"⚠️  Could not get OpenAPI spec (status: {response.status_code})")
    except Exception as e:
        print(f"⚠️  Error checking OpenAPI: {e}")
    
    # Test 3: Try actual POST request
    print("\n[TEST 3] Testing POST /tryon with sample data...")
    try:
        payload = {
            "user_image_url": "https://example.com/user.jpg",
            "garment_image_urls": ["https://example.com/garment.jpg"]
        }
        
        response = requests.post(
            f"{base_url}/tryon",
            json=payload,
            timeout=10,
            headers={"Content-Type": "application/json"}
        )
        
        print(f"Status Code: {response.status_code}")
        
        if response.status_code == 404:
            print("❌ ENDPOINT NOT FOUND (404)")
            print(f"   Response: {response.text[:200]}")
            return False
        elif response.status_code == 200:
            print("✅ Endpoint exists and responded!")
            try:
                data = response.json()
                print(f"   Response: {json.dumps(data, indent=2)[:300]}")
            except:
                print(f"   Response text: {response.text[:200]}")
            return True
        else:
            print(f"⚠️  Endpoint exists but returned {response.status_code}")
            print(f"   Response: {response.text[:300]}")
            return True  # Endpoint exists, just has an error (expected with fake URLs)
            
    except requests.exceptions.ConnectionError:
        print("❌ Cannot connect to server")
        return False
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
        return False
    
    print("\n" + "=" * 60)
    print("✅ ALL TESTS COMPLETE")
    print("=" * 60)
    return True

if __name__ == "__main__":
    success = test_endpoint()
    sys.exit(0 if success else 1)
