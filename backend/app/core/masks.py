"""
Mask Management for Immutable Body Regions
All masks are locked and cannot be modified after Stage 2.
"""
from typing import Dict, Optional
import numpy as np
import cv2


class BodyMasks:
    """
    Immutable body segmentation masks.
    Once created in Stage 2, these masks define locked regions.
    """
    
    def __init__(
        self,
        face_mask: np.ndarray,
        hair_mask: np.ndarray,
        hands_mask: np.ndarray,
        torso_mask: np.ndarray,
        arms_mask: np.ndarray,
        hips_mask: np.ndarray,
        legs_mask: np.ndarray,
        feet_mask: np.ndarray,
        image_shape: tuple,
    ):
        """
        Initialize immutable body masks.
        
        Args:
            face_mask: Face region mask (locked)
            hair_mask: Hair region mask (locked)
            hands_mask: Hands region mask (locked)
            torso_mask: Torso region (editable for tops)
            arms_mask: Arms region (editable for tops)
            hips_mask: Hips region (editable for pants)
            legs_mask: Legs region (editable for pants)
            feet_mask: Feet region (editable for shoes)
            image_shape: (height, width) of original image
        """
        self._face_mask = self._validate_mask(face_mask, image_shape)
        self._hair_mask = self._validate_mask(hair_mask, image_shape)
        self._hands_mask = self._validate_mask(hands_mask, image_shape)
        self._torso_mask = self._validate_mask(torso_mask, image_shape)
        self._arms_mask = self._validate_mask(arms_mask, image_shape)
        self._hips_mask = self._validate_mask(hips_mask, image_shape)
        self._legs_mask = self._validate_mask(legs_mask, image_shape)
        self._feet_mask = self._validate_mask(feet_mask, image_shape)
        self._image_shape = image_shape
        
        # Pre-compute locked regions (immutable)
        self._locked_mask = self._compute_locked_mask()
        self._editable_mask = self._compute_editable_mask()
    
    @staticmethod
    def _validate_mask(mask: np.ndarray, image_shape: tuple) -> np.ndarray:
        """Validate and normalize mask to image shape."""
        if mask is None:
            return np.zeros(image_shape[:2], dtype=np.uint8)
        
        if len(mask.shape) == 3:
            mask = cv2.cvtColor(mask, cv2.COLOR_BGR2GRAY)
        
        if mask.shape != image_shape[:2]:
            mask = cv2.resize(mask, (image_shape[1], image_shape[0]), interpolation=cv2.INTER_NEAREST)
        
        # Binarize
        _, mask = cv2.threshold(mask, 127, 255, cv2.THRESH_BINARY)
        return mask.astype(np.uint8)
    
    def _compute_locked_mask(self) -> np.ndarray:
        """Compute combined locked regions (face, hair, hands)."""
        locked = cv2.bitwise_or(self._face_mask, self._hair_mask)
        locked = cv2.bitwise_or(locked, self._hands_mask)
        return locked
    
    def _compute_editable_mask(self) -> np.ndarray:
        """Compute editable regions (everything except locked)."""
        locked = self._locked_mask
        editable = cv2.bitwise_not(locked)
        return editable
    
    @property
    def face_mask(self) -> np.ndarray:
        """Face mask (read-only, locked)."""
        return self._face_mask.copy()
    
    @property
    def hair_mask(self) -> np.ndarray:
        """Hair mask (read-only, locked)."""
        return self._hair_mask.copy()
    
    @property
    def hands_mask(self) -> np.ndarray:
        """Hands mask (read-only, locked)."""
        return self._hands_mask.copy()
    
    @property
    def torso_mask(self) -> np.ndarray:
        """Torso mask (editable for tops)."""
        return self._torso_mask.copy()
    
    @property
    def arms_mask(self) -> np.ndarray:
        """Arms mask (editable for tops)."""
        return self._arms_mask.copy()
    
    @property
    def hips_mask(self) -> np.ndarray:
        """Hips mask (editable for pants)."""
        return self._hips_mask.copy()
    
    @property
    def legs_mask(self) -> np.ndarray:
        """Legs mask (editable for pants)."""
        return self._legs_mask.copy()
    
    @property
    def feet_mask(self) -> np.ndarray:
        """Feet mask (editable for shoes)."""
        return self._feet_mask.copy()
    
    @property
    def locked_mask(self) -> np.ndarray:
        """Combined locked regions (face, hair, hands)."""
        return self._locked_mask.copy()
    
    @property
    def editable_mask(self) -> np.ndarray:
        """Combined editable regions."""
        return self._editable_mask.copy()
    
    def get_allowed_regions(self, garment_type: str) -> np.ndarray:
        """
        Get allowed regions for a specific garment type.
        
        Args:
            garment_type: "top", "pants", "jacket", "shoes"
        
        Returns:
            Binary mask of allowed regions
        """
        if garment_type == "top":
            allowed = cv2.bitwise_or(self._torso_mask, self._arms_mask)
        elif garment_type == "pants":
            allowed = cv2.bitwise_or(self._hips_mask, self._legs_mask)
        elif garment_type == "jacket":
            # Jacket can cover torso and arms
            allowed = cv2.bitwise_or(self._torso_mask, self._arms_mask)
        elif garment_type == "shoes":
            allowed = self._feet_mask.copy()
        else:
            raise ValueError(f"Unknown garment type: {garment_type}")
        
        return allowed
    
    def get_forbidden_regions(self) -> np.ndarray:
        """Get forbidden regions (locked: face, hair, hands)."""
        return self._locked_mask.copy()
    
    def validate_garment_placement(
        self,
        garment_mask: np.ndarray,
        garment_type: str
    ) -> tuple[bool, float]:
        """
        Validate that garment mask only overlaps allowed regions.
        
        Returns:
            (is_valid, overlap_ratio)
        """
        allowed = self.get_allowed_regions(garment_type)
        forbidden = self.get_forbidden_regions()
        
        # Ensure same size
        if garment_mask.shape != allowed.shape:
            garment_mask = cv2.resize(
                garment_mask,
                (allowed.shape[1], allowed.shape[0]),
                interpolation=cv2.INTER_NEAREST
            )
        
        # Binarize garment mask
        if len(garment_mask.shape) == 3:
            garment_mask = cv2.cvtColor(garment_mask, cv2.COLOR_BGR2GRAY)
        _, garment_mask = cv2.threshold(garment_mask, 127, 255, cv2.THRESH_BINARY)
        
        # Check overlap with forbidden regions
        forbidden_overlap = cv2.bitwise_and(garment_mask, forbidden)
        overlap_pixels = np.sum(forbidden_overlap > 0)
        garment_pixels = np.sum(garment_mask > 0)
        
        if garment_pixels == 0:
            return False, 1.0  # Empty mask is invalid
        
        overlap_ratio = overlap_pixels / garment_pixels
        
        # Maximum 1% overlap with forbidden regions allowed (tolerance for edge cases)
        is_valid = overlap_ratio <= 0.01
        
        return is_valid, overlap_ratio
