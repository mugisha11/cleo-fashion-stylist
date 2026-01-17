"""Test network connectivity to Gemini API"""
import socket
import httpx
import asyncio

async def test_network():
    """Test if we can reach Gemini API"""
    print("Testing network connectivity to Gemini API...")
    print("=" * 50)
    
    # Test DNS resolution
    try:
        hostname = "generativelanguage.googleapis.com"
        ip = socket.gethostbyname(hostname)
        print(f"✅ DNS Resolution: {hostname} -> {ip}")
    except Exception as e:
        print(f"❌ DNS Resolution Failed: {e}")
        print("   This means your server cannot resolve domain names.")
        print("   Check:")
        print("   1. Internet connection")
        print("   2. DNS server settings")
        print("   3. Firewall blocking DNS queries")
        return
    
    # Test HTTP connection
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get("https://generativelanguage.googleapis.com")
            print(f"✅ HTTP Connection: Status {response.status_code}")
    except httpx.ConnectError as e:
        print(f"❌ HTTP Connection Failed: {e}")
        print("   Cannot establish connection to Gemini API")
        print("   Check:")
        print("   1. Internet connection")
        print("   2. Firewall allowing outbound HTTPS (port 443)")
        print("   3. Proxy settings (if behind corporate firewall)")
    except Exception as e:
        print(f"❌ HTTP Error: {e}")

if __name__ == "__main__":
    asyncio.run(test_network())
