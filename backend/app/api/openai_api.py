"""
OpenAI API Endpoints
Provides fashion AI capabilities using OpenAI
"""
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from ..services.openai_service import get_openai_service

router = APIRouter(prefix="/openai", tags=["openai"])


class ChatRequest(BaseModel):
    messages: List[dict]
    temperature: Optional[float] = 0.7
    max_tokens: Optional[int] = 1000


class FashionAdviceRequest(BaseModel):
    context: str
    question: str


class OutfitAnalysisRequest(BaseModel):
    clothing_items: List[str]
    occasion: str


@router.post("/chat")
async def chat_completion(request: ChatRequest):
    """Create a chat completion"""
    try:
        service = get_openai_service()
        response = await service.create_chat_completion(
            messages=request.messages,
            temperature=request.temperature,
            max_tokens=request.max_tokens,
        )
        return response
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/fashion-advice")
async def fashion_advice(request: FashionAdviceRequest):
    """Get fashion advice from AI"""
    try:
        service = get_openai_service()
        advice = await service.generate_fashion_advice(
            context=request.context,
            question=request.question,
        )
        return {"advice": advice}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/analyze-outfit")
async def analyze_outfit(request: OutfitAnalysisRequest):
    """Analyze outfit compatibility"""
    try:
        service = get_openai_service()
        analysis = await service.analyze_outfit(
            clothing_items=request.clothing_items,
            occasion=request.occasion,
        )
        return analysis
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
