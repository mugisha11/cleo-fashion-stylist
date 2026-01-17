"""
Test image generation directly to verify it's working
"""
import asyncio
import httpx  # type: ignore
import base64
import json
from app.core.config import settings
from app.stages.generation import Stage5ImageGeneration
import numpy as np  # type: ignore
import cv2  # type: ignore
from PIL import Image  # type: ignore
import io

async def test_gemini_image_generation():
    """Test Gemini image generation with a simple prompt"""
    print("\n" + "="*60)
    print("TESTING GEMINI IMAGE GENERATION")
    print("="*60)
    
    # Check API key
    api_key = settings.GEMINI_API_KEY
    if not api_key:
        print("[ERROR] GEMINI_API_KEY not set")
        return False
    
    print(f"[OK] API Key found: {api_key[:20]}...")
    
    # Create a simple test image (white image with text)
    test_image = np.ones((512, 512, 3), dtype=np.uint8) * 255
    cv2.putText(test_image, "TEST", (150, 250), cv2.FONT_HERSHEY_SIMPLEX, 2, (0, 0, 0), 5)
    
    # Initialize generation service
    try:
        stage5 = Stage5ImageGeneration(use_pro_model=False)
        print(f"[OK] Stage5ImageGeneration initialized with model: {stage5.model}")
    except Exception as e:
        print(f"[ERROR] Failed to initialize Stage5ImageGeneration: {e}")
        return False
    
    # Test 1: Simple text-to-image (no input images)
    print("\n[TEST 1] Testing text-to-image generation...")
    try:
        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(
                f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent?key={api_key}",
                headers={"Content-Type": "application/json"},
                json={
                    "contents": [{
                        "parts": [{"text": "A simple red circle on white background"}]
                    }]
                }
            )
            
            if response.status_code == 200:
                result = response.json()
                if "candidates" in result and len(result["candidates"]) > 0:
                    candidate = result["candidates"][0]
                    if "content" in candidate and "parts" in candidate["content"]:
                        for part in candidate["content"]["parts"]:
                            # Check both snake_case and camelCase formats
                            inline_data = part.get("inline_data") or part.get("inlineData")
                            if inline_data:
                                image_b64 = inline_data.get("data", "")
                                if image_b64:
                                    print("[SUCCESS] Image generated successfully!")
                                    print(f"   Image data length: {len(image_b64)} characters")
                                    
                                    # Try to decode and verify it's a valid image
                                    try:
                                        image_bytes = base64.b64decode(image_b64)
                                        img = Image.open(io.BytesIO(image_bytes))
                                        width, height = img.size
                                        print(f"   Image size: {width}x{height}")
                                        print(f"   Image format: {img.format}")
                                        print(f"   Image mode: {img.mode}")
                                        print("[SUCCESS] Image generation is working!")
                                        return True
                                    except Exception as e:
                                        print(f"[WARN] Generated data is not a valid image: {e}")
                                        return False
                        
                        print("[WARN] Response contains candidates but no image data")
                        # Check for text response
                        for part in candidate["content"]["parts"]:
                            if "text" in part:
                                print(f"   Text response: {part['text'][:200]}")
                            # Debug: print all part keys
                            print(f"   Part keys: {list(part.keys())}")
                        # Print full response structure for debugging
                        print(f"   Full candidate structure: {json.dumps(candidate, indent=2, default=str)[:500]}")
                        return False
                else:
                    print(f"[ERROR] No candidates in response: {list(result.keys())}")
                    return False
            else:
                error_text = response.text
                print(f"[ERROR] API returned status {response.status_code}")
                print(f"   Error: {error_text[:300]}")
                return False
                
    except httpx.ConnectError as e:
        print(f"[ERROR] Connection failed: {e}")
        print("   This indicates a network connectivity issue")
        return False
    except Exception as e:
        print(f"[ERROR] Image generation test failed: {e}")
        return False


async def test_gemini_sdk_generation():
    """Test Gemini SDK image generation"""
    print("\n[TEST 2] Testing Gemini SDK image generation...")
    
    try:
        from google import genai
        
        client = genai.Client(api_key=settings.GEMINI_API_KEY)
        
        # Simple text-to-image
        response = client.models.generate_content(
            model="gemini-2.5-flash-image",
            contents=["A blue square on white background"]
        )
        
        # Extract image
        for part in response.parts:
            if part.inline_data is not None:
                try:
                    image = part.as_image()
                    print("[SUCCESS] SDK generated image successfully!")
                    # PIL Image has .size as (width, height) tuple
                    if hasattr(image, 'size'):
                        width, height = image.size
                        print(f"   Image size: {width}x{height}")
                    else:
                        print(f"   Image type: {type(image)}")
                    if hasattr(image, 'mode'):
                        print(f"   Image mode: {image.mode}")
                    return True
                except Exception as e:
                    print(f"[WARN] SDK image extraction failed: {e}")
                    # Try alternative extraction
                    try:
                        image_data = part.inline_data.data
                        img = Image.open(io.BytesIO(image_data))
                        width, height = img.size
                        print(f"[SUCCESS] Alternative extraction worked! Size: {width}x{height}")
                        return True
                    except Exception as e2:
                        print(f"[ERROR] Alternative extraction also failed: {e2}")
                        return False
        
        print("[WARN] SDK response contains no image data")
        return False
        
    except ImportError:
        print("[SKIP] Gemini SDK not available, skipping SDK test")
        return True  # Not a failure, just not available
    except Exception as e:
        print(f"[ERROR] SDK test failed: {e}")
        return False


async def test_all_apis():
    """Test all APIs"""
    print("\n" + "="*60)
    print("COMPREHENSIVE API TEST")
    print("="*60)
    
    results = {}
    
    # Test Gemini API
    results['gemini_api'] = await test_gemini_image_generation()
    
    # Test Gemini SDK
    results['gemini_sdk'] = await test_gemini_sdk_generation()
    
    # Summary
    print("\n" + "="*60)
    print("TEST SUMMARY")
    print("="*60)
    
    for test_name, result in results.items():
        status = "[PASS]" if result else "[FAIL]"
        print(f"{test_name.upper():20} {status}")
    
    all_passed = all(results.values())
    
    print("\n" + "="*60)
    if all_passed:
        print("[SUCCESS] ALL IMAGE GENERATION TESTS PASSED!")
        print("   Gemini API is working correctly!")
    else:
        print("[WARNING] SOME TESTS FAILED")
        print("   Check errors above for details")
    print("="*60 + "\n")
    
    return all_passed


if __name__ == "__main__":
    asyncio.run(test_all_apis())
