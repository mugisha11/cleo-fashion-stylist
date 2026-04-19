import asyncio
from app.api.product_search import _fallback_static_catalog

async def test():
    res = await _fallback_static_catalog('minimalist accessories for work and travel', 10)
    print('static count', len(res))
    for p in res:
        print(p.title, p.price, p.link)

asyncio.run(test())
