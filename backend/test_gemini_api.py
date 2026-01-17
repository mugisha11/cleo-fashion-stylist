"""Test Gemini API directly to see actual error"""
import asyncio
import httpx
import base64
import cv2
import numpy as np
from app.core.config import settings

async def test_gemini_api():
    """Test direct Gemini API call"""
    print(f"GEMINI_API_KEY: {'SET' if settings.GEMINI_API_KEY else 'NOT SET'}")
    print(f"GEMINI_MODEL: {settings.GEMINI_MODEL}")
    print(f"Base URL: https://generativelanguage.googleapis.com/v1beta")
    
    # Create a dummy image (1x1 pixel)
    dummy_image = np.zeros((100, 100, 3), dtype=np.uint8)
    _, buffer = cv2.imencode('.jpg', dummy_image)
    image_b64 = base64.b64encode(buffer.tobytes()).decode('utf-8')
    
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{settings.GEMINI_MODEL}:generateContent"
    
    payload = {
        "contents": [{
            "parts": [
                {"text": "Generate a test image"},
                {
                    "inline_data": {
                        "mime_type": "image/jpeg",
                        "data": image_b64
                    }
                }
            ]
        }]
    }
    
    print(f"\nTesting URL: {url}")
    print(f"Payload keys: {list(payload.keys())}")
    
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                url,
                headers={
                    "Content-Type": "application/json",
                    "x-goog-api-key": settings.GEMINI_API_KEY
                },
                json=payload
            )
            
            print(f"\nResponse Status: {response.status_code}")
            print(f"Response Headers: {dict(response.headers)}")
            print(f"Response Body: {response.text[:500]}")
            
            if response.status_code != 200:
                print(f"\n❌ ERROR: Status {response.status_code}")
                try:
                    error_json = response.json()
                    print(f"Error JSON: {error_json}")
                except:
                    pass
            else:
                print(f"\n✅ SUCCESS!")
                result = response.json()
                print(f"Response keys: {list(result.keys())}")
                
    except httpx.HTTPStatusError as e:
        print(f"\n❌ HTTP Error: {e}")
        print(f"Response: {e.response.text[:500]}")
    except Exception as e:
        print(f"\n❌ Exception: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(test_gemini_api())
