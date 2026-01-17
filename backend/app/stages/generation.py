"""
Stage 5: Image Generation
Uses Gemini API for image generation
"""
import logging
import numpy as np
import cv2
from typing import Optional
import httpx
import base64
from io import BytesIO

from ..core.config import settings
from ..core.exceptions import APIError, ErrorCode

logger = logging.getLogger(__name__)


class Stage5ImageGeneration:
    """
    Stage 5: Image generation using Gemini API.
    Generates try-on result using user image, garment, and prompt.
    """
    
    def __init__(self, use_pro_model: bool = False):
        """
        Initialize image generation stage.
        
        Args:
            use_pro_model: Whether to use Pro model (higher quality)
        """
        self.use_pro_model = use_pro_model
        self.model_name = self._get_model_name()
        self.api_key = settings.GEMINI_API_KEY
        self.base_url = "https://generativelanguage.googleapis.com/v1beta"
    
    def _get_model_name(self) -> str:
        """Get model name based on configuration"""
        if self.use_pro_model:
            return settings.GEMINI_MODEL or "gemini-3-pro-image-preview"
        else:
            return settings.GEMINI_MODEL or "gemini-2.5-flash-image"
    
    async def execute(
        self,
        user_image: np.ndarray,
        garment_image: np.ndarray,
        prompt: str,
        garment_type: str = "garment",
        aspect_ratio: Optional[str] = None
    ) -> np.ndarray:
        """
        Execute image generation.
        
        Args:
            user_image: User photo (BGR format)
            garment_image: Garment image (BGR format)
            prompt: Generation prompt
            garment_type: Type of garment
            aspect_ratio: Optional aspect ratio
        
        Returns:
            Generated image (BGR format)
        
        Raises:
            Exception: If generation fails
        """
        if not self.api_key:
            raise APIError(
                code=ErrorCode.CONFIG_MISSING_API_KEY,
                message="GEMINI_API_KEY not configured",
                details="Set GEMINI_API_KEY environment variable"
            )
        
        try:
            # Convert images to base64
            user_b64 = self._image_to_base64(user_image)
            garment_b64 = self._image_to_base64(garment_image)
            
            # Prepare request
            url = f"{self.base_url}/models/{self.model_name}:generateContent"
            
            payload = {
                "contents": [{
                    "parts": [
                        {"text": prompt},
                        {
                            "inline_data": {
                                "mime_type": "image/jpeg",
                                "data": user_b64
                            }
                        },
                        {
                            "inline_data": {
                                "mime_type": "image/jpeg",
                                "data": garment_b64
                            }
                        }
                    ]
                }],
                "generationConfig": {
                    "temperature": 0.4,
                    "topK": 32,
                    "topP": 1.0,
                    "maxOutputTokens": 1024
                }
            }
            
            # Make request
            async with httpx.AsyncClient(timeout=120.0) as client:
                logger.info(f"Calling Gemini API: {url}")
                logger.info(f"Model: {self.model_name}")
                response = await client.post(
                    url,
                    headers={
                        "Content-Type": "application/json",
                        "x-goog-api-key": self.api_key
                    },
                    json=payload
                )
                
                # Log response status for debugging
                logger.info(f"Gemini API response status: {response.status_code}")
                
                if response.status_code != 200:
                    error_text = response.text[:500]
                    logger.error(f"Gemini API error ({response.status_code}): {error_text}")
                    
                    # Map HTTP status codes to typed exceptions
                    if response.status_code == 404:
                        raise APIError(
                            code=ErrorCode.API_MODEL_NOT_FOUND,
                            message="Gemini model or endpoint not found",
                            details=f"HTTP 404: {error_text[:200]}"
                        )
                    elif response.status_code == 429:
                        raise APIError(
                            code=ErrorCode.API_RATE_LIMIT,
                            message="API rate limit exceeded",
                            details="Please wait a moment and try again"
                        )
                    elif response.status_code == 401:
                        raise APIError(
                            code=ErrorCode.API_UNAUTHORIZED,
                            message="Gemini API authentication failed",
                            details="Check GEMINI_API_KEY configuration"
                        )
                    elif response.status_code >= 500:
                        raise APIError(
                            code=ErrorCode.API_SERVER_ERROR,
                            message="Gemini API server error",
                            details=f"HTTP {response.status_code}: {error_text[:200]}"
                        )
                    else:
                        try:
                            error_json = response.json()
                            error_detail = error_json.get("error", {}).get("message", error_text)
                        except:
                            error_detail = error_text
                        
                        raise APIError(
                            code=ErrorCode.API_SERVER_ERROR,
                            message=f"Gemini API error: HTTP {response.status_code}",
                            details=error_detail[:200]
                        )
                
                response.raise_for_status()
                result = response.json()
            
            # Extract image from response
            generated_image = self._extract_image_from_response(result)
            
            if generated_image is None:
                from ..core.exceptions import GenerationError
                raise GenerationError(
                    code=ErrorCode.GENERATION_NO_IMAGE,
                    message="No image generated in response",
                    details="Gemini API did not return an image in the expected format"
                )
            
            return generated_image
            
        except (APIError, GenerationError):
            # Re-raise typed exceptions as-is
            raise
        except httpx.TimeoutException:
            raise APIError(
                code=ErrorCode.API_TIMEOUT,
                message="Request to Gemini API timed out",
                details="The API did not respond within 120 seconds"
            )
        except httpx.RequestError as e:
            raise APIError(
                code=ErrorCode.API_NETWORK_ERROR,
                message="Network error connecting to Gemini API",
                details=str(e)
            )
        except Exception as e:
            # Catch-all for unexpected errors
            logger.error(f"Unexpected error in image generation: {e}", exc_info=True)
            from ..core.exceptions import GenerationError
            raise GenerationError(
                code=ErrorCode.GENERATION_FAILED,
                message="Unexpected error during image generation",
                details=str(e)[:300]
            )
    
    def _image_to_base64(self, image: np.ndarray) -> str:
        """Convert numpy image to base64 string"""
        # Convert BGR to RGB if needed
        if len(image.shape) == 3 and image.shape[2] == 3:
            image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        else:
            image_rgb = image
        
        # Encode to JPEG
        _, buffer = cv2.imencode('.jpg', image)
        image_bytes = buffer.tobytes()
        
        # Convert to base64
        return base64.b64encode(image_bytes).decode('utf-8')
    
    def _extract_image_from_response(self, response: dict) -> Optional[np.ndarray]:
        """Extract image from Gemini API response"""
        try:
            candidates = response.get("candidates", [])
            if not candidates:
                return None
            
            content = candidates[0].get("content", {})
            parts = content.get("parts", [])
            
            for part in parts:
                # Check for inline data (base64 image) - try both camelCase and snake_case
                inline_data = part.get("inlineData") or part.get("inline_data")
                if inline_data:
                    data = inline_data.get("data") if isinstance(inline_data, dict) else inline_data
                    if data:
                        # Decode base64
                        image_bytes = base64.b64decode(data)
                        # Convert to numpy array
                        nparr = np.frombuffer(image_bytes, np.uint8)
                        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
                        if image is not None:
                            return image
                
                # Check for image URL (if provided)
                image_url = part.get("imageUrl") or part.get("image_url")
                if image_url:
                    url = image_url.get("url") if isinstance(image_url, dict) else image_url
                    if url and url.startswith("data:image"):
                        # Extract base64 from data URL
                        header, encoded = url.split(",", 1)
                        image_bytes = base64.b64decode(encoded)
                        nparr = np.frombuffer(image_bytes, np.uint8)
                        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
                        if image is not None:
                            return image
                
                # Check for text response (might contain image reference)
                if "text" in part:
                    text = part["text"]
                    # Sometimes Gemini returns image as base64 in text
                    if "data:image" in text:
                        import re
                        match = re.search(r'data:image/[^;]+;base64,([A-Za-z0-9+/=]+)', text)
                        if match:
                            image_bytes = base64.b64decode(match.group(1))
                            nparr = np.frombuffer(image_bytes, np.uint8)
                            image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
                            if image is not None:
                                return image
            
            return None
            
        except Exception as e:
            logger.error(f"Failed to extract image from response: {e}")
            return None
