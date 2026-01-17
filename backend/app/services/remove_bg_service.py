"""
Remove.bg API Service
Uses Remove.bg API for background removal with fallback to local segmentation
"""
import logging
import httpx
import numpy as np
import cv2
from typing import Tuple
from PIL import Image
import io

from ..core.config import settings

logger = logging.getLogger(__name__)


class RemoveBGService:
    """Service for removing background from images using Remove.bg API"""
    
    def __init__(self):
        """Initialize Remove.bg service"""
        self.api_key = settings.REMOVE_BG_API_KEY
        self.api_url = "https://api.remove.bg/v1.0/removebg"
        self.enabled = bool(self.api_key)
        
        if not self.enabled:
            logger.warning("Remove.bg API key not configured. Background removal will use fallback methods.")
    
    async def remove_background(
        self,
        image_bytes: bytes
    ) -> Tuple[np.ndarray, np.ndarray]:
        """
        Remove background from image using Remove.bg API
        
        Args:
            image_bytes: Image bytes (JPEG/PNG format)
            
        Returns:
            (image_no_bg, mask) - Image with transparent background (BGR) and binary mask
        """
        if self.enabled:
            try:
                return await self._remove_with_api(image_bytes)
            except Exception as e:
                logger.warning(f"Remove.bg API failed: {e}. Using fallback method.")
                return self._remove_with_fallback(image_bytes)
        else:
            return self._remove_with_fallback(image_bytes)
    
    async def _remove_with_api(self, image_bytes: bytes) -> Tuple[np.ndarray, np.ndarray]:
        """Remove background using Remove.bg API"""
        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                response = await client.post(
                    self.api_url,
                    files={"image_file": image_bytes},
                    data={"size": "auto"},
                    headers={"X-Api-Key": self.api_key}
                )
                response.raise_for_status()
                
                # Parse response
                result_image = Image.open(io.BytesIO(response.content)).convert('RGBA')
                result_array = np.array(result_image)
                
                # Extract RGB and alpha channel
                garment_rgb = result_array[:, :, :3]
                alpha_mask = result_array[:, :, 3]
                
                # Convert RGB to BGR for OpenCV compatibility
                garment_bgr = cv2.cvtColor(garment_rgb, cv2.COLOR_RGB2BGR)
                
                # Binarize mask (0-255 -> 0 or 255)
                _, mask_binary = cv2.threshold(alpha_mask, 127, 255, cv2.THRESH_BINARY)
                
                return garment_bgr, mask_binary
                
        except httpx.HTTPStatusError as e:
            logger.error(f"Remove.bg API HTTP error: {e.response.status_code} - {e.response.text[:200]}")
            raise Exception(f"Remove.bg API error: {e.response.status_code}")
        except Exception as e:
            logger.error(f"Remove.bg API error: {e}")
            raise
    
    def _remove_with_fallback(self, image_bytes: bytes) -> Tuple[np.ndarray, np.ndarray]:
        """Fallback background removal using OpenCV"""
        try:
            # Decode image
            nparr = np.frombuffer(image_bytes, np.uint8)
            image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            
            if image is None:
                raise ValueError("Failed to decode image")
            
            # Convert to grayscale
            gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
            
            # Use GrabCut algorithm for better segmentation
            mask = np.zeros(gray.shape, np.uint8)
            bgd_model = np.zeros((1, 65), np.float64)
            fgd_model = np.zeros((1, 65), np.float64)
            
            # Estimate foreground region (center 60% of image)
            h, w = gray.shape
            rect = (int(w * 0.2), int(h * 0.2), int(w * 0.6), int(h * 0.6))
            
            cv2.grabCut(image, mask, rect, bgd_model, fgd_model, 5, cv2.GC_INIT_WITH_RECT)
            
            # Create binary mask
            mask2 = np.where((mask == 2) | (mask == 0), 0, 255).astype('uint8')
            
            # Refine mask with morphological operations
            kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
            mask2 = cv2.morphologyEx(mask2, cv2.MORPH_CLOSE, kernel)
            mask2 = cv2.morphologyEx(mask2, cv2.MORPH_OPEN, kernel)
            
            # Apply mask to image
            garment_no_bg = cv2.bitwise_and(image, image, mask=mask2)
            
            return garment_no_bg, mask2
            
        except Exception as e:
            logger.error(f"Fallback background removal failed: {e}")
            # Last resort: return original image with full mask
            nparr = np.frombuffer(image_bytes, np.uint8)
            image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            if image is None:
                raise ValueError("Failed to decode image")
            mask = np.ones(image.shape[:2], dtype=np.uint8) * 255
            return image, mask
