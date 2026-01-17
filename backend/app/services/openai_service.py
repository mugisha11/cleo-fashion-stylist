"""
OpenAI Service
Handles communication with OpenAI API
"""
import os
import json
import httpx
from typing import List, Dict, Optional, Any
import logging

logger = logging.getLogger(__name__)


class OpenAIService:
    """Service for interacting with OpenAI API"""
    
    def __init__(self, api_key: Optional[str] = None, model: Optional[str] = None):
        self.api_key = api_key or os.getenv("OPENAI_API_KEY", "")
        self.model = model or os.getenv("OPENAI_MODEL", "gpt-5-mini-2025-08-07")
        self.base_url = "https://api.openai.com/v1"
        
        if not self.api_key:
            logger.warning("OpenAI API key not configured")
    
    async def create_chat_completion(
        self,
        messages: List[Dict[str, str]],
        temperature: float = 0.7,
        max_tokens: int = 1000,
    ) -> Dict[str, Any]:
        """
        Create a chat completion using OpenAI API
        
        Args:
            messages: List of message dicts with 'role' and 'content'
            temperature: Sampling temperature (0-2)
            max_tokens: Maximum tokens to generate
            
        Returns:
            API response as dict
        """
        if not self.api_key:
            raise ValueError("OpenAI API key not configured")
        
        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                response = await client.post(
                    f"{self.base_url}/chat/completions",
                    headers={
                        "Content-Type": "application/json",
                        "Authorization": f"Bearer {self.api_key}",
                    },
                    json={
                        "model": self.model,
                        "messages": messages,
                        "temperature": temperature,
                        "max_tokens": max_tokens,
                    },
                )
                
                response.raise_for_status()
                return response.json()
        except httpx.HTTPStatusError as e:
            logger.error(f"OpenAI API error: {e.response.text}")
            raise Exception(f"OpenAI API error: {e.response.text}")
        except Exception as e:
            logger.error(f"Failed to call OpenAI API: {e}")
            raise
    
    async def generate_text(
        self,
        prompt: str,
        temperature: float = 0.7,
        max_tokens: int = 1000,
    ) -> str:
        """
        Generate text completion
        
        Args:
            prompt: Text prompt
            temperature: Sampling temperature
            max_tokens: Maximum tokens
            
        Returns:
            Generated text
        """
        messages = [{"role": "user", "content": prompt}]
        response = await self.create_chat_completion(
            messages=messages,
            temperature=temperature,
            max_tokens=max_tokens,
        )
        
        return response.get("choices", [{}])[0].get("message", {}).get("content", "")
    
    async def generate_fashion_advice(
        self,
        context: str,
        question: str,
    ) -> str:
        """
        Generate fashion advice using AI
        
        Args:
            context: User context (wardrobe, style preferences, etc.)
            question: User's fashion question
            
        Returns:
            AI-generated fashion advice
        """
        prompt = f"""You are a luxury fashion stylist and AI assistant. 
Provide elegant, feminine, and modern fashion advice.

Context: {context}

Question: {question}

Provide a helpful, inspiring response in a warm, professional tone."""
        
        return await self.generate_text(
            prompt=prompt,
            temperature=0.8,
            max_tokens=500,
        )
    
    async def analyze_outfit(
        self,
        clothing_items: List[str],
        occasion: str,
    ) -> Dict[str, Any]:
        """
        Analyze outfit compatibility
        
        Args:
            clothing_items: List of clothing items
            occasion: Occasion type (casual, formal, etc.)
            
        Returns:
            Analysis with score, assessment, suggestions
        """
        prompt = f"""Analyze this outfit for a {occasion} occasion:
{', '.join(clothing_items)}

Provide:
1. Compatibility score (0-100)
2. Style assessment
3. Suggestions for improvement
4. Color harmony analysis

Respond in JSON format with keys: score, assessment, suggestions, colorHarmony."""
        
        response = await self.generate_text(
            prompt=prompt,
            temperature=0.6,
            max_tokens=800,
        )
        
        try:
            return json.loads(response)
        except json.JSONDecodeError:
            # Fallback if not valid JSON
            return {
                "score": 75,
                "assessment": response,
                "suggestions": [],
                "colorHarmony": "Good",
            }


# Global service instance
_openai_service: Optional[OpenAIService] = None


def get_openai_service() -> OpenAIService:
    """Get or create OpenAI service instance"""
    global _openai_service
    if _openai_service is None:
        _openai_service = OpenAIService()
    return _openai_service
