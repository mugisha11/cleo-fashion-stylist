"""
Utility Functions for Production VTON Pipeline
"""
import base64
import io
from typing import Optional, Tuple
import numpy as np
from PIL import Image
import cv2


def image_to_base64(image: np.ndarray, format: str = "JPEG") -> str:
    """Convert numpy image to base64 string."""
    if len(image.shape) == 2:
        # Grayscale
        pil_image = Image.fromarray(image, mode="L")
    elif image.shape[2] == 3:
        # RGB
        pil_image = Image.fromarray(cv2.cvtColor(image, cv2.COLOR_BGR2RGB))
    elif image.shape[2] == 4:
        # RGBA
        pil_image = Image.fromarray(cv2.cvtColor(image, cv2.COLOR_BGRA2RGBA))
    else:
        raise ValueError(f"Unsupported image shape: {image.shape}")
    
    buffer = io.BytesIO()
    pil_image.save(buffer, format=format)
    img_bytes = buffer.getvalue()
    return base64.b64encode(img_bytes).decode("utf-8")


def base64_to_image(base64_str: str) -> np.ndarray:
    """Convert base64 string to numpy image (BGR format for OpenCV)."""
    # Handle data URL format
    if base64_str.startswith("data:"):
        base64_str = base64_str.split(",")[1]
    
    img_bytes = base64.b64decode(base64_str)
    pil_image = Image.open(io.BytesIO(img_bytes))
    
    # Convert to RGB then BGR for OpenCV
    if pil_image.mode != 'RGB':
        pil_image = pil_image.convert('RGB')
    
    rgb_array = np.array(pil_image)
    bgr_array = cv2.cvtColor(rgb_array, cv2.COLOR_RGB2BGR)
    return bgr_array


def load_image_from_path(path: str) -> np.ndarray:
    """Load image from file path."""
    image = cv2.imread(path)
    if image is None:
        raise ValueError(f"Could not load image from path: {path}")
    return image


def ensure_same_size(
    image1: np.ndarray,
    image2: np.ndarray,
    interpolation: int = cv2.INTER_LINEAR
) -> Tuple[np.ndarray, np.ndarray]:
    """Ensure two images have the same dimensions."""
    h1, w1 = image1.shape[:2]
    h2, w2 = image2.shape[:2]
    
    if (h1, w1) == (h2, w2):
        return image1, image2
    
    # Resize to match the larger dimensions
    target_h = max(h1, h2)
    target_w = max(w1, w2)
    
    if image1.shape[:2] != (target_h, target_w):
        image1 = cv2.resize(image1, (target_w, target_h), interpolation=interpolation)
    
    if image2.shape[:2] != (target_h, target_w):
        image2 = cv2.resize(image2, (target_w, target_h), interpolation=interpolation)
    
    return image1, image2


def validate_image(image: np.ndarray, min_size: int = 256, max_size: int = 4096) -> bool:
    """Validate image dimensions and format."""
    if image is None:
        return False
    
    if len(image.shape) < 2 or len(image.shape) > 3:
        return False
    
    h, w = image.shape[:2]
    
    if h < min_size or w < min_size:
        return False
    
    if h > max_size or w > max_size:
        return False
    
    return True


def normalize_image(image: np.ndarray) -> np.ndarray:
    """Normalize image to [0, 1] range."""
    if image.dtype == np.uint8:
        return image.astype(np.float32) / 255.0
    return image.astype(np.float32)


def denormalize_image(image: np.ndarray) -> np.ndarray:
    """Convert image from [0, 1] to [0, 255] uint8."""
    if image.dtype == np.float32 or image.dtype == np.float64:
        return np.clip(image * 255.0, 0, 255).astype(np.uint8)
    return image.astype(np.uint8)
