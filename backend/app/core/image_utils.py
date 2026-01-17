"""
Image Validation & Normalization Utility
CRITICAL: Prevents OpenCV assertion errors by ensuring all images are valid before processing
"""
import cv2
import numpy as np
import logging
from typing import Tuple, Optional, Any
import httpx
import io
from PIL import Image

logger = logging.getLogger(__name__)


def validate_image(img: Optional[np.ndarray], name: str = "Image") -> None:
    """
    Hard validation layer - raises ValueError if image is invalid
    
    Args:
        img: Image array to validate
        name: Name for error messages
        
    Raises:
        ValueError: If image is None, empty, or has invalid shape
    """
    if img is None:
        raise ValueError(f"{name} is None - cannot process")
    
    if not isinstance(img, np.ndarray):
        raise ValueError(f"{name} is not a numpy array (got {type(img)})")
    
    if img.size == 0:
        raise ValueError(f"{name} is empty (size=0)")
    
    if len(img.shape) < 2:
        raise ValueError(f"{name} has invalid shape: {img.shape} (expected at least 2D)")
    
    if img.shape[0] == 0 or img.shape[1] == 0:
        raise ValueError(f"{name} has zero dimensions: {img.shape}")
    
    # Check for NaN or Inf values
    if np.any(np.isnan(img)) or np.any(np.isinf(img)):
        raise ValueError(f"{name} contains NaN or Inf values")


def normalize_image(img: np.ndarray, name: str = "Image") -> np.ndarray:
    """
    Force image format normalization for OpenCV compatibility
    
    Handles:
    - RGBA → RGB conversion (removes alpha channel)
    - uint8 conversion
    - Grayscale → BGR conversion (if needed)
    
    Args:
        img: Image array to normalize
        name: Name for logging
        
    Returns:
        Normalized image (BGR, uint8, 3 channels)
    """
    # Validate first
    validate_image(img, name)
    
    # Handle RGBA → RGB conversion
    if len(img.shape) == 3 and img.shape[2] == 4:
        # Extract alpha channel
        alpha = img[:, :, 3]
        rgb = img[:, :, :3]
        
        # If alpha is fully opaque, just use RGB
        if np.all(alpha == 255):
            img = rgb
        else:
            # Composite RGBA onto white background
            # Convert to float for proper alpha blending
            rgb_float = rgb.astype(np.float32) / 255.0
            alpha_float = alpha.astype(np.float32) / 255.0
            alpha_3d = np.stack([alpha_float] * 3, axis=2)
            
            # Composite: result = alpha * rgb + (1 - alpha) * white
            white = np.ones_like(rgb_float)
            img_float = alpha_3d * rgb_float + (1 - alpha_3d) * white
            
            # Convert back to uint8
            img = (img_float * 255.0).astype(np.uint8)
        
        logger.debug(f"{name}: Converted RGBA → RGB")
    
    # Ensure uint8 dtype
    if img.dtype != np.uint8:
        if img.dtype in [np.float32, np.float64]:
            # Assume 0-1 range, convert to 0-255
            if img.max() <= 1.0:
                img = (img * 255.0).astype(np.uint8)
            else:
                img = np.clip(img, 0, 255).astype(np.uint8)
        else:
            img = img.astype(np.uint8)
        logger.debug(f"{name}: Converted dtype to uint8")
    
    # Handle grayscale → BGR conversion
    if len(img.shape) == 2:
        img = cv2.cvtColor(img, cv2.COLOR_GRAY2BGR)
        logger.debug(f"{name}: Converted grayscale → BGR")
    elif len(img.shape) == 3 and img.shape[2] == 1:
        img = cv2.cvtColor(img, cv2.COLOR_GRAY2BGR)
        logger.debug(f"{name}: Converted single channel → BGR")
    
    # Ensure 3 channels (BGR)
    if len(img.shape) == 3 and img.shape[2] != 3:
        if img.shape[2] == 4:
            # Still has alpha? Remove it
            img = img[:, :, :3]
        else:
            raise ValueError(f"{name} has {img.shape[2]} channels, expected 3 (BGR)")
    
    # Final validation
    validate_image(img, f"{name} (normalized)")
    
    return img


def safe_calc_hist(
    images: list,
    channels: list,
    mask: Optional[np.ndarray] = None,
    histSize: list = [256],
    ranges: list = [0, 256]
) -> np.ndarray:
    """
    Safe wrapper for cv2.calcHist that validates inputs
    
    Args:
        images: List of images (must be non-empty)
        channels: List of channel indices
        mask: Optional mask
        histSize: Histogram size
        ranges: Value ranges
        
    Returns:
        Histogram array
        
    Raises:
        ValueError: If images list is empty or images are invalid
    """
    if not images or len(images) == 0:
        raise ValueError("No images provided to calcHist - cannot compute histogram")
    
    # Validate all images
    for i, img in enumerate(images):
        validate_image(img, f"Histogram image {i}")
    
    # Validate mask if provided
    if mask is not None:
        validate_image(mask, "Histogram mask")
        if len(mask.shape) == 3:
            # Convert to grayscale
            mask = cv2.cvtColor(mask, cv2.COLOR_BGR2GRAY)
    
    # Calculate histogram
    try:
        hist = cv2.calcHist(images, channels, mask, histSize, ranges)
        return hist
    except cv2.error as e:
        raise ValueError(f"OpenCV calcHist failed: {e}. Images shape: {[img.shape for img in images]}")


