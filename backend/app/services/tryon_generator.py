"""
Try-On Generation Service
Generates virtual try-on results using mask constraints and generative models
"""
import cv2
import numpy as np
import logging
from typing import Dict, List, Optional, Tuple, Any
from PIL import Image
import torch

from ..core.config import settings

logger = logging.getLogger(__name__)


class TryOnGenerator:
    """
    Try-on generator that applies garments to user images with mask constraints
    Uses warp + diffusion or hybrid approaches
    """
    
    def __init__(self, use_gpu: Optional[bool] = None):
        self.use_gpu = use_gpu if use_gpu is not None else settings.USE_GPU
        self.device = torch.device("cuda" if (self.use_gpu and torch.cuda.is_available()) else "cpu")
        
        # Lazy-load models
        self.diffusion_pipeline = None
        self.controlnet = None
        
        logger.info(f"Try-on generator initialized (device: {self.device})")
    
    async def generate(
        self,
        user_image: np.ndarray,
        garment_image: np.ndarray,
        body_parsing: Dict[str, Any],
        garment_classification: Dict[str, Any],
    ) -> Dict[str, Any]:
        """
        Generate try-on result
        
        Args:
            user_image: User photo (BGR format)
            garment_image: Garment image (BGR format)
            body_parsing: Body parsing results with masks
            garment_classification: Garment classification from OpenRouter
        
        Returns:
            Dictionary with:
            - result_image: np.ndarray - final try-on result
            - quality_scores: Dict[str, float] - quality metrics
            - metadata: Dict[str, Any] - additional metadata
        """
        try:
            # Validate confidence
            confidence = garment_classification.get("confidence", 0.0)
            if confidence < settings.MIN_GARMENT_CONFIDENCE:
                raise ValueError(
                    f"Garment confidence {confidence} below threshold {settings.MIN_GARMENT_CONFIDENCE}"
                )
            
            # Extract masks
            allowed_mask = body_parsing.get("allowed_mask")
            locked_mask = body_parsing.get("locked_mask")
            
            if allowed_mask is None or np.sum(allowed_mask) == 0:
                raise ValueError("Allowed mask is empty - cannot proceed with try-on")
            
            # Step 1: Extract garment mask and prepare garment
            garment_mask = self._extract_garment_mask(garment_image)
            prepared_garment = self._prepare_garment(garment_image, garment_mask)
            
            # Step 2: Warp garment to fit user pose
            warped_garment = self._warp_garment(
                prepared_garment,
                user_image,
                body_parsing.get("pose_keypoints"),
                allowed_mask
            )
            
            # Step 3: Apply garment with mask constraints
            result_image = self._apply_garment_with_masks(
                user_image,
                warped_garment,
                allowed_mask,
                locked_mask
            )
            
            # Step 4: Refine with diffusion (if enabled)
            if settings.USE_GPU and torch.cuda.is_available():
                try:
                    result_image = await self._refine_with_diffusion(
                        result_image,
                        user_image,
                        garment_image,
                        allowed_mask,
                        locked_mask,
                        body_parsing
                    )
                except Exception as e:
                    logger.warning(f"Diffusion refinement failed, using warped result: {e}")
            
            # Step 5: Quality check
            quality_scores = self._calculate_quality_scores(
                result_image,
                user_image,
                allowed_mask,
                locked_mask
            )
            
            # Step 6: Post-process
            result_image = self._post_process(result_image, user_image, locked_mask)
            
            return {
                "result_image": result_image,
                "quality_scores": quality_scores,
                "metadata": {
                    "garment_type": garment_classification.get("garment_type"),
                    "target_body_part": garment_classification.get("target_body_part"),
                    "confidence": confidence,
                    "method": "warp+diffusion" if self.diffusion_pipeline else "warp",
                    "mask_coverage": float(np.sum(allowed_mask > 0) / allowed_mask.size)
                }
            }
            
        except Exception as e:
            logger.error(f"Try-on generation error: {e}", exc_info=True)
            raise
    
    def _extract_garment_mask(self, garment_image: np.ndarray) -> np.ndarray:
        """Extract garment from background"""
        # Use grabcut or background removal
        h, w = garment_image.shape[:2]
        
        # Simple background removal using color-based segmentation
        # In production, use a proper segmentation model
        gray = cv2.cvtColor(garment_image, cv2.COLOR_BGR2GRAY)
        
        # Threshold to get foreground
        _, mask = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
        
        # Refine mask
        kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
        mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel)
        mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, kernel)
        
        return mask
    
    def _prepare_garment(
        self,
        garment_image: np.ndarray,
        garment_mask: np.ndarray
    ) -> np.ndarray:
        """Prepare garment with alpha channel"""
        # Create RGBA image
        garment_rgba = cv2.cvtColor(garment_image, cv2.COLOR_BGR2BGRA)
        garment_rgba[:, :, 3] = garment_mask
        
        return garment_rgba
    
    def _warp_garment(
        self,
        garment: np.ndarray,
        user_image: np.ndarray,
        pose_keypoints: Optional[np.ndarray],
        target_mask: np.ndarray
    ) -> np.ndarray:
        """Warp garment to fit user pose and target region"""
        h, w = user_image.shape[:2]
        garment_h, garment_w = garment.shape[:2]
        
        # Get target region bounds
        y_coords, x_coords = np.where(target_mask > 0)
        if len(y_coords) == 0:
            # Fallback: center region
            x_min, x_max = w // 4, 3 * w // 4
            y_min, y_max = h // 4, 3 * h // 4
        else:
            x_min, x_max = int(np.min(x_coords)), int(np.max(x_coords))
            y_min, y_max = int(np.min(y_coords)), int(np.max(y_coords))
        
        target_width = x_max - x_min
        target_height = y_max - y_min
        
        # Resize garment to fit target region
        scale = min(target_width / garment_w, target_height / garment_h)
        new_w = int(garment_w * scale)
        new_h = int(garment_h * scale)
        
        garment_resized = cv2.resize(garment, (new_w, new_h), interpolation=cv2.INTER_LANCZOS4)
        
        # Create output image
        warped = np.zeros((h, w, 4), dtype=np.uint8)
        
        # Center garment in target region
        x_offset = x_min + (target_width - new_w) // 2
        y_offset = y_min + (target_height - new_h) // 2
        
        # Place garment
        y_end = min(h, y_offset + new_h)
        x_end = min(w, x_offset + new_w)
        y_start = max(0, y_offset)
        x_start = max(0, x_offset)
        
        src_y_start = max(0, -y_offset)
        src_x_start = max(0, -x_offset)
        src_y_end = src_y_start + (y_end - y_start)
        src_x_end = src_x_start + (x_end - x_start)
        
        if src_y_end > 0 and src_x_end > 0:
            warped[y_start:y_end, x_start:x_end] = garment_resized[
                src_y_start:src_y_end, src_x_start:src_x_end
            ]
        
        return warped
    
    def _apply_garment_with_masks(
        self,
        user_image: np.ndarray,
        garment: np.ndarray,
        allowed_mask: np.ndarray,
        locked_mask: np.ndarray
    ) -> np.ndarray:
        """Apply garment to user image respecting mask constraints"""
        result = user_image.copy().astype(np.float32)
        
        # Extract garment RGB and alpha
        garment_rgb = garment[:, :, :3].astype(np.float32)
        garment_alpha = garment[:, :, 3:4].astype(np.float32) / 255.0
        
        # Create composite mask (only apply where allowed and not locked)
        apply_mask = (allowed_mask > 0).astype(np.float32)
        apply_mask = apply_mask * (1.0 - (locked_mask > 0).astype(np.float32))
        apply_mask = apply_mask[:, :, np.newaxis]
        
        # Blend garment with user image
        final_alpha = garment_alpha * apply_mask
        result = result * (1.0 - final_alpha) + garment_rgb * final_alpha
        
        return result.astype(np.uint8)
    
    async def _refine_with_diffusion(
        self,
        current_result: np.ndarray,
        user_image: np.ndarray,
        garment_image: np.ndarray,
        allowed_mask: np.ndarray,
        locked_mask: np.ndarray,
        body_parsing: Dict[str, Any]
    ) -> np.ndarray:
        """
        Refine try-on result using diffusion model with ControlNet
        This is optional and requires diffusers library
        """
        try:
            # Lazy-load diffusion pipeline
            if self.diffusion_pipeline is None:
                from diffusers import StableDiffusionControlNetInpaintPipeline, ControlNetModel
                from diffusers.utils import load_image
                
                # Load ControlNet for inpainting
                controlnet = ControlNetModel.from_pretrained(
                    "lllyasviel/control_v11p_sd15_inpaint",
                    torch_dtype=torch.float16 if self.use_gpu else torch.float32
                )
                
                self.diffusion_pipeline = StableDiffusionControlNetInpaintPipeline.from_pretrained(
                    "runwayml/stable-diffusion-v1-5",
                    controlnet=controlnet,
                    torch_dtype=torch.float16 if self.use_gpu else torch.float32
                )
                self.diffusion_pipeline = self.diffusion_pipeline.to(self.device)
                self.diffusion_pipeline.enable_attention_slicing()
            
            # Convert to PIL
            result_pil = Image.fromarray(cv2.cvtColor(current_result, cv2.COLOR_BGR2RGB))
            user_pil = Image.fromarray(cv2.cvtColor(user_image, cv2.COLOR_BGR2RGB))
            garment_pil = Image.fromarray(cv2.cvtColor(garment_image, cv2.COLOR_BGR2RGB))
            
            # Create inpainting mask (allowed region)
            inpaint_mask = Image.fromarray(allowed_mask)
            
            # Generate prompt
            garment_type = body_parsing.get("metadata", {}).get("garment_type", "clothing")
            prompt = f"realistic {garment_type} on person, high quality, photorealistic"
            
            # Run diffusion
            refined = self.diffusion_pipeline(
                prompt=prompt,
                image=result_pil,
                mask_image=inpaint_mask,
                control_image=user_pil,
                num_inference_steps=20,
                strength=0.7,
                guidance_scale=7.5
            ).images[0]
            
            # Convert back to numpy
            refined_np = np.array(refined)
            refined_bgr = cv2.cvtColor(refined_np, cv2.COLOR_RGB2BGR)
            
            # Enforce locked mask
            locked_mask_3ch = np.stack([locked_mask] * 3, axis=2)
            refined_bgr = np.where(
                locked_mask_3ch > 0,
                user_image,
                refined_bgr
            ).astype(np.uint8)
            
            return refined_bgr
            
        except ImportError:
            logger.warning("Diffusers not available, skipping diffusion refinement")
            return current_result
        except Exception as e:
            logger.warning(f"Diffusion refinement failed: {e}")
            return current_result
    
    def _calculate_quality_scores(
        self,
        result_image: np.ndarray,
        original_image: np.ndarray,
        allowed_mask: np.ndarray,
        locked_mask: np.ndarray
    ) -> Dict[str, float]:
        """Calculate quality scores for the try-on result"""
        scores = {}
        
        # Check mask integrity (changes should only be in allowed region)
        diff = np.abs(result_image.astype(np.float32) - original_image.astype(np.float32))
        diff_magnitude = np.sqrt(np.sum(diff ** 2, axis=2))
        
        # Changes outside allowed mask should be minimal
        changes_outside = diff_magnitude[allowed_mask == 0]
        if len(changes_outside) > 0:
            max_change_outside = np.max(changes_outside)
            scores["mask_integrity"] = max(0.0, 1.0 - (max_change_outside / 255.0))
        else:
            scores["mask_integrity"] = 1.0
        
        # Check locked region preservation
        locked_region = original_image[locked_mask > 0]
        result_locked = result_image[locked_mask > 0]
        if len(locked_region) > 0:
            locked_diff = np.mean(np.abs(locked_region.astype(np.float32) - result_locked.astype(np.float32)))
            scores["locked_preservation"] = max(0.0, 1.0 - (locked_diff / 255.0))
        else:
            scores["locked_preservation"] = 1.0
        
        # Overall quality (average)
        scores["overall_quality"] = (scores["mask_integrity"] + scores["locked_preservation"]) / 2.0
        
        return scores
    
    def _post_process(
        self,
        result_image: np.ndarray,
        original_image: np.ndarray,
        locked_mask: np.ndarray
    ) -> np.ndarray:
        """Post-process result to ensure quality"""
        # Ensure locked regions are exactly preserved
        locked_mask_3ch = np.stack([locked_mask] * 3, axis=2)
        result_image = np.where(
            locked_mask_3ch > 128,
            original_image,
            result_image
        ).astype(np.uint8)
        
        # Optional: apply slight blur to blend edges
        # (commented out for now to preserve sharpness)
        # result_image = cv2.bilateralFilter(result_image, 5, 50, 50)
        
        return result_image
