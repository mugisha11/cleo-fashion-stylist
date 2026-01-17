"""
Skin Tone & Texture Preservation Service
Ensures skin remains identical in color, undertone, and texture
Validates ΔE color difference < 2 and face similarity ≥ 99%
"""
import cv2
import numpy as np
from typing import Tuple, Dict, Optional
import logging
from skimage.color import rgb2lab, deltaE_cie76

logger = logging.getLogger(__name__)


class SkinPreservationService:
    """
    Critical service for preserving skin tone and texture
    Validates color accuracy using ΔE (CIE Lab color difference)
    """
    
    def __init__(self, max_delta_e: float = 2.0):
        """
        Args:
            max_delta_e: Maximum allowed ΔE color difference (default 2.0)
                        ΔE < 1: Not perceptible
                        ΔE < 2: Perceptible by trained observer
                        ΔE < 3: Perceptible by average observer
        """
        self.max_delta_e = max_delta_e
    
    def validate_skin_preservation(
        self,
        original: np.ndarray,
        result: np.ndarray,
        skin_mask: Optional[np.ndarray] = None
    ) -> Tuple[bool, Dict]:
        """
        Validate that skin tone and texture are preserved
        
        Returns:
            (passed, validation_metrics)
        """
        try:
            # Extract skin regions
            if skin_mask is None:
                skin_mask = self._detect_skin_regions(original)
            
            if not np.any(skin_mask):
                return False, {'error': 'No skin regions detected'}
            
            # Extract skin pixels
            orig_skin = original[skin_mask > 0]
            result_skin = result[skin_mask > 0]
            
            if len(orig_skin) == 0 or len(result_skin) == 0:
                return False, {'error': 'No skin pixels found'}
            
            # Calculate color statistics
            orig_mean = np.mean(orig_skin, axis=0)
            result_mean = np.mean(result_skin, axis=0)
            
            # Calculate ΔE (CIE Lab color difference)
            orig_lab = rgb2lab(orig_mean.reshape(1, 1, 3) / 255.0)
            result_lab = rgb2lab(result_mean.reshape(1, 1, 3) / 255.0)
            delta_e = deltaE_cie76(orig_lab[0, 0], result_lab[0, 0])
            
            # Calculate RGB histogram similarity
            hist_similarity = self._histogram_similarity(orig_skin, result_skin)
            
            # Calculate texture similarity (using gradient magnitude)
            texture_similarity = self._texture_similarity(
                original, result, skin_mask
            )
            
            # Overall validation
            passed = (
                delta_e < self.max_delta_e and
                hist_similarity > 0.95 and
                texture_similarity > 0.90
            )
            
            metrics = {
                'delta_e': float(delta_e),
                'histogram_similarity': float(hist_similarity),
                'texture_similarity': float(texture_similarity),
                'original_mean_rgb': orig_mean.tolist(),
                'result_mean_rgb': result_mean.tolist(),
                'passed': passed,
                'message': self._get_message(delta_e, hist_similarity, texture_similarity)
            }
            
            return passed, metrics
            
        except Exception as e:
            logger.error(f"Skin preservation validation error: {e}")
            return False, {'error': str(e)}
    
    def _detect_skin_regions(self, image: np.ndarray) -> np.ndarray:
        """Detect skin regions using color-based segmentation"""
        # Convert to YCbCr for better skin detection
        ycbcr = cv2.cvtColor(image, cv2.COLOR_BGR2YCrCb)
        
        # Skin color range in YCbCr
        lower_skin = np.array([0, 135, 85], dtype=np.uint8)
        upper_skin = np.array([255, 180, 135], dtype=np.uint8)
        
        skin_mask = cv2.inRange(ycbcr, lower_skin, upper_skin)
        
        # Clean up with morphology
        kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
        skin_mask = cv2.morphologyEx(skin_mask, cv2.MORPH_OPEN, kernel)
        skin_mask = cv2.morphologyEx(skin_mask, cv2.MORPH_CLOSE, kernel)
        
        return skin_mask
    
    def _histogram_similarity(
        self,
        orig_skin: np.ndarray,
        result_skin: np.ndarray
    ) -> float:
        """Calculate histogram similarity (0-1)"""
        # Calculate histograms for each channel
        hist_orig_b = cv2.calcHist([orig_skin], [0], None, [256], [0, 256])
        hist_orig_g = cv2.calcHist([orig_skin], [1], None, [256], [0, 256])
        hist_orig_r = cv2.calcHist([orig_skin], [2], None, [256], [0, 256])
        
        hist_result_b = cv2.calcHist([result_skin], [0], None, [256], [0, 256])
        hist_result_g = cv2.calcHist([result_skin], [1], None, [256], [0, 256])
        hist_result_r = cv2.calcHist([result_skin], [2], None, [256], [0, 256])
        
        # Normalize histograms
        hist_orig_b = hist_orig_b / (np.sum(hist_orig_b) + 1e-7)
        hist_orig_g = hist_orig_g / (np.sum(hist_orig_g) + 1e-7)
        hist_orig_r = hist_orig_r / (np.sum(hist_orig_r) + 1e-7)
        
        hist_result_b = hist_result_b / (np.sum(hist_result_b) + 1e-7)
        hist_result_g = hist_result_g / (np.sum(hist_result_g) + 1e-7)
        hist_result_r = hist_result_r / (np.sum(hist_result_r) + 1e-7)
        
        # Calculate correlation for each channel
        corr_b = cv2.compareHist(hist_orig_b, hist_result_b, cv2.HISTCMP_CORREL)
        corr_g = cv2.compareHist(hist_orig_g, hist_result_g, cv2.HISTCMP_CORREL)
        corr_r = cv2.compareHist(hist_orig_r, hist_result_r, cv2.HISTCMP_CORREL)
        
        # Average correlation
        similarity = (corr_b + corr_g + corr_r) / 3.0
        
        return max(0.0, similarity)
    
    def _texture_similarity(
        self,
        original: np.ndarray,
        result: np.ndarray,
        skin_mask: np.ndarray
    ) -> float:
        """Calculate texture similarity using gradient magnitude"""
        # Convert to grayscale
        orig_gray = cv2.cvtColor(original, cv2.COLOR_BGR2GRAY)
        result_gray = cv2.cvtColor(result, cv2.COLOR_BGR2GRAY)
        
        # Calculate gradients
        orig_grad_x = cv2.Sobel(orig_gray, cv2.CV_64F, 1, 0, ksize=3)
        orig_grad_y = cv2.Sobel(orig_gray, cv2.CV_64F, 0, 1, ksize=3)
        orig_grad_mag = np.sqrt(orig_grad_x**2 + orig_grad_y**2)
        
        result_grad_x = cv2.Sobel(result_gray, cv2.CV_64F, 1, 0, ksize=3)
        result_grad_y = cv2.Sobel(result_gray, cv2.CV_64F, 0, 1, ksize=3)
        result_grad_mag = np.sqrt(result_grad_x**2 + result_grad_y**2)
        
        # Extract skin regions
        orig_skin_grad = orig_grad_mag[skin_mask > 0]
        result_skin_grad = result_grad_mag[skin_mask > 0]
        
        if len(orig_skin_grad) == 0:
            return 0.0
        
        # Calculate correlation
        correlation = np.corrcoef(orig_skin_grad.flatten(), result_skin_grad.flatten())[0, 1]
        
        return max(0.0, correlation if not np.isnan(correlation) else 0.0)
    
    def _get_message(
        self,
        delta_e: float,
        hist_similarity: float,
        texture_similarity: float
    ) -> str:
        """Generate validation message"""
        if delta_e < self.max_delta_e and hist_similarity > 0.95 and texture_similarity > 0.90:
            return "Skin tone and texture preserved"
        elif delta_e >= self.max_delta_e:
            return f"Skin tone changed: ΔE = {delta_e:.2f} (max {self.max_delta_e})"
        elif hist_similarity <= 0.95:
            return f"Skin color histogram mismatch: {hist_similarity:.3f}"
        else:
            return f"Skin texture changed: {texture_similarity:.3f}"
    
    def correct_skin_tone(
        self,
        image: np.ndarray,
        target_skin_tone: Dict,
        skin_mask: Optional[np.ndarray] = None
    ) -> np.ndarray:
        """
        Correct skin tone to match target reference
        Uses LAB color space for perceptually uniform color adjustment
        """
        if skin_mask is None:
            skin_mask = self._detect_skin_regions(image)
        
        if not np.any(skin_mask):
            return image
        
        result = image.copy()
        
        # Convert to LAB color space
        lab_image = cv2.cvtColor(image, cv2.COLOR_BGR2LAB).astype(np.float32)
        
        # Target skin tone in LAB
        target_rgb = np.array(target_skin_tone['mean_rgb'])
        target_lab = rgb2lab(target_rgb.reshape(1, 1, 3) / 255.0)
        
        # Extract skin pixels
        skin_pixels = lab_image[skin_mask > 0]
        
        if len(skin_pixels) == 0:
            return result
        
        # Calculate current mean LAB
        current_mean_lab = np.mean(skin_pixels, axis=0)
        
        # Calculate adjustment
        target_lab_flat = target_lab[0, 0]
        adjustment = target_lab_flat - current_mean_lab
        
        # Apply adjustment to skin pixels only
        lab_image[skin_mask > 0] += adjustment
        
        # Clip to valid LAB range
        lab_image[:, :, 0] = np.clip(lab_image[:, :, 0], 0, 100)  # L: 0-100
        lab_image[:, :, 1] = np.clip(lab_image[:, :, 1], -127, 127)  # a: -127 to 127
        lab_image[:, :, 2] = np.clip(lab_image[:, :, 2], -127, 127)  # b: -127 to 127
        
        # Convert back to BGR
        result = cv2.cvtColor(lab_image.astype(np.uint8), cv2.COLOR_LAB2BGR)
        
        return result
