"""
OpenRouter Service
Handles AI reasoning and garment classification using OpenRouter API
"""
import logging
import base64
import httpx
from typing import Dict, List, Optional, Any
from PIL import Image
import io

from ..core.config import settings

logger = logging.getLogger(__name__)


class OpenRouterService:
    """
    OpenRouter API service for multimodal reasoning and garment classification
    """
    
    def __init__(self):
        self.api_key = settings.OPENROUTER_API_KEY
        self.base_url = settings.OPENROUTER_BASE_URL
        self.model = settings.OPENROUTER_MODEL_VISION  # Use vision model for garment classification
        
        if not self.api_key:
            logger.warning("OpenRouter API key not set. Set OPENROUTER_API_KEY environment variable.")
    
    async def _download_image(self, url: str) -> bytes:
        """Download image from URL"""
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.get(url)
            response.raise_for_status()
            return response.content
    
    def _image_to_base64(self, image_bytes: bytes) -> str:
        """Convert image bytes to base64 data URL"""
        # Validate it's an image
        try:
            img = Image.open(io.BytesIO(image_bytes))
            # Convert to RGB if needed
            if img.mode != 'RGB':
                img = img.convert('RGB')
            
            # Resize if too large (OpenRouter has limits)
            max_size = 2048
            if max(img.size) > max_size:
                img.thumbnail((max_size, max_size), Image.Resampling.LANCZOS)
            
            buffer = io.BytesIO()
            img.save(buffer, format='JPEG', quality=85)
            image_bytes = buffer.getvalue()
        except Exception as e:
            logger.warning(f"Image processing warning: {e}")
        
        base64_str = base64.b64encode(image_bytes).decode('utf-8')
        return f"data:image/jpeg;base64,{base64_str}"
    
    async def classify_garment(
        self,
        garment_image_url: Optional[str] = None,
        garment_image_base64: Optional[str] = None,
        user_image_url: Optional[str] = None,
        user_image_base64: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Classify garment using OpenRouter multimodal model
        
        Returns:
            {
                "garment_type": str,
                "target_body_part": List[str],
                "confidence": float,
                "style": Optional[str],
                "region": Optional[str]
            }
        """
        if not self.api_key:
            raise ValueError("OpenRouter API key not configured")
        
        # Prepare images
        images = []
        
        if garment_image_url:
            garment_bytes = await self._download_image(garment_image_url)
            images.append({
                "type": "image_url",
                "image_url": {"url": self._image_to_base64(garment_bytes)}
            })
        elif garment_image_base64:
            # Handle base64 input
            if garment_image_base64.startswith("data:"):
                images.append({
                    "type": "image_url",
                    "image_url": {"url": garment_image_base64}
                })
            else:
                images.append({
                    "type": "image_url",
                    "image_url": {"url": f"data:image/jpeg;base64,{garment_image_base64}"}
                })
        
        if user_image_url:
            user_bytes = await self._download_image(user_image_url)
            images.append({
                "type": "image_url",
                "image_url": {"url": self._image_to_base64(user_bytes)}
            })
        elif user_image_base64:
            if user_image_base64.startswith("data:"):
                images.append({
                    "type": "image_url",
                    "image_url": {"url": user_image_base64}
                })
            else:
                images.append({
                    "type": "image_url",
                    "image_url": {"url": f"data:image/jpeg;base64,{user_image_base64}"}
                })
        
        if not images:
            raise ValueError("At least one image (garment or user) must be provided")
        
        # Construct prompt for structured output
        prompt = """Analyze the garment image(s) and user photo (if provided) for virtual try-on.

You must return a JSON object with the following structure:
{
  "garment_type": "shirt|pants|dress|shoes|jacket|hat|accessory|other",
  "target_body_part": ["torso", "legs", "feet", "head", "arms", "hands", "full_body"],
  "confidence": 0.0-1.0,
  "style": "casual|formal|sporty|elegant|streetwear|other",
  "region": "upper_body|lower_body|full_body|accessory"
}

Rules:
1. garment_type must be one of: shirt, pants, dress, shoes, jacket, hat, accessory, other
2. target_body_part is an array of body parts where this garment should be applied
3. confidence must be >= 0.90 for the try-on to proceed
4. Analyze the garment carefully to determine its type and target body parts
5. If user image is provided, consider body positioning and existing clothing

Return ONLY valid JSON, no additional text."""
        
        messages = [
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": prompt},
                    *images
                ]
            }
        ]
        
        # Call OpenRouter API
        try:
            async with httpx.AsyncClient(timeout=60.0) as client:
                response = await client.post(
                    f"{self.base_url}/chat/completions",
                    headers={
                        "Authorization": f"Bearer {self.api_key}",
                        "Content-Type": "application/json",
                        "HTTP-Referer": "https://cleo-fashion.com",  # Optional
                        "X-Title": "Cleo Fashion Virtual Try-On"  # Optional
                    },
                    json={
                        "model": self.model,
                        "messages": messages,
                        "temperature": 0.1,  # Low temperature for consistent classification
                        "max_tokens": 600,  # Reduced to stay well below credit limit (869 tokens available)
                        "response_format": {"type": "json_object"}  # Force JSON output
                    }
                )
                response.raise_for_status()
                result = response.json()
                
                # Extract JSON from response
                content = result["choices"][0]["message"]["content"]
                
                # Parse JSON (handle if wrapped in markdown code blocks)
                import json
                if "```json" in content:
                    content = content.split("```json")[1].split("```")[0].strip()
                elif "```" in content:
                    content = content.split("```")[1].split("```")[0].strip()
                
                classification = json.loads(content)
                
                # Validate confidence
                confidence = classification.get("confidence", 0.0)
                if confidence < settings.MIN_GARMENT_CONFIDENCE:
                    logger.warning(f"Garment classification confidence {confidence} below threshold {settings.MIN_GARMENT_CONFIDENCE}")
                
                # Validate required fields
                if "garment_type" not in classification:
                    raise ValueError("garment_type missing from classification")
                if "target_body_part" not in classification:
                    raise ValueError("target_body_part missing from classification")
                if not isinstance(classification["target_body_part"], list):
                    classification["target_body_part"] = [classification["target_body_part"]]
                
                logger.info(f"Garment classified: {classification['garment_type']} -> {classification['target_body_part']} (confidence: {confidence})")
                
                return classification
                
        except httpx.HTTPStatusError as e:
            logger.error(f"OpenRouter API error: {e.response.status_code} - {e.response.text}")
            raise Exception(f"OpenRouter API error: {e.response.status_code}")
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse OpenRouter response: {content[:200]}")
            raise Exception(f"Invalid JSON response from OpenRouter: {e}")
        except Exception as e:
            logger.error(f"OpenRouter classification error: {e}", exc_info=True)
            raise
    
    async def generate_body_parsing_instructions(
        self,
        user_image_url: Optional[str] = None,
        user_image_base64: Optional[str] = None,
        garment_classification: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """
        Generate body parsing instructions using OpenRouter
        
        Returns instructions for computer vision model to parse body segments
        """
        if not self.api_key:
            raise ValueError("OpenRouter API key not configured")
        
        # Prepare user image
        images = []
        if user_image_url:
            user_bytes = await self._download_image(user_image_url)
            images.append({
                "type": "image_url",
                "image_url": {"url": self._image_to_base64(user_bytes)}
            })
        elif user_image_base64:
            if user_image_base64.startswith("data:"):
                images.append({
                    "type": "image_url",
                    "image_url": {"url": user_image_base64}
                })
            else:
                images.append({
                    "type": "image_url",
                    "image_url": {"url": f"data:image/jpeg;base64,{user_image_base64}"}
                })
        
        garment_info = ""
        if garment_classification:
            garment_info = f"""
Garment to apply:
- Type: {garment_classification.get('garment_type', 'unknown')}
- Target body parts: {', '.join(garment_classification.get('target_body_part', []))}
- Style: {garment_classification.get('style', 'unknown')}
"""
        
        prompt = f"""Analyze this user photo and provide body parsing instructions for virtual try-on.

{garment_info}

Return a JSON object with parsing instructions:
{{
  "required_segments": ["face", "torso", "legs", "arms", "hands", "feet", "background"],
  "priority_segments": ["face", "torso"],  // Must preserve these
  "target_segments": ["torso"],  // Where garment will be applied
  "preserve_regions": ["face", "hair", "skin"],  // Must not modify
  "parsing_hints": {{
    "pose_estimation": true,
    "segmentation": true,
    "depth_estimation": false
  }}
}}

Rules:
1. required_segments: All body parts that need to be identified
2. priority_segments: Critical segments that must be accurately parsed
3. target_segments: Body parts where the garment will be applied (based on garment classification)
4. preserve_regions: Regions that must remain unchanged
5. parsing_hints: Technical hints for CV model

Return ONLY valid JSON, no additional text."""
        
        messages = [
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": prompt},
                    *images
                ]
            }
        ]
        
        try:
            async with httpx.AsyncClient(timeout=60.0) as client:
                response = await client.post(
                    f"{self.base_url}/chat/completions",
                    headers={
                        "Authorization": f"Bearer {self.api_key}",
                        "Content-Type": "application/json",
                        "HTTP-Referer": "https://cleo-fashion.com",
                        "X-Title": "Cleo Fashion Virtual Try-On"
                    },
                    json={
                        "model": self.model,
                        "messages": messages,
                        "temperature": 0.1,
                        "max_tokens": 600,  # Reduced to stay well below credit limit (869 tokens available)
                        "response_format": {"type": "json_object"}
                    }
                )
                response.raise_for_status()
                result = response.json()
                
                content = result["choices"][0]["message"]["content"]
                
                import json
                if "```json" in content:
                    content = content.split("```json")[1].split("```")[0].strip()
                elif "```" in content:
                    content = content.split("```")[1].split("```")[0].strip()
                
                instructions = json.loads(content)
                logger.info(f"Body parsing instructions generated: {instructions.get('target_segments', [])}")
                
                return instructions
                
        except Exception as e:
            logger.error(f"Failed to generate body parsing instructions: {e}", exc_info=True)
            # Return default instructions as fallback
            return {
                "required_segments": ["face", "torso", "legs", "arms"],
                "priority_segments": ["face"],
                "target_segments": garment_classification.get("target_body_part", ["torso"]) if garment_classification else ["torso"],
                "preserve_regions": ["face", "hair"],
                "parsing_hints": {
                    "pose_estimation": True,
                    "segmentation": True,
                    "depth_estimation": False
                }
            }
