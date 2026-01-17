"""
AI Clothing Recognition Pipeline
Performs background-aware segmentation, classification, and attribute extraction
"""
import cv2
import numpy as np
from typing import Dict, List, Optional, Tuple, Any
from PIL import Image
import torch
import torchvision.transforms as transforms
from pathlib import Path
import logging
from dataclasses import dataclass

import logging
logger = logging.getLogger(__name__)

try:
    from sklearn.cluster import KMeans
    SKLEARN_AVAILABLE = True
except ImportError:
    SKLEARN_AVAILABLE = False
    logger.warning("sklearn not available, using fallback color extraction")

logger = logging.getLogger(__name__)


@dataclass
class ClothingAttributes:
    """Structured clothing attributes"""
    category: str
    subcategory: Optional[str]
    colors: List[str]
    patterns: List[str]
    fit: Optional[str]  # loose, regular, tight, fitted
    occasion: List[str]  # casual, formal, party, etc.
    style: Optional[str]
    confidence: float
    metadata: Dict[str, Any]


@dataclass
class SegmentationResult:
    """Clothing segmentation result"""
    mask: np.ndarray
    bbox: Tuple[int, int, int, int]  # x, y, w, h
    confidence: float
    garment_type: str


class ImagePreprocessor:
    """OpenCV-based image preprocessing for clothing recognition"""
    
    def __init__(self, max_size: int = 1024):
        self.max_size = max_size
    
    def preprocess(self, image: np.ndarray) -> np.ndarray:
        """Preprocess image for recognition pipeline"""
        # Resize if too large
        h, w = image.shape[:2]
        if max(h, w) > self.max_size:
            scale = self.max_size / max(h, w)
            new_w = int(w * scale)
            new_h = int(h * scale)
            image = cv2.resize(image, (new_w, new_h), interpolation=cv2.INTER_AREA)
        
        # Enhance contrast
        lab = cv2.cvtColor(image, cv2.COLOR_BGR2LAB)
        l, a, b = cv2.split(lab)
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
        l = clahe.apply(l)
        image = cv2.merge([l, a, b])
        image = cv2.cvtColor(image, cv2.COLOR_LAB2BGR)
        
        return image
    
    def remove_background(self, image: np.ndarray) -> Tuple[np.ndarray, np.ndarray]:
        """Remove background using grabcut algorithm"""
        # Create mask
        mask = np.zeros(image.shape[:2], np.uint8)
        bgd_model = np.zeros((1, 65), np.float64)
        fgd_model = np.zeros((1, 65), np.float64)
        
        # Estimate foreground region (center 60% of image)
        h, w = image.shape[:2]
        rect = (int(w * 0.2), int(h * 0.2), int(w * 0.6), int(h * 0.6))
        
        cv2.grabCut(image, mask, rect, bgd_model, fgd_model, 5, cv2.GC_INIT_WITH_RECT)
        
        # Create binary mask
        mask2 = np.where((mask == 2) | (mask == 0), 0, 1).astype('uint8')
        
        # Apply mask
        result = image * mask2[:, :, np.newaxis]
        
        return result, mask2


