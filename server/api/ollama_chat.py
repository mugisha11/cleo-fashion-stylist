"""
Ollama Chat API Integration
Free, open-source, local LLM - No API keys needed!
Install: https://ollama.ai/download
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Dict, Optional, Any
import os
import httpx
from datetime import datetime

router = APIRouter(prefix="/chat", tags=["chat"])

# Ollama API endpoint (default: localhost:11434)
OLLAMA_BASE_URL = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "llama3.2")  # or "mistral", "phi3", etc.

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
    Generate AI response using Ollama (free, local LLM)
    """
    try:
        # Build conversation context
        system_prompt = """You are Cleo, a professional AI fashion stylist assistant for the Cleo Fashion App. You help users with:
- Fashion advice and styling recommendations
- Outfit coordination and color matching
- Understanding their personal style preferences
- Answering questions about fashion trends, occasions, and wardrobe management
- Providing personalized fashion guidance based on their quiz results

Be friendly, knowledgeable, and concise. Always provide actionable fashion advice."""

        # Build messages for Ollama
        messages = [
            {"role": "system", "content": system_prompt}
        ]
        
        # Add conversation history
        for msg in request.history:
            role = msg.get("role", "user")
            content = msg.get("content", "")
            if role in ["user", "assistant"]:
                messages.append({"role": role, "content": content})
        
        # Add current message
        messages.append({"role": "user", "content": request.message})

        # Call Ollama API
        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(
                f"{OLLAMA_BASE_URL}/api/chat",
                json={
                    "model": OLLAMA_MODEL,
                    "messages": messages,
                    "stream": False,
                    "options": {
                        "temperature": 0.7,
                        "num_predict": 500,  # Max tokens
                    }
                }
            )
            
            if response.status_code != 200:
                raise HTTPException(
                    status_code=response.status_code,
                    detail=f"Ollama API error: {response.text}"
                )
            
            result = response.json()
            ai_content = result.get("message", {}).get("content", "")
            
            if not ai_content:
                raise HTTPException(
                    status_code=500,
                    detail="No response from Ollama"
                )

            return ChatResponse(
                content=ai_content,
                metadata={
                    "model": OLLAMA_MODEL,
                    "provider": "ollama",
                    "done": result.get("done", False),
                },
            )
            
    except httpx.TimeoutException:
        raise HTTPException(
            status_code=504,
            detail="Ollama request timeout. Make sure Ollama is running."
        )
    except httpx.ConnectError:
        raise HTTPException(
            status_code=503,
            detail="Cannot connect to Ollama. Please install and start Ollama: https://ollama.ai/download"
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Ollama error: {str(e)}"
        )