async def download_and_validate_image(
    url: str,
    timeout: int = 10,
    name: str = "Image"
) -> np.ndarray:
    """
    Download image from URL with full validation and normalization
    
    Args:
        url: Image URL
        timeout: Request timeout in seconds
        name: Name for error messages
        
    Returns:
        Validated and normalized image (BGR, uint8, 3 channels)
        
    Raises:
        ValueError: If download fails or image is invalid
        httpx.HTTPError: If HTTP request fails
    """
    try:
        async with httpx.AsyncClient(timeout=timeout) as client:
            response = await client.get(url)
            
            if response.status_code != 200:
                raise ValueError(f"Failed to download {name}: HTTP {response.status_code}")
            
            # Try multiple decoding methods
            image = None
            
            # Method 1: OpenCV imdecode (handles most formats)
            try:
                img_array = np.frombuffer(response.content, dtype=np.uint8)
                image = cv2.imdecode(img_array, cv2.IMREAD_UNCHANGED)
            except Exception as e:
                logger.debug(f"OpenCV decode failed for {name}: {e}")
            
            # Method 2: PIL fallback (handles RGBA PNGs better)
            if image is None:
                try:
                    pil_image = Image.open(io.BytesIO(response.content))
                    # Convert PIL to numpy
                    if pil_image.mode == 'RGBA':
                        # Keep alpha for processing
                        image = np.array(pil_image)
                    else:
                        # Convert to RGB then BGR
                        pil_image = pil_image.convert('RGB')
                        image = cv2.cvtColor(np.array(pil_image), cv2.COLOR_RGB2BGR)
                except Exception as e:
                    logger.debug(f"PIL decode failed for {name}: {e}")
            
            if image is None:
                raise ValueError(f"Failed to decode {name} from {url} - unsupported format")
            
            # Validate and normalize
            validate_image(image, name)
            image = normalize_image(image, name)
            
            logger.info(f"✅ Downloaded and validated {name}: shape={image.shape}, dtype={image.dtype}")
            return image
            
    except httpx.TimeoutException:
        raise ValueError(f"Timeout downloading {name} from {url}")
    except httpx.HTTPError as e:
        raise ValueError(f"HTTP error downloading {name}: {e}")
    except Exception as e:
        raise ValueError(f"Error downloading {name} from {url}: {e}")


def extract_alpha_channel(img: np.ndarray) -> Tuple[np.ndarray, Optional[np.ndarray]]:
    """
    Safely extract alpha channel from RGBA image
    
    Args:
        img: Image array (may be RGBA or RGB)
        
    Returns:
        (rgb_image, alpha_mask) where alpha_mask is None if no alpha channel
    """
    validate_image(img, "Alpha extraction input")
    
    if len(img.shape) == 3 and img.shape[2] == 4:
        rgb = img[:, :, :3]
        alpha = img[:, :, 3]
        return rgb, alpha
    else:
        return img, None


def ensure_non_empty_list(images: list, operation_name: str = "operation") -> None:
    """
    Validate that image list is non-empty before OpenCV operations
    
    Args:
        images: List of images
        operation_name: Name of operation for error message
        
    Raises:
        ValueError: If list is empty
    """
    if not images or len(images) == 0:
        raise ValueError(f"No valid images passed to {operation_name} - cannot proceed")
    
    # Validate each image
    for i, img in enumerate(images):
        validate_image(img, f"{operation_name} image {i}")


def convert_numpy_types(obj: Any) -> Any:
    """
    Recursively convert numpy types to native Python types for JSON serialization
    
    Args:
        obj: Object that may contain numpy types
        
    Returns:
        Object with all numpy types converted to Python native types
    """
    # Handle numpy bool types (numpy.bool_, numpy.bool)
    if isinstance(obj, (np.bool_, bool)) and type(obj).__module__ == 'numpy':
        return bool(obj)
    # Handle numpy integer types
    elif isinstance(obj, np.integer):
        return int(obj)
    # Handle numpy floating types
    elif isinstance(obj, np.floating):
        return float(obj)
    # Handle numpy arrays
    elif isinstance(obj, np.ndarray):
        return obj.tolist()
    # Handle dictionaries
    elif isinstance(obj, dict):
        return {key: convert_numpy_types(value) for key, value in obj.items()}
    # Handle lists and tuples
    elif isinstance(obj, (list, tuple)):
        return [convert_numpy_types(item) for item in obj]
    # Handle objects with __dict__ attribute (but not numpy types)
    elif hasattr(obj, '__dict__') and not isinstance(obj, (np.generic, np.ndarray)):
        try:
            return {key: convert_numpy_types(value) for key, value in obj.__dict__.items()}
        except (TypeError, AttributeError):
            return str(obj)
    else:
        return obj
