"""
Enhanced OpenRouter Service
Handles multimodal AI tasks including Gemini image generation via OpenRouter
"""
import logging
import base64
import httpx
import json
from typing import Dict, List, Optional, Any
from PIL import Image
import io
import numpy as np
import cv2

from ..core.config import settings
from ..core.utils import image_to_base64, base64_to_image

logger = logging.getLogger(__name__)


class EnhancedOpenRouterService:
    """
    Enhanced OpenRouter service for:
    - Vision reasoning (garment analysis)
    - Structured JSON outputs
    - Gemini image generation via OpenRouter
    - Fallback handling
    """
    
    def __init__(self):
        self.api_key = settings.OPENROUTER_API_KEY
        self.base_url = settings.OPENROUTER_BASE_URL
        self.vision_model = settings.OPENROUTER_MODEL_VISION
        self.gemini_model = settings.OPENROUTER_MODEL_GEMINI_IMAGE
        
        if not self.api_key:
            logger.warning("OpenRouter API key not set")
    
    def _image_to_base64(self, image_bytes: bytes) -> str:
        """Convert image bytes to base64 data URL"""
        try:
            img = Image.open(io.BytesIO(image_bytes))
            if img.mode != 'RGB':
                img = img.convert('RGB')
            
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
    
    async def analyze_garment_with_reasoning(
        self,
        user_image: np.ndarray,
        garment_image: np.ndarray,
        trace_id: str
    ) -> Dict[str, Any]:
        """
        Analyze garment with structured JSON output including:
        - Garment type
        - Placement regions
        - Confidence scores
        - Pose keypoints
        - Reasoning
        
        Returns structured JSON as specified in requirements
        """
        if not self.api_key:
            raise ValueError("OpenRouter API key not configured")
        
        # Convert images to base64
        user_b64 = image_to_base64(user_image)
        garment_b64 = image_to_base64(garment_image)
        
        prompt = """Analyze the garment image and user photo for virtual try-on.

You must return ONLY a valid JSON object with this exact structure:
{
  "garment_type": "T-shirt|shirt|pants|dress|shoes|jacket|hat|accessory|other",
  "placement": "upper_body|lower_body|full_body|feet|head|accessory",
  "allowed_regions": ["torso", "arms", "legs", "feet", "head"],
  "forbidden_regions": ["face", "hair", "hands"],
  "pose_keypoints": {
    "shoulders": [[x, y], [x, y]],
    "hips": [[x, y], [x, y]],
    "knees": [[x, y], [x, y]],
    "ankles": [[x, y], [x, y]]
  },
  "confidence": 0.95,
  "reasoning": "Brief explanation of placement decision",
  "orientation": "front|back|side",
  "body_shape_preservation": true
}

CRITICAL RULES:
1. garment_type must be specific (e.g., "T-shirt", "Jeans", "Sneakers")
2. placement must match garment type (shirt→upper_body, pants→lower_body, shoes→feet)
3. confidence must be >= 0.90
4. pose_keypoints should estimate key body points from user photo
5. reasoning must explain why this placement is correct
6. Return ONLY JSON, no markdown, no code blocks"""

        messages = [
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": prompt},
                    {
                        "type": "image_url",
                        "image_url": {"url": user_b64}
                    },
                    {
                        "type": "image_url",
                        "image_url": {"url": garment_b64}
                    }
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
                        "X-Title": "Cleo Fashion VTON"
                    },
                    json={
                        "model": self.vision_model,
                        "messages": messages,
                        "temperature": 0.1,
                        "max_tokens": 1000,
                        "response_format": {"type": "json_object"}
                    }
                )
                response.raise_for_status()
                result = response.json()
                
                content = result["choices"][0]["message"]["content"]
                
                # Parse JSON
                content = content.strip()
                if "```json" in content:
                    content = content.split("```json")[1].split("```")[0].strip()
                elif "```" in content:
                    content = content.split("```")[1].split("```")[0].strip()
                
                analysis = json.loads(content)
                
                # Validate
                if analysis.get("confidence", 0) < 0.90:
                    raise ValueError(f"Confidence {analysis.get('confidence')} below threshold 0.90")
                
                logger.info(f"[{trace_id}] Garment analyzed: {analysis.get('garment_type')} -> {analysis.get('placement')}")
                return analysis
                
        except Exception as e:
            logger.error(f"[{trace_id}] Garment analysis failed: {e}")
            raise
    
    async def generate_image_via_openrouter(
        self,
        user_image: np.ndarray,
        garment_image: np.ndarray,
        prompt: str,
        trace_id: str,
        fallback_models: Optional[List[str]] = None
    ) -> np.ndarray:
        """
        Generate try-on image using Gemini via OpenRouter
        
        Args:
            user_image: Original user photo
            garment_image: Garment image
            prompt: Generation prompt
            trace_id: Trace ID for logging
            fallback_models: List of fallback models if primary fails
            
        Returns:
            Generated image as numpy array
        """
        if not self.api_key:
            raise ValueError("OpenRouter API key not configured")
        
        # Convert images to base64
        user_b64 = image_to_base64(user_image)
        garment_b64 = image_to_base64(garment_image)
        
        # Prepare request with modalities
        messages = [
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": prompt},
                    {
                        "type": "image_url",
                        "image_url": {"url": user_b64}
                    },
                    {
                        "type": "image_url",
                        "image_url": {"url": garment_b64}
                    }
                ]
            }
        ]
        
        # Try primary model first
        models_to_try = [self.gemini_model]
        if fallback_models:
            models_to_try.extend(fallback_models)
        
        last_error = None
        for model in models_to_try:
            try:
                async with httpx.AsyncClient(timeout=120.0) as client:
                    response = await client.post(
                        f"{self.base_url}/chat/completions",
                        headers={
                            "Authorization": f"Bearer {self.api_key}",
                            "Content-Type": "application/json",
                            "HTTP-Referer": "https://cleo-fashion.com",
                            "X-Title": "Cleo Fashion VTON"
                        },
                        json={
                            "model": model,
                            "messages": messages,
                            "temperature": 0.1,
                            "max_tokens": 4096,
                            "modalities": ["image", "text"]  # Request both image and text output
                        }
                    )
                    response.raise_for_status()
                    result = response.json()
                    
                    # Extract image from response
                    content = result["choices"][0]["message"]["content"]
                    
                    # Check if response contains image
                    if isinstance(content, list):
                        for item in content:
                            if item.get("type") == "image_url":
                                image_url = item["image_url"]["url"]
                                # Download image
                                if image_url.startswith("data:"):
                                    image_b64 = image_url.split(",")[1]
                                    generated_image = base64_to_image(image_b64)
                                    logger.info(f"[{trace_id}] Image generated successfully with {model}")
                                    return generated_image
                    
                    # If no image in response, try to extract from text
                    # Some models return base64 in text
                    if isinstance(content, str) and "data:image" in content:
                        # Extract base64 from text
                        import re
                        match = re.search(r'data:image/[^;]+;base64,([A-Za-z0-9+/=]+)', content)
                        if match:
                            image_b64 = match.group(1)
                            generated_image = base64_to_image(image_b64)
                            logger.info(f"[{trace_id}] Image extracted from text response")
                            return generated_image
                    
                    raise ValueError(f"No image data in response from {model}")
                    
            except Exception as e:
                logger.warning(f"[{trace_id}] Model {model} failed: {e}")
                last_error = e
                continue
        
        # All models failed
        raise Exception(f"All image generation models failed. Last error: {last_error}")
    
    async def synthesize_prompt(
        self,
        user_image: np.ndarray,
        garment_image: np.ndarray,
        garment_analysis: Dict[str, Any],
        trace_id: str
    ) -> str:
        """
        Synthesize precise prompt for image generation
        
        Returns plain text prompt with explicit constraints
        """
        user_b64 = image_to_base64(user_image)
        garment_b64 = image_to_base64(garment_image)
        
        system_prompt = """You are a prompt engineer for image generation. Generate explicit, non-creative instructions.

CRITICAL RULES:
1. NO creativity or style invention
2. NO artistic interpretation
3. Explicitly list ALL constraints
4. Command identity preservation
5. Command pose preservation
6. Command lighting continuity
7. Explicitly forbid face, hair, hands modification

OUTPUT FORMAT:
Plain text instruction (no markdown, no code blocks)"""

        user_prompt = f"""Generate a prompt for applying a {garment_analysis.get('garment_type')} to a person in an image.

User image: [IMAGE]
Garment image: [IMAGE]

CONSTRAINTS:
- Allowed regions: {', '.join(garment_analysis.get('allowed_regions', []))}
- Forbidden regions: {', '.join(garment_analysis.get('forbidden_regions', []))}
- Placement: {garment_analysis.get('placement')}
- Orientation: {garment_analysis.get('orientation', 'front')}

Generate a plain text instruction that:
1. Explicitly lists allowed regions: {', '.join(garment_analysis.get('allowed_regions', []))}
2. Explicitly forbids modifying: {', '.join(garment_analysis.get('forbidden_regions', []))}
3. Commands preservation of face, hair, hands, pose, body shape, proportions
4. Commands lighting continuity
5. Commands applying the garment ONLY to allowed regions
6. No creativity, no style changes, no artistic interpretation

Return ONLY the plain text instruction, nothing else."""

        messages = [
            {"role": "system", "content": system_prompt},
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": user_prompt},
                    {"type": "image_url", "image_url": {"url": user_b64}},
                    {"type": "image_url", "image_url": {"url": garment_b64}}
                ]
            }
        ]
        
        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                response = await client.post(
                    f"{self.base_url}/chat/completions",
                    headers={
                        "Authorization": f"Bearer {self.api_key}",
                        "Content-Type": "application/json"
                    },
                    json={
                        "model": settings.OPENROUTER_MODEL_MINI,
                        "messages": messages,
                        "temperature": 0.1
                    }
                )
                response.raise_for_status()
                result = response.json()
                
                prompt = result["choices"][0]["message"]["content"].strip()
                
                # Remove markdown if present
                if prompt.startswith("```"):
                    lines = prompt.split("\n")
                    prompt = "\n".join(lines[1:-1]) if len(lines) > 2 else prompt
                    prompt = prompt.strip()
                
                logger.info(f"[{trace_id}] Prompt synthesized")
                return prompt
                
        except Exception as e:
            logger.error(f"[{trace_id}] Prompt synthesis failed: {e}")
            raise