class ClothingSegmentation:
    """YOLO + Human Parsing for clothing segmentation"""
    
    def __init__(self, device: str = "cpu"):
        self.device = device
        self.yolo_model = None
        self.parsing_model = None
        self._load_models()
    
    def _load_models(self):
        """Lazy load YOLO and parsing models"""
        try:
            # YOLO for object detection
            from ultralytics import YOLO
            self.yolo_model = YOLO('yolov8n-seg.pt')  # Nano model for speed
            self.yolo_model.to(self.device)
            logger.info("YOLO model loaded successfully")
        except ImportError:
            logger.warning("ultralytics not available, using fallback segmentation")
        
        # Human parsing model (simplified - would use SCHP or similar in production)
        # For now, use color-based segmentation as fallback
        logger.info("Using color-based segmentation fallback")
    
    def segment_clothing(
        self, 
        image: np.ndarray,
        garment_type: Optional[str] = None
    ) -> List[SegmentationResult]:
        """Segment clothing items from image"""
        results = []
        
        if self.yolo_model is not None:
            # Use YOLO for detection
            yolo_results = self.yolo_model(image, classes=[0])  # Person class
            for result in yolo_results:
                if result.masks is not None:
                    for mask, conf in zip(result.masks.data, result.boxes.conf):
                        # Convert mask to numpy
                        mask_np = mask.cpu().numpy()
                        mask_np = cv2.resize(mask_np, (image.shape[1], image.shape[0]))
                        
                        # Get bounding box
                        x1, y1, x2, y2 = result.boxes.xyxy[0].cpu().numpy()
                        bbox = (int(x1), int(y1), int(x2 - x1), int(y2 - y1))
                        
                        results.append(SegmentationResult(
                            mask=mask_np,
                            bbox=bbox,
                            confidence=float(conf),
                            garment_type=garment_type or "clothing"
                        ))
        
        # Fallback: use color-based segmentation
        if not results:
            results = self._fallback_segmentation(image, garment_type)
        
        return results
    
    def _fallback_segmentation(
        self, 
        image: np.ndarray,
        garment_type: Optional[str]
    ) -> List[SegmentationResult]:
        """Fallback segmentation using color and edge detection"""
        # Convert to HSV for better color segmentation
        hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)
        
        # Use grabcut for foreground extraction
        preprocessor = ImagePreprocessor()
        _, mask = preprocessor.remove_background(image)
        
        # Find contours
        contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        
        results = []
        for contour in contours:
            area = cv2.contourArea(contour)
            if area > 1000:  # Minimum area threshold
                x, y, w, h = cv2.boundingRect(contour)
                bbox = (x, y, w, h)
                
                # Create mask for this contour
                contour_mask = np.zeros(image.shape[:2], dtype=np.uint8)
                cv2.drawContours(contour_mask, [contour], -1, 255, -1)
                
                results.append(SegmentationResult(
                    mask=contour_mask,
                    bbox=bbox,
                    confidence=0.7,  # Lower confidence for fallback
                    garment_type=garment_type or "clothing"
                ))
        
        return results


class ClothingClassifier:
    """CLIP/ViT-based clothing classification"""
    
    # Fashion categories
    CATEGORIES = [
        "top", "shirt", "blouse", "t-shirt", "tank top", "sweater", "hoodie",
        "bottom", "pants", "jeans", "skirt", "shorts", "dress",
        "outerwear", "jacket", "coat", "blazer", "cardigan",
        "shoes", "sneakers", "boots", "heels", "sandals",
        "accessories", "bag", "hat", "jewelry", "watch"
    ]
    
    def __init__(self, device: str = "cpu"):
        self.device = device
        self.model = None
        self.preprocess = None
        self._load_model()
    
    def _load_model(self):
        """Load CLIP model for classification"""
        try:
            import clip
            self.model, self.preprocess = clip.load("ViT-B/32", device=self.device)
            logger.info("CLIP model loaded successfully")
        except ImportError:
            logger.warning("CLIP not available, using fallback classification")
            self.model = None
    
    def classify(
        self, 
        image: Image.Image,
        garment_type: Optional[str] = None
    ) -> Tuple[str, float]:
        """Classify clothing item"""
        if self.model is None:
            return self._fallback_classify(image, garment_type)
        
        # Prepare image
        image_tensor = self.preprocess(image).unsqueeze(0).to(self.device)
        
        # Prepare text prompts
        category_texts = [f"a photo of {cat}" for cat in self.CATEGORIES]
        text_tokens = clip.tokenize(category_texts).to(self.device)
        
        # Get predictions
        with torch.no_grad():
            image_features = self.model.encode_image(image_tensor)
            text_features = self.model.encode_text(text_tokens)
            
            # Normalize
            image_features = image_features / image_features.norm(dim=-1, keepdim=True)
            text_features = text_features / text_features.norm(dim=-1, keepdim=True)
            
            # Compute similarity
            logits = (100.0 * image_features @ text_features.T).softmax(dim=-1)
            probs = logits[0].cpu().numpy()
        
        # Get top prediction
        top_idx = np.argmax(probs)
        category = self.CATEGORIES[top_idx]
        confidence = float(probs[top_idx])
        
        return category, confidence
    
    def _fallback_classify(
        self, 
        image: Image.Image,
        garment_type: Optional[str]
    ) -> Tuple[str, float]:
        """Fallback classification using heuristics"""
        # Simple heuristic-based classification
        if garment_type:
            return garment_type.lower(), 0.7
        
        # Analyze image characteristics
        img_array = np.array(image)
        h, w = img_array.shape[:2]
        aspect_ratio = w / h
        
        # Heuristic rules
        if aspect_ratio > 1.2:
            return "top", 0.6
        elif aspect_ratio < 0.8:
            return "dress", 0.6
        else:
            return "clothing", 0.5


