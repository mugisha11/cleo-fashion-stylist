"""Test the /tryon endpoint directly to see actual error"""
import requests
import json

url = "http://localhost:8000/tryon"
payload = {
    "user_image_url": "https://via.placeholder.com/512",
    "garment_image_urls": ["https://via.placeholder.com/512"]
}

print("Testing /tryon endpoint...")
print(f"URL: {url}")
print(f"Payload: {json.dumps(payload, indent=2)}")
print("-" * 50)

try:
    response = requests.post(url, json=payload, timeout=60)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
except requests.exceptions.RequestException as e:
    print(f"Request Exception: {e}")
except Exception as e:
    print(f"Error: {e}")
    import traceback
    traceback.print_exc()
