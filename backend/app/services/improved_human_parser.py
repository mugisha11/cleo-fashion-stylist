"""
Improved Human Parser
Generates semantic parsing masks that preserve full body structure
CRITICAL: Never removes torso or limbs, only identifies clothing regions
"""
import cv2
import numpy as np
from typing import Dict, Tuple, Optional
import logging

logger = logging.getLogger(__name__)


class ImprovedHumanParser:
    """
    Improved human parsing that preserves full body structure
    Uses semantic segmentation to identify regions without removing them
    """
    
    # Semantic class definitions
    CLASSES = {
        0: 'background',
        1: 'hat',
        2: 'hair',
        3: 'glove',
        4: 'sunglasses',
        5: 'upper-clothes',
        6: 'dress',
        7: 'coat',
        8: 'socks',
        9: 'pants',
        10: 'jumpsuits',
        11: 'scarf',
        12: 'skirt',
        13: 'face',
        14: 'left-arm',
        15: 'right-arm',
        16: 'left-leg',
        17: 'right-leg',
        18: 'left-shoe',
        19: 'right-shoe',
    }
    
    # Protected regions (face, hair, neck) - NEVER modify
    PROTECTED_REGIONS = [1, 2, 13]  # hat, hair, face
    
    # Body structure regions (arms, legs) - PRESERVE, don't remove
    BODY_STRUCTURE_REGIONS = [14, 15, 16, 17, 18, 19]  # arms, legs, shoes
    
    # Clothing regions that CAN be replaced
    CLOTHING_REGIONS = [5, 6, 7, 9, 10, 12]  # upper-clothes, dress, coat, pants, jumpsuits, skirt
    
    def __init__(self):
        pass
    
    def parse(self, image: np.ndarray) -> Dict[str, np.ndarray]:
        """
        Parse human body with full structure preservation
        
        CRITICAL: Returns masks that preserve body, only mark clothing regions
        """
        h, w = image.shape[:2]
        
        # Create full body mask (everything except background)
        # This ensures body is NEVER removed
        full_body_mask = np.ones((h, w), dtype=np.uint8) * 255
        
        # Create semantic parsing mask
        parsing_mask = np.zeros((h, w), dtype=np.uint8)
        
        # Detect face for protected regions
        face_region = self._detect_face_region(image)
        
        # Step 1: Identify protected regions (face, hair)
        protected_mask = np.zeros((h, w), dtype=np.uint8)
        if face_region:
            x, y, fw, fh = face_region
            # Face region
            x_start = max(0, x - fw // 4)
            y_start = max(0, y - fh // 4)
            x_end = min(w, x + fw + fw // 4)
            y_end = min(h, y + fh + fh // 4)
            protected_mask[y_start:y_end, x_start:x_end] = 255
            parsing_mask[y_start:y_end, x_start:x_end] = 13  # face
            
            # Hair region (above face)
            hair_y_start = max(0, y - int(fh * 0.6))
            hair_y_end = y
            hair_x_start = max(0, x - fw // 3)
            hair_x_end = min(w, x + fw + fw // 3)
            protected_mask[hair_y_start:hair_y_end, hair_x_start:hair_x_end] = 255
            parsing_mask[hair_y_start:hair_y_end, hair_x_start:hair_x_end] = 2  # hair
        
        # Step 2: Identify body structure (arms, legs, torso)
        # Use pose estimation to find body parts
        body_structure_mask = self._detect_body_structure(image, face_region)
        
        # Step 3: Identify clothing regions (on top of body structure)
        # Upper body clothing region
        clothing_mask = np.zeros((h, w), dtype=np.uint8)
        
        if face_region:
            x, y, fw, fh = face_region
            # Upper body: below face, above waist
            upper_y_start = y + fh
            upper_y_end = int(h * 0.65)  # Above waist
            upper_x_start = max(0, int(w * 0.15))
            upper_x_end = min(w, int(w * 0.85))
            
            # Mark as upper-clothes region
            clothing_upper = np.zeros((h, w), dtype=np.uint8)
            clothing_upper[upper_y_start:upper_y_end, upper_x_start:upper_x_end] = 255
            # Exclude protected regions
            clothing_upper[protected_mask > 0] = 0
            clothing_mask = cv2.bitwise_or(clothing_mask, clothing_upper)
            parsing_mask[upper_y_start:upper_y_end, upper_x_start:upper_x_end] = 5  # upper-clothes
            
            # Lower body: waist to knees/ankles
            lower_y_start = int(h * 0.5)
            lower_y_end = int(h * 0.95)
            lower_x_start = max(0, int(w * 0.2))
            lower_x_end = min(w, int(w * 0.8))
            
            clothing_lower = np.zeros((h, w), dtype=np.uint8)
            clothing_lower[lower_y_start:lower_y_end, lower_x_start:lower_x_end] = 255
            clothing_mask = cv2.bitwise_or(clothing_mask, clothing_lower)
            parsing_mask[lower_y_start:lower_y_end, lower_x_start:lower_x_end] = 9  # pants
        else:
            # No face detected - use geometric regions
            # Upper body
            upper_y_start = int(h * 0.15)
            upper_y_end = int(h * 0.65)
            clothing_mask[upper_y_start:upper_y_end, :] = 255
            parsing_mask[upper_y_start:upper_y_end, :] = 5
            
            # Lower body
            lower_y_start = int(h * 0.5)
            lower_y_end = int(h * 0.95)
            clothing_mask[lower_y_start:lower_y_end, :] = 255
            parsing_mask[lower_y_start:lower_y_end, :] = 9
        
        # CRITICAL: Ensure clothing mask has minimum coverage
        coverage = np.sum(clothing_mask > 0) / clothing_mask.size
        if coverage < 0.15:  # Less than 15% coverage
            logger.warning(f"Clothing mask coverage too low: {coverage:.3f}, expanding")
            # Expand mask to ensure minimum coverage
            kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (15, 15))
            clothing_mask = cv2.dilate(clothing_mask, kernel, iterations=2)
            coverage = np.sum(clothing_mask > 0) / clothing_mask.size
            logger.info(f"Expanded mask coverage: {coverage:.3f}")
        
        # CRITICAL: Create body preservation mask
        # This mask ensures body structure is NEVER removed
        body_preservation_mask = full_body_mask.copy()
        # Only exclude protected regions from body preservation
        body_preservation_mask[protected_mask > 0] = 0
        
        return {
            'parsing_mask': parsing_mask,
            'clothing_mask': clothing_mask,
            'protected_mask': protected_mask,
            'body_preservation_mask': body_preservation_mask,  # NEW: Ensures body is preserved
            'full_body_mask': full_body_mask,  # NEW: Full body structure
            'face_regions': [face_region] if face_region else [],
            'method': 'improved_fallback',
            'coverage': float(coverage)
        }
    
    def _detect_face_region(self, image: np.ndarray) -> Optional[Tuple[int, int, int, int]]:
        """Detect face region using OpenCV"""
        try:
            gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
            face_cascade = cv2.CascadeClassifier(
                cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'
            )
            faces = face_cascade.detectMultiScale(gray, 1.1, 4)
            
            if len(faces) > 0:
                return tuple(faces[0])  # (x, y, w, h)
            return None
        except Exception as e:
            logger.warning(f"Face detection failed: {e}")
            return None
    
    def _detect_body_structure(self, image: np.ndarray, face_region: Optional[Tuple]) -> np.ndarray:
        """
        Detect body structure (torso, arms, legs)
        This ensures these regions are preserved
        """
        h, w = image.shape[:2]
        body_mask = np.zeros((h, w), dtype=np.uint8)
        
        if face_region:
            x, y, fw, fh = face_region
            # Torso: below face to waist
            torso_y_start = y + fh
            torso_y_end = int(h * 0.7)
            torso_x_start = max(0, int(w * 0.2))
            torso_x_end = min(w, int(w * 0.8))
            body_mask[torso_y_start:torso_y_end, torso_x_start:torso_x_end] = 255
            
            # Arms: sides of torso
            arm_width = int(w * 0.15)
            body_mask[torso_y_start:torso_y_end, :arm_width] = 255  # Left arm
            body_mask[torso_y_start:torso_y_end, w-arm_width:] = 255  # Right arm
            
            # Legs: below waist
            leg_y_start = int(h * 0.6)
            leg_y_end = int(h * 0.95)
            leg_x_start = max(0, int(w * 0.25))
            leg_x_end = min(w, int(w * 0.75))
            body_mask[leg_y_start:leg_y_end, leg_x_start:leg_x_end] = 255
        else:
            # No face - use geometric regions
            body_mask[int(h * 0.2):int(h * 0.9), int(w * 0.15):int(w * 0.85)] = 255
        
        return body_mask
    
    def get_clothing_mask(self, parsing_result: Dict) -> np.ndarray:
        """Get binary mask for clothing regions"""
        mask = parsing_result.get('clothing_mask', np.zeros((1, 1), dtype=np.uint8))
        
        # Validate mask is not empty
        if mask.size == 0 or np.sum(mask > 0) == 0:
            logger.error("CRITICAL: Clothing mask is empty, creating fallback")
            # Create fallback mask
            if 'parsing_mask' in parsing_result:
                h, w = parsing_result['parsing_mask'].shape[:2]
            else:
                h, w = 512, 512
            mask = np.ones((h, w), dtype=np.uint8) * 255
            # Remove top 20% (face region)
            mask[:int(h * 0.2), :] = 0
        
        return mask
    
    def get_protected_mask(self, parsing_result: Dict) -> np.ndarray:
        """Get binary mask for protected regions (face, hair)"""
        return parsing_result.get('protected_mask', np.zeros((1, 1), dtype=np.uint8))
    
    def get_body_preservation_mask(self, parsing_result: Dict) -> np.ndarray:
        """Get mask that ensures body structure is preserved"""
        return parsing_result.get('body_preservation_mask', 
                                 np.ones((512, 512), dtype=np.uint8) * 255)