class AttributeExtractor:
    """Extract fashion attributes: color, pattern, fit, occasion"""
    
    def __init__(self):
        self.color_names = [
            "black", "white", "red", "blue", "green", "yellow",
            "pink", "purple", "orange", "brown", "gray", "navy",
            "beige", "cream", "maroon", "teal", "olive", "coral"
        ]
    
    def extract_attributes(
        self,
        image: np.ndarray,
        mask: np.ndarray,
        category: str
    ) -> ClothingAttributes:
        """Extract all fashion attributes"""
        # Extract colors
        colors = self._extract_colors(image, mask)
        
        # Extract patterns
        patterns = self._extract_patterns(image, mask)
        
        # Estimate fit
        fit = self._estimate_fit(image, mask, category)
        
        # Determine occasion
        occasion = self._determine_occasion(colors, patterns, category)
        
        # Determine style
        style = self._determine_style(colors, patterns, category)
        
        return ClothingAttributes(
            category=category,
            subcategory=None,
            colors=colors,
            patterns=patterns,
            fit=fit,
            occasion=occasion,
            style=style,
            confidence=0.8,  # Will be updated by confidence validator
            metadata={}
        )
    
    def _extract_colors(self, image: np.ndarray, mask: np.ndarray) -> List[str]:
        """Extract dominant colors"""
        # Apply mask
        masked_image = image.copy()
        masked_image[mask == 0] = [0, 0, 0]
        
        # Reshape for k-means
        pixels = masked_image.reshape(-1, 3)
        pixels = pixels[pixels.sum(axis=1) > 0]  # Remove black pixels
        
        if len(pixels) == 0:
            return ["unknown"]
        
        # K-means clustering for dominant colors
        if SKLEARN_AVAILABLE:
            kmeans = KMeans(n_clusters=min(3, len(pixels)), random_state=42, n_init=10)
            kmeans.fit(pixels)
            
            # Get dominant colors
            colors = []
            for center in kmeans.cluster_centers_:
                color_name = self._rgb_to_color_name(center)
                if color_name not in colors:
                    colors.append(color_name)
            
            return colors[:3]  # Top 3 colors
        else:
            # Fallback: simple histogram-based color extraction
            colors = []
            for channel in range(3):
                hist = np.histogram(pixels[:, channel], bins=10)[0]
                dominant_bin = np.argmax(hist)
                color_value = dominant_bin * 25.5  # Approximate RGB value
                rgb = np.array([color_value, color_value, color_value])
                rgb[channel] = color_value
                color_name = self._rgb_to_color_name(rgb)
                if color_name not in colors:
                    colors.append(color_name)
            return colors[:3] if colors else ["unknown"]
    
    def _rgb_to_color_name(self, rgb: np.ndarray) -> str:
        """Convert RGB to color name"""
        # Convert to HSV for better color matching
        rgb_uint8 = np.uint8([[rgb]])
        hsv = cv2.cvtColor(rgb_uint8, cv2.COLOR_RGB2HSV)[0][0]
        
        h, s, v = hsv
        
        # Color matching logic
        if v < 30:
            return "black"
        elif v > 230 and s < 30:
            return "white"
        elif s < 50:
            return "gray" if v < 180 else "white"
        elif h < 10 or h > 170:
            return "red"
        elif 10 <= h < 25:
            return "orange"
        elif 25 <= h < 35:
            return "yellow"
        elif 35 <= h < 70:
            return "green"
        elif 70 <= h < 100:
            return "teal"
        elif 100 <= h < 130:
            return "blue"
        elif 130 <= h < 150:
            return "purple"
        elif 150 <= h < 170:
            return "pink"
        else:
            return "unknown"
    
    def _extract_patterns(self, image: np.ndarray, mask: np.ndarray) -> List[str]:
        """Detect patterns (stripes, dots, floral, etc.)"""
        patterns = []
        
        # Apply mask
        masked_image = image.copy()
        masked_image[mask == 0] = [0, 0, 0]
        
        # Convert to grayscale
        gray = cv2.cvtColor(masked_image, cv2.COLOR_BGR2GRAY)
        gray = gray[gray > 0]  # Remove masked areas
        
        if len(gray) == 0:
            return ["solid"]
        
        # Detect stripes using FFT
        fft = np.fft.fft2(gray.reshape(masked_image.shape[:2]))
        fft_shift = np.fft.fftshift(fft)
        magnitude = np.abs(fft_shift)
        
        # Check for horizontal/vertical patterns
        h, w = magnitude.shape
        horizontal_energy = np.sum(magnitude[h//2-5:h//2+5, :])
        vertical_energy = np.sum(magnitude[:, w//2-5:w//2+5])
        
        if horizontal_energy > vertical_energy * 1.5:
            patterns.append("stripes")
        elif vertical_energy > horizontal_energy * 1.5:
            patterns.append("stripes")
        
        # Detect dots using blob detection
        gray_full = cv2.cvtColor(masked_image, cv2.COLOR_BGR2GRAY)
        params = cv2.SimpleBlobDetector_Params()
        params.filterByArea = True
        params.minArea = 10
        detector = cv2.SimpleBlobDetector_create(params)
        keypoints = detector.detect(gray_full)
        
        if len(keypoints) > 20:
            patterns.append("dots")
        
        # Detect floral (complex pattern)
        laplacian_var = cv2.Laplacian(gray_full, cv2.CV_64F).var()
        if laplacian_var > 100 and len(patterns) == 0:
            patterns.append("floral")
        
        if not patterns:
            patterns.append("solid")
        
        return patterns
    
    def _estimate_fit(
        self, 
        image: np.ndarray, 
        mask: np.ndarray,
        category: str
    ) -> Optional[str]:
        """Estimate clothing fit"""
        # This is a simplified estimation
        # In production, would use more sophisticated analysis
        
        # Calculate area ratio
        total_area = image.shape[0] * image.shape[1]
        clothing_area = np.sum(mask > 0)
        ratio = clothing_area / total_area
        
        if category in ["dress", "top", "shirt"]:
            if ratio > 0.4:
                return "loose"
            elif ratio < 0.2:
                return "tight"
            else:
                return "regular"
        
        return "regular"
    
    def _determine_occasion(
        self,
        colors: List[str],
        patterns: List[str],
        category: str
    ) -> List[str]:
        """Determine suitable occasions"""
        occasions = []
        
        # Formal indicators
        if "black" in colors or "navy" in colors:
            if "solid" in patterns:
                occasions.append("formal")
        
        # Casual indicators
        if "t-shirt" in category or "jeans" in category:
            occasions.append("casual")
        
        # Party indicators
        if any(c in colors for c in ["red", "pink", "purple"]):
            if "dress" in category:
                occasions.append("party")
        
        # Default to casual if no specific occasion
        if not occasions:
            occasions.append("casual")
        
        return occasions
    
    def _determine_style(
        self,
        colors: List[str],
        patterns: List[str],
        category: str
    ) -> Optional[str]:
        """Determine style"""
        if "vintage" in patterns or any(c in colors for c in ["brown", "beige", "olive"]):
            return "vintage"
        elif "minimalist" in patterns or len(colors) == 1:
            return "minimalist"
        elif "floral" in patterns:
            return "bohemian"
        else:
            return "modern"


class ConfidenceValidator:
    """Validate confidence scores and implement retry logic"""
    
    def __init__(
        self,
        min_confidence: float = 0.6,
        max_retries: int = 3,
        retry_delay: float = 1.0
    ):
        self.min_confidence = min_confidence
        self.max_retries = max_retries
        self.retry_delay = retry_delay
    
    def validate(
        self,
        attributes: ClothingAttributes,
        retry_count: int = 0
    ) -> Tuple[bool, ClothingAttributes]:
        """Validate confidence and retry if needed"""
        if attributes.confidence >= self.min_confidence:
            return True, attributes
        
        if retry_count >= self.max_retries:
            # Return with lower confidence but mark as validated
            attributes.confidence = max(attributes.confidence, 0.5)
            return False, attributes
        
        # Mark for retry
        return False, attributes
    
    def should_retry(self, confidence: float, retry_count: int) -> bool:
        """Check if should retry"""
        return confidence < self.min_confidence and retry_count < self.max_retries


class ClothingRecognitionPipeline:
    """Complete clothing recognition pipeline"""
    
    def __init__(
        self,
        device: str = "cpu",
        min_confidence: float = 0.6,
        max_retries: int = 3
    ):
        self.device = device
        self.preprocessor = ImagePreprocessor()
        self.segmenter = ClothingSegmentation(device=device)
        self.classifier = ClothingClassifier(device=device)
        self.attribute_extractor = AttributeExtractor()
        self.validator = ConfidenceValidator(
            min_confidence=min_confidence,
            max_retries=max_retries
        )
    
    def process(
        self,
        image_path: str,
        retry_count: int = 0
    ) -> Dict[str, Any]:
        """Process clothing image through full pipeline"""
        try:
            # Load and preprocess image
            image = cv2.imread(image_path)
            if image is None:
                raise ValueError(f"Could not load image: {image_path}")
            
            preprocessed = self.preprocessor.preprocess(image)
            
            # Segment clothing
            segments = self.segmenter.segment_clothing(preprocessed)
            if not segments:
                raise ValueError("No clothing detected in image")
            
            # Use largest segment
            main_segment = max(segments, key=lambda s: np.sum(s.mask > 0))
            
            # Extract clothing region
            x, y, w, h = main_segment.bbox
            clothing_region = preprocessed[y:y+h, x:x+w]
            clothing_mask = main_segment.mask[y:y+h, x:x+w]
            
            # Classify
            pil_image = Image.fromarray(cv2.cvtColor(clothing_region, cv2.COLOR_BGR2RGB))
            category, class_confidence = self.classifier.classify(pil_image)
            
            # Extract attributes
            attributes = self.attribute_extractor.extract_attributes(
                clothing_region,
                clothing_mask,
                category
            )
            attributes.confidence = class_confidence
            
            # Validate confidence
            is_valid, validated_attributes = self.validator.validate(
                attributes,
                retry_count
            )
            
            if not is_valid and self.validator.should_retry(
                validated_attributes.confidence,
                retry_count
            ):
                # Retry with different preprocessing
                import time
                time.sleep(self.validator.retry_delay)
                return self.process(image_path, retry_count + 1)
            
            # Prepare result
            result = {
                "category": validated_attributes.category,
                "subcategory": validated_attributes.subcategory,
                "colors": validated_attributes.colors,
                "patterns": validated_attributes.patterns,
                "fit": validated_attributes.fit,
                "occasion": validated_attributes.occasion,
                "style": validated_attributes.style,
                "confidence": validated_attributes.confidence,
                "bbox": main_segment.bbox,
                "metadata": {
                    **validated_attributes.metadata,
                    "retry_count": retry_count,
                    "segmentation_confidence": main_segment.confidence
                }
            }
            
            return result
            
        except Exception as e:
            logger.error(f"Error in clothing recognition pipeline: {e}", exc_info=True)
            raise

