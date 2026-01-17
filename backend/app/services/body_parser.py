"""
Body Parser Service
Wraps human parsing functionality to provide a consistent interface
for body segmentation with allowed and locked regions
"""
import cv2
import numpy as np
from typing import Dict, Optional, Any
import logging

from .improved_human_parser import ImprovedHumanParser

logger = logging.getLogger(__name__)


class BodyParser:
    """
    Body parser that provides allowed_mask and locked_mask for try-on operations.
    
    Wraps ImprovedHumanParser to provide a consistent interface that matches
    the expected format for try-on generation.
    """
    
    def __init__(self):
        """Initialize the body parser with improved human parser"""
        self.parser = ImprovedHumanParser()
    
    async def parse_body(
        self,
        user_image: np.ndarray,
        parsing_instructions: Optional[Dict[str, Any]] = None,
        garment_classification: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Parse body and return allowed/locked masks for try-on.
        
        Args:
            user_image: User photo (BGR format)
            parsing_instructions: Optional parsing instructions (currently unused)
            garment_classification: Optional garment classification dict with:
                - garment_type: str (e.g., "top", "pants", "jacket", "shoes")
                - target_body_part: list of allowed body parts
        
        Returns:
            Dictionary with:
                - allowed_mask: np.ndarray - regions where clothing can be placed
                - locked_mask: np.ndarray - protected regions (face, hair, etc.)
                - parsing_mask: np.ndarray - full semantic parsing mask
                - clothing_mask: np.ndarray - clothing regions mask
                - protected_mask: np.ndarray - protected regions mask
        """
        # Parse the body using improved human parser
        parsing_result = self.parser.parse(user_image)
        
        # Extract masks from parsing result
        protected_mask = parsing_result.get('protected_mask', np.zeros((1, 1), dtype=np.uint8))
        clothing_mask = parsing_result.get('clothing_mask', np.zeros((1, 1), dtype=np.uint8))
        
        # Determine allowed regions based on garment type
        allowed_mask = self._get_allowed_mask(
            parsing_result=parsing_result,
            garment_classification=garment_classification,
            user_image=user_image
        )
        
        # Locked mask is the protected regions (face, hair, etc.)
        locked_mask = protected_mask.copy()
        
        # Ensure masks have the same shape as user image
        h, w = user_image.shape[:2]
        if allowed_mask.shape[:2] != (h, w):
            allowed_mask = cv2.resize(allowed_mask, (w, h), interpolation=cv2.INTER_NEAREST)
        if locked_mask.shape[:2] != (h, w):
            locked_mask = cv2.resize(locked_mask, (w, h), interpolation=cv2.INTER_NEAREST)
        
        return {
            'allowed_mask': allowed_mask,
            'locked_mask': locked_mask,
            'parsing_mask': parsing_result.get('parsing_mask'),
            'clothing_mask': clothing_mask,
            'protected_mask': protected_mask,
            'method': parsing_result.get('method', 'improved_fallback')
        }
    
    def _get_allowed_mask(
        self,
        parsing_result: Dict[str, Any],
        garment_classification: Optional[Dict[str, Any]],
        user_image: np.ndarray
    ) -> np.ndarray:
        """
        Get allowed mask based on garment type and classification.
        
        Args:
            parsing_result: Result from human parser
            garment_classification: Garment classification dict
            user_image: User image for shape reference
        
        Returns:
            Binary mask of allowed regions
        """
        h, w = user_image.shape[:2]
        clothing_mask = parsing_result.get('clothing_mask', np.zeros((h, w), dtype=np.uint8))
        
        # If garment classification is provided, use it to determine allowed regions
        if garment_classification:
            garment_type = garment_classification.get('garment_type', '').lower()
            target_body_parts = garment_classification.get('target_body_part', [])
            
            # Create allowed mask based on garment type
            if garment_type in ['top', 'shirt', 'blouse', 't-shirt', 'upper-clothes']:
                # Upper body clothing - allow torso and arms
                allowed_mask = np.zeros((h, w), dtype=np.uint8)
                # Upper body region (below face, above waist)
                upper_y_start = int(h * 0.15)
                upper_y_end = int(h * 0.65)
                allowed_mask[upper_y_start:upper_y_end, :] = 255
                
                # Exclude protected regions
                protected_mask = parsing_result.get('protected_mask', np.zeros((h, w), dtype=np.uint8))
                allowed_mask[protected_mask > 0] = 0
                
                return allowed_mask
                
            elif garment_type in ['pants', 'trousers', 'jeans', 'lower-clothes']:
                # Lower body clothing - allow hips and legs
                allowed_mask = np.zeros((h, w), dtype=np.uint8)
                lower_y_start = int(h * 0.5)
                lower_y_end = int(h * 0.95)
                allowed_mask[lower_y_start:lower_y_end, :] = 255
                
                return allowed_mask
                
            elif garment_type in ['dress', 'jumpsuit', 'onesie']:
                # Full body clothing - allow torso and lower body
                allowed_mask = np.zeros((h, w), dtype=np.uint8)
                upper_y_start = int(h * 0.15)
                lower_y_end = int(h * 0.95)
                allowed_mask[upper_y_start:lower_y_end, :] = 255
                
                # Exclude protected regions
                protected_mask = parsing_result.get('protected_mask', np.zeros((h, w), dtype=np.uint8))
                allowed_mask[protected_mask > 0] = 0
                
                return allowed_mask
                
            elif garment_type in ['jacket', 'coat', 'outerwear']:
                # Outerwear - similar to top but can cover more
                allowed_mask = np.zeros((h, w), dtype=np.uint8)
                upper_y_start = int(h * 0.1)
                upper_y_end = int(h * 0.7)
                allowed_mask[upper_y_start:upper_y_end, :] = 255
                
                # Exclude protected regions
                protected_mask = parsing_result.get('protected_mask', np.zeros((h, w), dtype=np.uint8))
                allowed_mask[protected_mask > 0] = 0
                
                return allowed_mask
        
        # Default: use clothing mask from parsing result
        # Ensure it's not empty
        if np.sum(clothing_mask > 0) == 0:
            logger.warning("Clothing mask is empty, creating fallback allowed mask")
            # Create fallback: allow upper and lower body, exclude face region
            allowed_mask = np.ones((h, w), dtype=np.uint8) * 255
            # Remove top 20% (face region)
            allowed_mask[:int(h * 0.2), :] = 0
            return allowed_mask
        
        return clothing_mask
