"""
Segmentation Service
Provides garment segmentation functionality using various methods
"""
import logging
import numpy as np
import cv2
from typing import Tuple
from ..core.config import settings

logger = logging.getLogger(__name__)


class SegmentationService:
    """
    Service for segmenting garments from images
    Supports multiple segmentation methods: rembg, sam, opencv
    """
    
    def __init__(self, method: str = "opencv"):
        """
        Initialize segmentation service
        
        Args:
            method: Segmentation method to use ('rembg', 'sam', 'opencv')
        """
        self.method = method or settings.SEGMENTATION_METHOD
        logger.info(f"SegmentationService initialized with method: {self.method}")
    
    def segment_garment(self, garment_image: np.ndarray) -> Tuple[np.ndarray, np.ndarray]:
        """
        Segment garment from image, removing background
        
        Args:
            garment_image: Input garment image (BGR format, numpy array)
            
        Returns:
            (garment_no_bg, garment_mask) - Image with transparent background (BGR) and binary mask
        """
        if self.method == "rembg":
            return self._segment_with_rembg(garment_image)
        elif self.method == "sam":
            return self._segment_with_sam(garment_image)
        else:  # opencv (default)
            return self._segment_with_opencv(garment_image)
    
    def _segment_with_opencv(self, garment_image: np.ndarray) -> Tuple[np.ndarray, np.ndarray]:
        """
        Segment garment using OpenCV GrabCut algorithm
        This is the default fallback method
        """
        try:
            h, w = garment_image.shape[:2]
            
            # Use GrabCut algorithm for better segmentation
            mask = np.zeros((h, w), np.uint8)
            bgd_model = np.zeros((1, 65), np.float64)
            fgd_model = np.zeros((1, 65), np.float64)
            
            # Estimate foreground region (center 60% of image)
            rect = (int(w * 0.2), int(h * 0.2), int(w * 0.6), int(h * 0.6))
            
            cv2.grabCut(garment_image, mask, rect, bgd_model, fgd_model, 5, cv2.GC_INIT_WITH_RECT)
            
            # Create binary mask (foreground = 255, background = 0)
            mask2 = np.where((mask == 2) | (mask == 0), 0, 255).astype('uint8')
            
            # Refine mask with morphological operations
            kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
            mask2 = cv2.morphologyEx(mask2, cv2.MORPH_CLOSE, kernel)
            mask2 = cv2.morphologyEx(mask2, cv2.MORPH_OPEN, kernel)
            
            # Apply mask to image
            garment_no_bg = cv2.bitwise_and(garment_image, garment_image, mask=mask2)
            
            return garment_no_bg, mask2
            
        except Exception as e:
            logger.error(f"OpenCV segmentation failed: {e}")
            # Last resort: return original image with full mask
            mask = np.ones(garment_image.shape[:2], dtype=np.uint8) * 255
            return garment_image, mask
    
    def _segment_with_rembg(self, garment_image: np.ndarray) -> Tuple[np.ndarray, np.ndarray]:
        """
        Segment garment using rembg library (if available)
        Falls back to OpenCV if rembg is not available
        """
        try:
            try:
                from rembg import remove  # type: ignore
                from PIL import Image  # type: ignore
                import io
                
                # Convert BGR to RGB for PIL
                garment_rgb = cv2.cvtColor(garment_image, cv2.COLOR_BGR2RGB)
                pil_image = Image.fromarray(garment_rgb)
                
                # Remove background
                output_bytes = remove(pil_image.tobytes())
                result_image = Image.open(io.BytesIO(output_bytes)).convert('RGBA')
                result_array = np.array(result_image)
                
                # Extract RGB and alpha channel
                garment_rgb = result_array[:, :, :3]
                alpha_mask = result_array[:, :, 3]
                
                # Convert RGB to BGR for OpenCV compatibility
                garment_bgr = cv2.cvtColor(garment_rgb, cv2.COLOR_RGB2BGR)
                
                # Binarize mask (0-255 -> 0 or 255)
                _, mask_binary = cv2.threshold(alpha_mask, 127, 255, cv2.THRESH_BINARY)
                
                return garment_bgr, mask_binary
                
            except ImportError:
                logger.warning("rembg library not available, falling back to OpenCV")
                return self._segment_with_opencv(garment_image)
                
        except Exception as e:
            logger.error(f"rembg segmentation failed: {e}, falling back to OpenCV")
            return self._segment_with_opencv(garment_image)
    
    def _segment_with_sam(self, garment_image: np.ndarray) -> Tuple[np.ndarray, np.ndarray]:
        """
        Segment garment using SAM (Segment Anything Model) if available
        Falls back to OpenCV if SAM is not available
        """
        try:
            # SAM integration would go here
            # For now, fall back to OpenCV
            logger.warning("SAM segmentation not yet implemented, falling back to OpenCV")
            return self._segment_with_opencv(garment_image)
            
        except Exception as e:
            logger.error(f"SAM segmentation failed: {e}, falling back to OpenCV")
            return self._segment_with_opencv(garment_image)
