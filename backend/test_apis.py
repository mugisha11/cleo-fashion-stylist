"""
Test script to verify all APIs are responding correctly
"""
import asyncio
import httpx
import json
import os
from app.core.config import settings

async def test_gemini_api():
    """Test Gemini API connectivity"""
    print("\n" + "="*60)
    print("Testing Gemini API (Nano Banana)")
    print("="*60)
    
    api_key = settings.GEMINI_API_KEY
    if not api_key:
        print("[ERROR] GEMINI_API_KEY not set")
        return False
    
    print(f"[OK] API Key found: {api_key[:20]}...")
    
    # Test with a simple text-to-image request
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent?key={api_key}",
                headers={"Content-Type": "application/json"},
                json={
                    "contents": [{
                        "parts": [{"text": "A simple test image"}]
                    }]
                }
            )
            
            if response.status_code == 200:
                result = response.json()
                if "candidates" in result:
                    print("[OK] Gemini API is responding correctly!")
                    return True
                else:
                    print(f"[WARN] Unexpected response structure: {list(result.keys())}")
                    return False
            else:
                error_text = response.text
                print(f"[ERROR] Gemini API error (status {response.status_code}): {error_text[:200]}")
                return False
                
    except Exception as e:
        print(f"[ERROR] Gemini API connection failed: {str(e)}")
        return False


async def test_openrouter_api():
    """Test OpenRouter API connectivity"""
    print("\n" + "="*60)
    print("Testing OpenRouter API")
    print("="*60)
    
    api_key = settings.OPENROUTER_API_KEY
    if not api_key:
        print("[ERROR] OPENROUTER_API_KEY not set")
        return False
    
    print(f"[OK] API Key found: {api_key[:20]}...")
    
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                "https://openrouter.ai/api/v1/chat/completions",
                headers={
                    "Authorization": f"Bearer {api_key}",
                    "Content-Type": "application/json"
                },
                json={
                    "model": "openai/gpt-4o-mini",
                    "messages": [{"role": "user", "content": "Say 'test'"}]
                }
            )
            
            if response.status_code == 200:
                result = response.json()
                if "choices" in result:
                    print("[OK] OpenRouter API is responding correctly!")
                    return True
                else:
                    print(f"[WARN] Unexpected response structure: {list(result.keys())}")
                    return False
            else:
                error_text = response.text
                print(f"[ERROR] OpenRouter API error (status {response.status_code}): {error_text[:200]}")
                return False
                
    except Exception as e:
        print(f"[ERROR] OpenRouter API connection failed: {str(e)}")
        return False


async def test_backend_health():
    """Test backend health endpoint"""
    print("\n" + "="*60)
    print("Testing Backend Health")
    print("="*60)
    
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get("http://localhost:8000/health")
            
            if response.status_code == 200:
                result = response.json()
                print("[OK] Backend is running!")
                print(f"   Status: {result.get('status', 'unknown')}")
                print(f"   Version: {result.get('version', 'unknown')}")
                return True
            else:
                print(f"[ERROR] Backend health check failed (status {response.status_code})")
                return False
                
    except httpx.ConnectError:
        print("[ERROR] Backend is not running on http://localhost:8000")
        print("   Please start the server first!")
        return False
    except Exception as e:
        print(f"[ERROR] Backend health check failed: {str(e)}")
        return False


async def test_tryon_endpoint():
    """Test try-on endpoint availability"""
    print("\n" + "="*60)
    print("Testing Try-On Endpoint")
    print("="*60)
    
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            # Test health endpoint first
            response = await client.get("http://localhost:8000/try-on/health")
            
            if response.status_code == 200:
                result = response.json()
                print("[OK] Try-on endpoint is available!")
                print(f"   Status: {result.get('status', 'unknown')}")
                return True
            else:
                print(f"[WARN] Try-on health endpoint returned status {response.status_code}")
                return False
                
    except httpx.ConnectError:
        print("[ERROR] Backend is not running")
        return False
    except Exception as e:
        print(f"[WARN] Try-on endpoint check: {str(e)}")
        # Endpoint might not have health check, that's okay
        return True


async def test_gemini_sdk():
    """Test if Gemini SDK is available"""
    print("\n" + "="*60)
    print("Testing Gemini SDK Availability")
    print("="*60)
    
    try:
        from google import genai
        print("[OK] Gemini SDK (google-genai) is installed")
        
        # Try to initialize client
        try:
            client = genai.Client(api_key=settings.GEMINI_API_KEY)
            print("[OK] Gemini SDK client initialized successfully")
            return True
        except Exception as e:
            print(f"[WARN] SDK client initialization failed: {str(e)}")
            print("   Will use REST API instead (this is fine)")
            return True  # REST API is still available
            
    except ImportError:
        print("[WARN] Gemini SDK (google-genai) is not installed")
        print("   Will use REST API instead (this is fine)")
        return True  # REST API is still available


async def main():
    """Run all tests"""
    print("\n" + "="*60)
    print("VIRTUAL TRY-ON API VERIFICATION")
    print("="*60)
    
    results = {}
    
    # Test backend
    results['backend'] = await test_backend_health()
    
    # Test Gemini SDK
    results['gemini_sdk'] = await test_gemini_sdk()
    
    # Test Gemini API
    results['gemini_api'] = await test_gemini_api()
    
    # Test OpenRouter API
    results['openrouter'] = await test_openrouter_api()
    
    # Test try-on endpoint
    results['tryon_endpoint'] = await test_tryon_endpoint()
    
    # Summary
    print("\n" + "="*60)
    print("TEST SUMMARY")
    print("="*60)
    
    all_critical = True
    for test_name, result in results.items():
        status = "[PASS]" if result else "[FAIL]"
        print(f"{test_name.upper():20} {status}")
        if test_name in ['backend', 'gemini_api'] and not result:
            all_critical = False
    
    print("\n" + "="*60)
    if all_critical:
        print("[SUCCESS] ALL CRITICAL APIS ARE WORKING!")
        print("   Virtual try-on should work correctly.")
    else:
        print("[WARNING] SOME CRITICAL APIS ARE NOT WORKING")
        print("   Please check the errors above.")
    print("="*60 + "\n")


if __name__ == "__main__":
    asyncio.run(main())
