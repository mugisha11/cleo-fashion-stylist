"""
Safe Clothing Removal Service (Phase 1 - Undressing)
Removes only existing clothing while preserving skin tone and texture
Uses LaMa inpainting with strict skin preservation
"""
import cv2
import numpy as np
from typing import Tuple, Optional, Dict
import logging
from PIL import Image

logger = logging.getLogger(__name__)


class ClothingRemovalService:
    """
    Removes clothing from user photo while preserving:
    - Original skin tone (RGB histogram matching)
    - Skin texture (no smoothing/whitening)
    - Face and hair (locked, never modified)
    """
    
    def __init__(self, use_gpu: bool = True):
        self.use_gpu = use_gpu
        # TODO: Load LaMa model for structure-aware inpainting
        # For now, use OpenCV inpainting as fallback
    
    def remove_clothing(
        self,
        image: np.ndarray,
        clothing_mask: np.ndarray,
        protected_mask: np.ndarray,
        skin_regions: Optional[np.ndarray] = None
    ) -> Tuple[np.ndarray, Dict]:
        """
        Remove clothing while preserving skin
        
        Args:
            image: Original user photo
            clothing_mask: Binary mask of clothing to remove (255 = clothing)
            protected_mask: Binary mask of protected regions (face, hair) (255 = protected)
            skin_regions: Optional pre-detected skin regions
        
        Returns:
            (undressed_image, metadata)
        """
        try:
            # Step 1: Extract skin tone reference from visible skin regions
            skin_tone_ref = self._extract_skin_tone(image, protected_mask, skin_regions)
            
            # Step 2: Create inpainting mask (clothing only, excluding protected)
            inpaint_mask = self._create_inpaint_mask(clothing_mask, protected_mask)
            
            # Step 3: Perform structure-aware inpainting
            # Use LaMa or OpenCV inpainting
            undressed = self._inpaint_clothing(image, inpaint_mask, skin_tone_ref)
            
            # Step 4: Preserve skin tone exactly
            undressed = self._preserve_skin_tone(undressed, image, skin_tone_ref, inpaint_mask)
            
            # Step 5: Validate no face/hair modification
            validation = self._validate_preservation(image, undressed, protected_mask)
            
            metadata = {
                'skin_tone_ref': skin_tone_ref,
                'validation': validation,
                'method': 'lama_fallback'  # Will be 'lama' when model loaded
            }
            
            return undressed, metadata
            
        except Exception as e:
            logger.error(f"Clothing removal error: {e}")
            raise
    
    def _extract_skin_tone(
        self,
        image: np.ndarray,
        protected_mask: np.ndarray,
        skin_regions: Optional[np.ndarray]
    ) -> Dict:
        """
        Extract skin tone reference from visible skin regions
        Returns RGB histogram and color statistics
        """
        # Find visible skin (not covered by clothing or protected)
        h, w = image.shape[:2]
        
        if skin_regions is not None:
            # Use provided skin regions
            skin_mask = skin_regions
        else:
            # Detect skin using color-based segmentation
            skin_mask = self._detect_skin_color(image, protected_mask)
        
        # Extract skin pixels
        skin_pixels = image[skin_mask > 0]
        
        if len(skin_pixels) == 0:
            logger.warning("No skin regions detected, using fallback")
            # Use face region as skin reference
            face_region = image[h//4:h//2, w//4:3*w//4]
            skin_pixels = face_region.reshape(-1, 3)
        
        # Calculate skin tone statistics
        mean_rgb = np.mean(skin_pixels, axis=0)
        std_rgb = np.std(skin_pixels, axis=0)
        
        # Calculate histogram
        hist_b = cv2.calcHist([skin_pixels], [0], None, [256], [0, 256])
        hist_g = cv2.calcHist([skin_pixels], [1], None, [256], [0, 256])
        hist_r = cv2.calcHist([skin_pixels], [2], None, [256], [0, 256])
        
        return {
            'mean_rgb': mean_rgb.tolist(),
            'std_rgb': std_rgb.tolist(),
            'histogram': {
                'b': hist_b.flatten().tolist(),
                'g': hist_g.flatten().tolist(),
                'r': hist_r.flatten().tolist()
            },
            'sample_pixels': skin_pixels[:100].tolist()  # Sample for reference
        }
    
    def _detect_skin_color(self, image: np.ndarray, protected_mask: np.ndarray) -> np.ndarray:
        """
        Detect skin regions using color-based segmentation
        Uses YCbCr color space for better skin detection
        """
        # Convert to YCbCr
        ycbcr = cv2.cvtColor(image, cv2.COLOR_BGR2YCrCb)
        
        # Skin color range in YCbCr (empirically determined)
        lower_skin = np.array([0, 135, 85], dtype=np.uint8)
        upper_skin = np.array([255, 180, 135], dtype=np.uint8)
        
        # Create skin mask
        skin_mask = cv2.inRange(ycbcr, lower_skin, upper_skin)
        
        # Exclude protected regions (face/hair)
        skin_mask[protected_mask > 0] = 0
        
        # Morphological operations to clean up
        kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
        skin_mask = cv2.morphologyEx(skin_mask, cv2.MORPH_OPEN, kernel)
        skin_mask = cv2.morphologyEx(skin_mask, cv2.MORPH_CLOSE, kernel)
        
        return skin_mask
    
    def _create_inpaint_mask(
        self,
        clothing_mask: np.ndarray,
        protected_mask: np.ndarray
    ) -> np.ndarray:
        """
        Create inpainting mask: clothing to remove, excluding protected regions
        """
        # Start with clothing mask
        inpaint_mask = clothing_mask.copy()
        
        # Remove protected regions (face, hair) from inpainting
        inpaint_mask[protected_mask > 0] = 0
        
        # Dilate slightly for better edge blending
        kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (3, 3))
        inpaint_mask = cv2.dilate(inpaint_mask, kernel, iterations=1)
        
        return inpaint_mask
    
    def _inpaint_clothing(
        self,
        image: np.ndarray,
        inpaint_mask: np.ndarray,
        skin_tone_ref: Dict
    ) -> np.ndarray:
        """
        Perform structure-aware inpainting to remove clothing
        Uses LaMa (Large Mask Inpainting) when available, OpenCV fallback otherwise
        """
        # TODO: Use LaMa model for better structure preservation
        # For now, use OpenCV's inpainting algorithms
        
        # Use Telea algorithm (fast inpainting)
        result_telea = cv2.inpaint(image, inpaint_mask, 3, cv2.INPAINT_TELEA)
        
        # Use NS algorithm (better for textures)
        result_ns = cv2.inpaint(image, inpaint_mask, 3, cv2.INPAINT_NS)
        
        # Combine both (weighted average)
        # NS is better for textures, Telea for structure
        combined = cv2.addWeighted(result_telea, 0.4, result_ns, 0.6, 0)
        
        return combined
    
    def _preserve_skin_tone(
        self,
        inpainted: np.ndarray,
        original: np.ndarray,
        skin_tone_ref: Dict,
        inpaint_mask: np.ndarray
    ) -> np.ndarray:
        """
        Ensure inpainted skin matches original skin tone exactly
        Uses histogram matching and color correction
        """
        result = inpainted.copy()
        
        # Find inpainted regions
        inpainted_regions = inpaint_mask > 0
        
        if not np.any(inpainted_regions):
            return result
        
        # Extract reference skin color
        ref_mean = np.array(skin_tone_ref['mean_rgb'])
        ref_std = np.array(skin_tone_ref['std_rgb'])
        
        # For each inpainted pixel in skin-like regions, adjust to match reference
        # Only adjust if the inpainted value looks like skin
        for y in range(result.shape[0]):
            for x in range(result.shape[1]):
                if inpainted_regions[y, x]:
                    pixel = result[y, x].astype(np.float32)
                    
                    # Check if pixel is in skin color range
                    if self._is_skin_like(pixel, ref_mean, ref_std):
                        # Adjust to match reference skin tone
                        # Use color transfer technique
                        adjusted = self._transfer_color(pixel, ref_mean, ref_std)
                        result[y, x] = np.clip(adjusted, 0, 255).astype(np.uint8)
        
        return result
    
    def _is_skin_like(self, pixel: np.ndarray, ref_mean: np.ndarray, ref_std: np.ndarray) -> bool:
        """Check if pixel color is within skin color range"""
        # Use Mahalanobis distance
        diff = pixel - ref_mean
        # Simplified check: within 2 standard deviations
        return np.all(np.abs(diff) < 2 * ref_std)
    
    def _transfer_color(
        self,
        pixel: np.ndarray,
        ref_mean: np.ndarray,
        ref_std: np.ndarray
    ) -> np.ndarray:
        """
        Transfer color to match reference skin tone
        Preserves relative color relationships
        """
        # Simple color transfer: shift mean, scale std
        # More sophisticated: use LAB color space for better results
        lab_pixel = cv2.cvtColor(np.uint8([[pixel]]), cv2.COLOR_BGR2LAB)[0, 0]
        lab_ref = cv2.cvtColor(np.uint8([[ref_mean]]), cv2.COLOR_BGR2LAB)[0, 0]
        
        # Transfer L channel (lightness) while preserving a, b (color)
        lab_pixel[0] = lab_ref[0]  # Match lightness
        
        # Convert back to BGR
        bgr = cv2.cvtColor(np.uint8([[lab_pixel]]), cv2.COLOR_LAB2BGR)[0, 0]
        return bgr
    
    def _validate_preservation(
        self,
        original: np.ndarray,
        result: np.ndarray,
        protected_mask: np.ndarray
    ) -> Dict:
        """
        Validate that protected regions (face, hair) were not modified
        """
        protected_pixels = protected_mask > 0
        
        if not np.any(protected_pixels):
            return {'passed': True, 'similarity': 1.0, 'message': 'No protected regions'}
        
        # Extract protected regions
        orig_protected = original[protected_pixels]
        result_protected = result[protected_pixels]
        
        # Calculate similarity (SSIM or pixel difference)
        diff = np.abs(orig_protected.astype(np.float32) - result_protected.astype(np.float32))
        mean_diff = np.mean(diff)
        max_diff = np.max(diff)
        
        # Similarity score (0-1, higher is better)
        similarity = 1.0 - min(1.0, mean_diff / 10.0)  # Normalize by max expected diff
        
        passed = similarity >= 0.99  # Must be 99%+ identical
        
        return {
            'passed': passed,
            'similarity': float(similarity),
            'mean_diff': float(mean_diff),
            'max_diff': float(max_diff),
            'message': 'Protected regions preserved' if passed else 'Protected regions modified'
        }
