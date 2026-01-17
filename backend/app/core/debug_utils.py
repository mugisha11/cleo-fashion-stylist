"""
Debug Visualization Utilities
Saves intermediate pipeline stages for debugging
"""
import cv2
import numpy as np
import os
from pathlib import Path
from typing import Optional, Dict
import logging

logger = logging.getLogger(__name__)

DEBUG_DIR = Path("debug")
DEBUG_ENABLED = os.getenv("VTON_DEBUG", "false").lower() == "true"


def ensure_debug_dir():
    """Ensure debug directory exists"""
    if DEBUG_ENABLED:
        DEBUG_DIR.mkdir(exist_ok=True)


def save_debug_image(
    image: np.ndarray,
    filename: str,
    stage: str = "unknown",
    metadata: Optional[Dict] = None
):
    """
    Save debug image with metadata
    
    Args:
        image: Image to save
        filename: Filename (without extension)
        stage: Pipeline stage name
        metadata: Optional metadata dict
    """
    if not DEBUG_ENABLED:
        return
    
    try:
        ensure_debug_dir()
        
        # Validate image
        if image is None or image.size == 0:
            logger.warning(f"Debug: Cannot save empty image: {filename}")
            return
        
        # Save image
        filepath = DEBUG_DIR / f"{stage}_{filename}.png"
        cv2.imwrite(str(filepath), image)
        
        # Save metadata if provided
        if metadata:
            import json
            metapath = DEBUG_DIR / f"{stage}_{filename}_meta.json"
            with open(metapath, 'w') as f:
                json.dump(metadata, f, indent=2, default=str)
        
        logger.debug(f"Debug image saved: {filepath}")
    except Exception as e:
        logger.warning(f"Failed to save debug image {filename}: {e}")


def save_pipeline_stage(
    stage_name: str,
    original_image: Optional[np.ndarray] = None,
    result_image: Optional[np.ndarray] = None,
    mask: Optional[np.ndarray] = None,
    metadata: Optional[Dict] = None
):
    """
    Save complete pipeline stage with all components
    
    Args:
        stage_name: Name of pipeline stage
        original_image: Original input image
        result_image: Processed result image
        mask: Optional mask
        metadata: Optional metadata
    """
    if not DEBUG_ENABLED:
        return
    
    try:
        ensure_debug_dir()
        
        if original_image is not None:
            save_debug_image(original_image, f"{stage_name}_original", stage_name)
        
        if result_image is not None:
            save_debug_image(result_image, f"{stage_name}_result", stage_name)
        
        if mask is not None:
            save_debug_image(mask, f"{stage_name}_mask", stage_name)
        
        if metadata:
            import json
            metapath = DEBUG_DIR / f"{stage_name}_metadata.json"
            with open(metapath, 'w') as f:
                json.dump(metadata, f, indent=2, default=str)
        
    except Exception as e:
        logger.warning(f"Failed to save pipeline stage {stage_name}: {e}")


def save_semantic_pipeline_stage(
    stage_name: str,
    image: Optional[np.ndarray] = None,
    body_parts: Optional[Dict[str, np.ndarray]] = None,
    allowed_region_mask: Optional[np.ndarray] = None,
    clothing_type: Optional[str] = None,
    metadata: Optional[Dict] = None
):
    """
    Save semantic pipeline stage with body parts visualization
    
    Args:
        stage_name: Name of pipeline stage
        image: Base image
        body_parts: Dictionary of body part masks
        allowed_region_mask: Combined allowed region mask
        clothing_type: Type of clothing being applied
        metadata: Optional metadata
    """
    if not DEBUG_ENABLED:
        return
    
    try:
        ensure_debug_dir()
        
        if image is not None:
            save_debug_image(image, f"{stage_name}_image", stage_name)
        
        if allowed_region_mask is not None:
            save_debug_image(allowed_region_mask, f"{stage_name}_allowed_region", stage_name)
            
            # Create overlay visualization
            overlay = visualize_mask_overlay(image, allowed_region_mask, color=(0, 255, 0), alpha=0.5)
            save_debug_image(overlay, f"{stage_name}_overlay", stage_name)
        
        if body_parts:
            # Save each body part mask
            for part_name, part_mask in body_parts.items():
                save_debug_image(part_mask, f"{stage_name}_bodypart_{part_name}", stage_name)
        
        if metadata:
            import json
            metadata_to_save = metadata.copy()
            if clothing_type:
                metadata_to_save["clothing_type"] = clothing_type
            metapath = DEBUG_DIR / f"{stage_name}_metadata.json"
            with open(metapath, 'w') as f:
                json.dump(metadata_to_save, f, indent=2, default=str)
        
    except Exception as e:
        logger.warning(f"Failed to save semantic pipeline stage {stage_name}: {e}")


def visualize_mask_overlay(
    image: np.ndarray,
    mask: np.ndarray,
    color: tuple = (0, 255, 0),
    alpha: float = 0.5
) -> np.ndarray:
    """
    Visualize mask overlay on image
    
    Args:
        image: Base image
        mask: Binary mask
        color: Overlay color (BGR)
        alpha: Transparency
    
    Returns:
        Overlay visualization
    """
    if image is None or mask is None:
        return image
    
    # Resize mask if needed
    if mask.shape[:2] != image.shape[:2]:
        mask = cv2.resize(mask, (image.shape[1], image.shape[0]))
    
    # Create colored mask
    if len(mask.shape) == 2:
        mask_3ch = cv2.cvtColor(mask, cv2.COLOR_GRAY2BGR)
    else:
        mask_3ch = mask
    
    # Create overlay
    overlay = image.copy()
    mask_bool = (mask_3ch[:, :, 0] > 127).astype(np.uint8)
    overlay[mask_bool > 0] = color
    
    # Blend
    result = cv2.addWeighted(image, 1 - alpha, overlay, alpha, 0)
    return result
