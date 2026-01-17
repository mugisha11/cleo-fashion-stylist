"""
Quick test to verify try-on endpoint is accessible
"""
import requests
import json
import time

# Wait a moment for server to start
print("Waiting for server to start...")
time.sleep(3)

BASE_URL = "http://localhost:8000"

def test_health():
    """Test health endpoint"""
    print("\n" + "="*60)
    print("TESTING HEALTH ENDPOINT")
    print("="*60)
    try:
        response = requests.get(f"{BASE_URL}/try-on/health", timeout=5)
        print(f"Status: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
        return response.status_code == 200
    except requests.exceptions.ConnectionError:
        print("❌ Cannot connect to server. Is it running?")
        return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def test_main_endpoint():
    """Test main try-on endpoint"""
    print("\n" + "="*60)
    print("TESTING MAIN ENDPOINT")
    print("="*60)
    try:
        payload = {
            "user_image_url": "https://example.com/user.jpg",
            "cloth_image_url": "https://example.com/garment.jpg"
        }
        response = requests.post(
            f"{BASE_URL}/try-on",
            json=payload,
            timeout=10
        )
        print(f"Status: {response.status_code}")
        
        if response.status_code == 404:
            print("❌ Endpoint not found (404)")
            return False
        else:
            print("✅ Endpoint exists and responded!")
            try:
                data = response.json()
                print(f"Response keys: {list(data.keys())}")
                if "error" in data:
                    print(f"Error (expected): {data.get('error', '')[:100]}")
            except:
                print(f"Response text: {response.text[:200]}")
            return True
    except requests.exceptions.ConnectionError:
        print("❌ Cannot connect to server. Is it running?")
        return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    print("="*60)
    print("QUICK ENDPOINT TEST")
    print("="*60)
    
    health_ok = test_health()
    endpoint_ok = test_main_endpoint()
    
    print("\n" + "="*60)
    if health_ok and endpoint_ok:
        print("✅ ALL TESTS PASSED - ENDPOINT IS WORKING!")
    elif health_ok:
        print("⚠️  Health endpoint works, but main endpoint has issues")
    else:
        print("❌ Server may not be running or endpoint not accessible")
    print("="*60)
