"""
Minimal FastAPI app for Railway - production try-on only (Gemini + OpenRouter).
No torch, opencv, dlib - avoids heavy apt deps and build failures.
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .core.config import settings
from .api.production_vton_v2 import router as production_vton_router

app = FastAPI(
    title=settings.API_TITLE,
    version=settings.API_VERSION,
    description="Production Virtual Try-On API (Gemini + OpenRouter)",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(production_vton_router)


@app.get("/")
@app.get("/health")
async def health():
    return {"status": "healthy", "version": settings.API_VERSION, "gpu_available": False}


@app.get("/alive")
async def alive():
    return {"alive": True, "version": settings.API_VERSION}
