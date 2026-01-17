"""
Chat Completion API Endpoint
Uses Google Gemini API for AI reasoning with conversation context
"""

from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import List, Dict, Optional, Any
import os
import time
import asyncio
from google import genai
from google.genai import types
from datetime import datetime

router = APIRouter(prefix="/chat", tags=["chat"])

# Initialize Gemini client
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "AIzaSyDNR_ypy6HMhdc_Jn-EX-H4xEz4O24mnZs")
client = genai.Client(api_key=GEMINI_API_KEY)

class ChatMessage(BaseModel):
    role: str  # 'user', 'assistant', or 'system'
    content: str

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
    Generate AI response using Google Gemini with conversation context
    """
    try:
        # Build conversation context for Gemini
        # Gemini uses a different format - we'll build a single prompt with history
        system_prompt = """You are Cleo, a professional AI fashion stylist assistant for the Cleo Fashion App. You help users with:
- Fashion advice and styling recommendations
- Outfit coordination and color matching
- Understanding their personal style preferences
- Answering questions about fashion trends, occasions, and wardrobe management
- Providing personalized fashion guidance based on their quiz results

Be friendly, knowledgeable, and concise. Always provide actionable fashion advice. If you don't know something, admit it rather than guessing.

Conversation History:"""

        # Build conversation history
        conversation_text = system_prompt + "\n\n"
        for msg in request.history:
            role = msg.get("role", "user")
            content = msg.get("content", "")
            if role == "user":
                conversation_text += f"User: {content}\n\n"
            elif role == "assistant":
                conversation_text += f"Cleo: {content}\n\n"
        
        # Add current user message
        conversation_text += f"User: {request.message}\n\nCleo:"

        # Call Gemini API with retry logic for quota errors
        max_retries = 3
        retry_delay = 1
        
        for attempt in range(max_retries):
            try:
                response = client.models.generate_content(
                    model="gemini-2.0-flash-exp",
                    contents=[conversation_text],
                )

                # Extract text response
                ai_content = ""
                for part in response.parts:
                    if part.text is not None:
                        ai_content += part.text

                if not ai_content:
                    raise HTTPException(status_code=500, detail="No response from Gemini API")

                return ChatResponse(
                    content=ai_content,
                    metadata={
                        "model": "gemini-2.0-flash-exp",
                        "tokens_used": getattr(response, 'usage_metadata', {}).get('total_token_count', 0) if hasattr(response, 'usage_metadata') else 0,
                    },
                )
            except Exception as api_error:
                error_str = str(api_error)
                
                # Check if it's a quota error (429)
                if "429" in error_str or "RESOURCE_EXHAUSTED" in error_str or "quota" in error_str.lower():
                    if attempt < max_retries - 1:
                        # Extract retry delay from error if available
                        if "retry in" in error_str.lower() or "retryDelay" in error_str:
                            # Try to extract delay (default to exponential backoff)
                            retry_delay = min(retry_delay * 2, 60)  # Max 60 seconds
                        else:
                            retry_delay = min(retry_delay * 2, 60)
                        
                        await asyncio.sleep(retry_delay)
                        continue
                    else:
                        # Last attempt failed - return user-friendly error
                        raise HTTPException(
                            status_code=429,
                            detail="Gemini API quota exceeded. Please wait a few minutes and try again, or check your API key quota at https://ai.dev/usage?tab=rate-limit"
                        )
                else:
                    # Non-quota error - raise immediately
                    raise HTTPException(status_code=500, detail=f"Gemini API error: {error_str}")
        
        # Should not reach here, but just in case
        raise HTTPException(status_code=500, detail="Failed to get response from Gemini API after retries")
    except HTTPException:
        # Re-raise HTTP exceptions as-is
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Unexpected error: {str(e)}")

