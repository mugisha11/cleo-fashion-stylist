"""
Seam Blending, Shadow Synthesis & Fabric Realism Service
Ensures natural integration of clothing with body
No visible seams, realistic shadows, natural fabric deformation
"""
import cv2
import numpy as np
from typing import Tuple, Optional, Dict
import logging

logger = logging.getLogger(__name__)


class SeamBlendingService:
    """
    Creates photorealistic integration of clothing with body:
    - Edge blending for seamless transitions
    - Lighting harmonization
    - Shadow synthesis
    - Fabric deformation simulation
    """
    
    def __init__(self):
        pass
    
    def blend_clothing(
        self,
        person_image: np.ndarray,
        clothing_image: np.ndarray,
        clothing_mask: np.ndarray,
        pose_map: Optional[np.ndarray] = None
    ) -> Tuple[np.ndarray, Dict]:
        """
        Blend clothing naturally into person image
        
        Args:
            person_image: Person with clothing removed
            clothing_image: Clothing item to apply
            clothing_mask: Binary mask of clothing region
            pose_map: Optional pose information for better alignment
        
        Returns:
            (blended_image, metadata)
        """
        try:
            # Step 1: Align and warp clothing to body
            warped_clothing = self._warp_clothing_to_body(
                clothing_image, person_image, clothing_mask, pose_map
            )
            
            # Step 2: Edge blending for seamless transition
            blended = self._blend_edges(
                person_image, warped_clothing, clothing_mask
            )
            
            # Step 3: Lighting harmonization
            blended = self._harmonize_lighting(blended, person_image, clothing_mask)
            
            # Step 4: Shadow synthesis
            blended = self._add_shadows(blended, person_image, clothing_mask, pose_map)
            
            # Step 5: Fabric deformation (subtle wrinkles)
            blended = self._apply_fabric_deformation(blended, clothing_mask)
            
            metadata = {
                'blending_method': 'multi_stage',
                'shadows_applied': True,
                'lighting_harmonized': True
            }
            
            return blended, metadata
            
        except Exception as e:
            logger.error(f"Seam blending error: {e}")
            # Fallback: simple alpha blending
            return self._simple_blend(person_image, clothing_image, clothing_mask), {}
    
    def _warp_clothing_to_body(
        self,
        clothing_image: np.ndarray,
        person_image: np.ndarray,
        clothing_mask: np.ndarray,
        pose_map: Optional[np.ndarray]
    ) -> np.ndarray:
        """
        Warp clothing to match body shape and pose
        """
        # For now, use simple scaling and positioning
        # In production, use thin-plate spline or similar warping
        
        h_person, w_person = person_image.shape[:2]
        h_cloth, w_cloth = clothing_image.shape[:2]
        
        # Resize clothing to match mask size
        mask_h, mask_w = clothing_mask.shape[:2]
        
        if mask_h != h_cloth or mask_w != w_cloth:
            clothing_resized = cv2.resize(clothing_image, (mask_w, mask_h))
        else:
            clothing_resized = clothing_image.copy()
        
        # Find clothing region in person image
        mask_3channel = cv2.cvtColor(clothing_mask, cv2.COLOR_GRAY2BGR) / 255.0
        
        # Place clothing in correct position
        warped = clothing_resized * mask_3channel
        
        return warped.astype(np.uint8)
    
    def _blend_edges(
        self,
        person_image: np.ndarray,
        clothing_image: np.ndarray,
        clothing_mask: np.ndarray
    ) -> np.ndarray:
        """
        Blend edges for seamless transition
        Uses multi-scale blending and feathering
        """
        # Create feather mask (soft edges)
        kernel_size = 15
        kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (kernel_size, kernel_size))
        
        # Dilate mask slightly
        dilated_mask = cv2.dilate(clothing_mask, kernel, iterations=1)
        
        # Create distance transform for smooth blending
        dist_transform = cv2.distanceTransform(clothing_mask, cv2.DIST_L2, 5)
        
        # Normalize to 0-1 range
        max_dist = np.max(dist_transform)
        if max_dist > 0:
            dist_transform = dist_transform / max_dist
        else:
            dist_transform = (clothing_mask > 0).astype(np.float32)
        
        # Create feather mask (1.0 in center, 0.0 at edges)
        feather_width = kernel_size
        feather_mask = np.clip(
            (dist_transform - (1.0 - feather_width / max_dist)) / (feather_width / max_dist),
            0.0, 1.0
        )
        
        # Apply feathering
        feather_3channel = cv2.cvtColor(feather_mask, cv2.COLOR_GRAY2BGR).astype(np.float32)
        
        # Blend
        blended = (
            person_image.astype(np.float32) * (1.0 - feather_3channel) +
            clothing_image.astype(np.float32) * feather_3channel
        ).astype(np.uint8)
        
        return blended
    
    def _harmonize_lighting(
        self,
        blended_image: np.ndarray,
        person_image: np.ndarray,
        clothing_mask: np.ndarray
    ) -> np.ndarray:
        """
        Harmonize lighting between clothing and person
        Matches brightness, contrast, and color temperature
        """
        result = blended_image.copy()
        
        # Extract clothing region
        clothing_region = result[clothing_mask > 0]
        person_region = person_image[clothing_mask == 0]
        
        if len(clothing_region) == 0 or len(person_region) == 0:
            return result
        
        # Calculate mean brightness
        clothing_brightness = np.mean(cv2.cvtColor(clothing_region.reshape(-1, 1, 3), cv2.COLOR_BGR2GRAY))
        person_brightness = np.mean(cv2.cvtColor(person_region.reshape(-1, 1, 3), cv2.COLOR_BGR2GRAY))
        
        # Adjust clothing brightness to match person
        brightness_ratio = person_brightness / (clothing_brightness + 1e-7)
        brightness_ratio = np.clip(brightness_ratio, 0.7, 1.3)  # Limit adjustment
        
        # Apply brightness adjustment to clothing region
        clothing_adjusted = result[clothing_mask > 0].astype(np.float32) * brightness_ratio
        result[clothing_mask > 0] = np.clip(clothing_adjusted, 0, 255).astype(np.uint8)
        
        # Color temperature matching (simplified)
        # Calculate average color in surrounding region
        kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (20, 20))
        dilated_mask = cv2.dilate(clothing_mask, kernel, iterations=2)
        border_mask = dilated_mask - clothing_mask
        
        if np.any(border_mask > 0):
            border_colors = person_image[border_mask > 0]
            avg_border_color = np.mean(border_colors, axis=0)
            
            clothing_colors = result[clothing_mask > 0]
            avg_clothing_color = np.mean(clothing_colors, axis=0)
            
            # Subtle color shift
            color_shift = (avg_border_color - avg_clothing_color) * 0.2
            clothing_colors_adjusted = clothing_colors.astype(np.float32) + color_shift
            result[clothing_mask > 0] = np.clip(clothing_colors_adjusted, 0, 255).astype(np.uint8)
        
        return result
    
    def _add_shadows(
        self,
        image: np.ndarray,
        person_image: np.ndarray,
        clothing_mask: np.ndarray,
        pose_map: Optional[np.ndarray]
    ) -> np.ndarray:
        """
        Add realistic shadows under clothing
        """
        result = image.copy()
        
        # Create shadow mask (below clothing, slightly offset)
        shadow_mask = np.zeros_like(clothing_mask)
        
        # Find bottom edge of clothing
        h, w = clothing_mask.shape
        for x in range(w):
            col = clothing_mask[:, x]
            clothing_pixels = np.where(col > 0)[0]
            if len(clothing_pixels) > 0:
                bottom_y = np.max(clothing_pixels)
                # Add shadow below clothing
                shadow_start = min(h - 1, bottom_y + 2)
                shadow_end = min(h - 1, bottom_y + 10)
                shadow_mask[shadow_start:shadow_end, x] = 255
        
        # Blur shadow mask
        shadow_mask = cv2.GaussianBlur(shadow_mask, (15, 15), 0)
        
        # Create shadow (darken image)
        shadow_intensity = 0.3
        shadow_3channel = (shadow_mask / 255.0 * shadow_intensity).reshape(h, w, 1)
        
        result = (result.astype(np.float32) * (1.0 - shadow_3channel)).astype(np.uint8)
        
        return result
    
    def _apply_fabric_deformation(
        self,
        image: np.ndarray,
        clothing_mask: np.ndarray
    ) -> np.ndarray:
        """
        Apply subtle fabric deformation (wrinkles, folds)
        """
        # Very subtle effect - just add slight texture variation
        # In production, use more sophisticated methods
        
        result = image.copy()
        
        # Create subtle noise in clothing region
        noise = np.random.randn(*image.shape).astype(np.float32) * 2.0
        noise_mask = (clothing_mask > 0).astype(np.float32).reshape(*image.shape[:2], 1)
        
        # Apply noise only to clothing
        result = result.astype(np.float32) + noise * noise_mask * 0.5
        result = np.clip(result, 0, 255).astype(np.uint8)
        
        return result
    
    def _simple_blend(
        self,
        person_image: np.ndarray,
        clothing_image: np.ndarray,
        clothing_mask: np.ndarray
    ) -> np.ndarray:
        """Simple alpha blending fallback"""
        mask_3channel = cv2.cvtColor(clothing_mask, cv2.COLOR_GRAY2BGR) / 255.0
        
        # Resize clothing if needed
        h, w = person_image.shape[:2]
        if clothing_image.shape[:2] != (h, w):
            clothing_image = cv2.resize(clothing_image, (w, h))
        
        blended = (
            person_image.astype(np.float32) * (1.0 - mask_3channel) +
            clothing_image.astype(np.float32) * mask_3channel
        ).astype(np.uint8)
        
        return blended
