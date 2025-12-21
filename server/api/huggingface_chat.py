"""
Hugging Face Inference API Integration
Free tier available - Open source models
Get API key: https://huggingface.co/settings/tokens
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Dict, Optional, Any
import os
import httpx

router = APIRouter(prefix="/chat", tags=["chat"])

# Hugging Face API
HF_API_KEY = os.getenv("HUGGINGFACE_API_KEY", "")  # Get from https://huggingface.co/settings/tokens
HF_MODEL = os.getenv("HF_MODEL", "mistralai/Mistral-7B-Instruct-v0.2")  # Free model
HF_API_URL = f"https://api-inference.huggingface.co/models/{HF_MODEL}"

class ChatRequest(BaseModel):
    conversation_id: str
    user_id: str
    message: str
    history: List[Dict[str, str]]

class ChatResponse(BaseModel):
    content: str
    metadata: Dict[str, Any]

@router.post("/completion", response_model=ChatResponse)
async def chat_completion(request: ChatRequest):
    """
    Generate AI response using Hugging Face Inference API
    """
    if not HF_API_KEY:
        raise HTTPException(
            status_code=500,
            detail="Hugging Face API key not set. Get one at https://huggingface.co/settings/tokens"
        )
    
    try:
        # Build prompt
        system_prompt = """You are Cleo, a professional AI fashion stylist assistant."""
        
        conversation_text = system_prompt + "\n\n"
        for msg in request.history:
            role = msg.get("role", "user")
            content = msg.get("content", "")
            if role == "user":
                conversation_text += f"User: {content}\n"
            elif role == "assistant":
                conversation_text += f"Assistant: {content}\n"
        
        conversation_text += f"User: {request.message}\nAssistant:"

        # Call Hugging Face API
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                HF_API_URL,
                headers={
                    "Authorization": f"Bearer {HF_API_KEY}",
                    "Content-Type": "application/json",
                },
                json={
                    "inputs": conversation_text,
                    "parameters": {
                        "max_new_tokens": 500,
                        "temperature": 0.7,
                        "return_full_text": False,
                    }
                }
            )
            
            if response.status_code == 503:
                # Model is loading
                raise HTTPException(
                    status_code=503,
                    detail="Model is loading. Please wait a moment and try again."
                )
            
            if response.status_code != 200:
                raise HTTPException(
                    status_code=response.status_code,
                    detail=f"Hugging Face API error: {response.text}"
                )
            
            result = response.json()
            
            # Extract text from response (format varies by model)
            if isinstance(result, list) and len(result) > 0:
                ai_content = result[0].get("generated_text", "")
            elif isinstance(result, dict):
                ai_content = result.get("generated_text", "")
            else:
                ai_content = str(result)
            
            if not ai_content:
                raise HTTPException(
                    status_code=500,
                    detail="No response from Hugging Face API"
                )

            return ChatResponse(
                content=ai_content.strip(),
                metadata={
                    "model": HF_MODEL,
                    "provider": "huggingface",
                },
            )
            
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Hugging Face error: {str(e)}"
        )


