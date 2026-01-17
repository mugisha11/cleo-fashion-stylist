"""
Clothing Feature Extraction Service
Extracts embeddings and metadata from wardrobe clothing items
Stores in Supabase for intelligent matching and recommendations
"""
import cv2
import numpy as np
import torch
import torchvision.transforms as transforms
from typing import Dict, List, Optional, Tuple
import logging
from PIL import Image

logger = logging.getLogger(__name__)

# Try to import pre-trained models
try:
    import torchvision.models as models
    TORCHVISION_AVAILABLE = True
except ImportError:
    TORCHVISION_AVAILABLE = False
    logger.warning("torchvision not available - using fallback feature extraction")


class ClothingFeatureExtractor:
    """
    Extracts comprehensive features from clothing images:
    - Visual embeddings (ResNet/EfficientNet)
    - Category classification
    - Fabric type
    - Fit type
    - Color palette
    - Texture patterns
    """
    
    def __init__(self, use_gpu: bool = True):
        self.use_gpu = use_gpu and torch.cuda.is_available()
        self.device = torch.device('cuda' if self.use_gpu else 'cpu')
        self.model = None
        self._load_model()
        
        # Image preprocessing
        self.transform = transforms.Compose([
            transforms.Resize((224, 224)),
            transforms.ToTensor(),
            transforms.Normalize(
                mean=[0.485, 0.456, 0.406],
                std=[0.229, 0.224, 0.225]
            )
        ])
    
    def _load_model(self):
        """Load pre-trained ResNet for feature extraction"""
        try:
            if TORCHVISION_AVAILABLE:
                # Use ResNet50 as feature extractor
                self.model = models.resnet50(pretrained=True)
                # Remove final classification layer
                self.model = torch.nn.Sequential(*list(self.model.children())[:-1])
                self.model.eval()
                self.model.to(self.device)
                logger.info("ResNet50 feature extractor loaded")
            else:
                logger.warning("Using fallback feature extraction")
        except Exception as e:
            logger.warning(f"Could not load ResNet: {e}, using fallback")
    
    def extract_features(
        self,
        clothing_image: np.ndarray,
        clothing_mask: Optional[np.ndarray] = None
    ) -> Dict:
        """
        Extract comprehensive features from clothing image
        
        Returns:
            Dictionary with embeddings, category, colors, etc.
        """
        try:
            # Preprocess image
            if clothing_mask is not None:
                # Remove background using mask
                clothing_image = self._apply_mask(clothing_image, clothing_mask)
            
            # Extract visual embedding
            embedding = self._extract_embedding(clothing_image)
            
            # Extract color palette
            colors = self._extract_color_palette(clothing_image)
            
            # Classify category
            category = self._classify_category(clothing_image, embedding)
            
            # Detect fabric/texture
            fabric = self._detect_fabric(clothing_image)
            
            # Estimate fit
            fit = self._estimate_fit(clothing_image, embedding)
            
            # Extract length/style
            length = self._estimate_length(clothing_image)
            
            return {
                'embedding': embedding.tolist() if isinstance(embedding, np.ndarray) else embedding,
                'category': category,
                'subcategory': category.get('subcategory'),
                'colors': colors,
                'fabric': fabric,
                'fit': fit,
                'length': length,
                'texture': self._analyze_texture(clothing_image),
                'metadata': {
                    'image_shape': clothing_image.shape,
                    'extraction_method': 'resnet50' if self.model else 'fallback'
                }
            }
            
        except Exception as e:
            logger.error(f"Feature extraction error: {e}")
            return self._fallback_extraction(clothing_image)
    
    def _extract_embedding(self, image: np.ndarray) -> np.ndarray:
        """Extract deep learning embedding"""
        if self.model is None:
            # Fallback: Use simple histogram-based features
            return self._histogram_features(image)
        
        try:
            # Preprocess
            pil_image = Image.fromarray(cv2.cvtColor(image, cv2.COLOR_BGR2RGB))
            input_tensor = self.transform(pil_image).unsqueeze(0).to(self.device)
            
            # Extract features
            with torch.no_grad():
                features = self.model(input_tensor)
                features = features.squeeze().cpu().numpy()
            
            return features
        except Exception as e:
            logger.error(f"Embedding extraction error: {e}")
            return self._histogram_features(image)
    
    def _histogram_features(self, image: np.ndarray) -> np.ndarray:
        """Fallback: histogram-based features"""
        # Color histogram
        hist_b = cv2.calcHist([image], [0], None, [32], [0, 256])
        hist_g = cv2.calcHist([image], [1], None, [32], [0, 256])
        hist_r = cv2.calcHist([image], [2], None, [32], [0, 256])
        
        # Texture features (gradient histogram)
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        grad_x = cv2.Sobel(gray, cv2.CV_64F, 1, 0, ksize=3)
        grad_y = cv2.Sobel(gray, cv2.CV_64F, 0, 1, ksize=3)
        grad_mag = np.sqrt(grad_x**2 + grad_y**2)
        texture_hist = np.histogram(grad_mag, bins=32)[0]
        
        # Combine features
        features = np.concatenate([
            hist_b.flatten(),
            hist_g.flatten(),
            hist_r.flatten(),
            texture_hist
        ])
        
        # Normalize
        features = features / (np.linalg.norm(features) + 1e-7)
        
        return features
    
    def _extract_color_palette(self, image: np.ndarray, n_colors: int = 5) -> List[Dict]:
        """Extract dominant colors using K-means clustering"""
        # Reshape image to list of pixels
        pixels = image.reshape(-1, 3)
        
        # Use K-means to find dominant colors
        try:
            from sklearn.cluster import KMeans
            kmeans = KMeans(n_clusters=n_colors, random_state=42, n_init=10)
            kmeans.fit(pixels)
            colors = kmeans.cluster_centers_.astype(int)
            
            # Get color frequencies
            labels = kmeans.labels_
            frequencies = [np.sum(labels == i) / len(labels) for i in range(n_colors)]
            
            # Sort by frequency
            sorted_indices = np.argsort(frequencies)[::-1]
            colors = colors[sorted_indices]
            frequencies = [frequencies[i] for i in sorted_indices]
            
        except ImportError:
            # Fallback: Use simple color quantization
            colors = []
            frequencies = []
            # Sample random pixels
            sample_size = min(1000, len(pixels))
            sample_pixels = pixels[np.random.choice(len(pixels), sample_size, replace=False)]
            
            # Simple clustering by color distance
            for _ in range(n_colors):
                if len(sample_pixels) == 0:
                    break
                # Find most common color
                unique_colors, counts = np.unique(sample_pixels, axis=0, return_counts=True)
                most_common_idx = np.argmax(counts)
                colors.append(unique_colors[most_common_idx])
                frequencies.append(counts[most_common_idx] / len(sample_pixels))
                # Remove similar colors
                sample_pixels = sample_pixels[
                    np.linalg.norm(sample_pixels - unique_colors[most_common_idx], axis=1) > 30
                ]
        
        # Format as RGB hex codes
        color_palette = []
        for color, freq in zip(colors, frequencies):
            r, g, b = int(color[2]), int(color[1]), int(color[0])  # BGR to RGB
            hex_color = f"#{r:02x}{g:02x}{b:02x}"
            color_palette.append({
                'rgb': [int(r), int(g), int(b)],
                'hex': hex_color,
                'frequency': float(freq)
            })
        
        return color_palette
    
    def _classify_category(
        self,
        image: np.ndarray,
        embedding: Optional[np.ndarray] = None
    ) -> Dict:
        """Classify clothing category"""
        h, w = image.shape[:2]
        aspect_ratio = w / h
        
        # Simple rule-based classification (can be enhanced with ML model)
        if aspect_ratio > 1.2:
            # Wide image - likely full outfit or horizontal item
            category = 'dress' if h > w * 0.8 else 'top'
        elif aspect_ratio < 0.8:
            # Tall image - likely full body or vertical item
            category = 'full_body'
        else:
            # Square-ish - analyze content
            # Check if it's upper or lower body
            # Simple heuristic: check color distribution
            upper_half = image[:h//2, :]
            lower_half = image[h//2:, :]
            
            upper_colors = np.mean(upper_half, axis=(0, 1))
            lower_colors = np.mean(lower_half, axis=(0, 1))
            
            if np.linalg.norm(upper_colors - lower_colors) < 20:
                category = 'dress'  # Similar colors = likely dress
            else:
                category = 'top'  # Different colors = likely top
        
        # Subcategories
        subcategories = {
            'top': ['t-shirt', 'shirt', 'blouse', 'sweater', 'jacket'],
            'bottom': ['pants', 'jeans', 'skirt', 'shorts'],
            'dress': ['casual', 'formal', 'maxi', 'mini'],
            'full_body': ['jumpsuit', 'romper', 'overall']
        }
        
        return {
            'main': category,
            'subcategory': subcategories.get(category, ['unknown'])[0],
            'confidence': 0.7  # Placeholder
        }
    
    def _detect_fabric(self, image: np.ndarray) -> str:
        """Detect fabric type from texture"""
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        
        # Calculate texture features
        # Use Local Binary Pattern (LBP) or gradient statistics
        grad_x = cv2.Sobel(gray, cv2.CV_64F, 1, 0, ksize=3)
        grad_y = cv2.Sobel(gray, cv2.CV_64F, 0, 1, ksize=3)
        grad_mag = np.sqrt(grad_x**2 + grad_y**2)
        
        texture_variance = np.var(grad_mag)
        
        # Simple classification
        if texture_variance < 100:
            return 'smooth'  # Cotton, silk
        elif texture_variance < 500:
            return 'medium'  # Denim, linen
        else:
            return 'rough'  # Wool, knit
    
    def _estimate_fit(self, image: np.ndarray, embedding: Optional[np.ndarray]) -> str:
        """Estimate fit type (loose, regular, tight, fitted)"""
        # Analyze silhouette and shape
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        
        # Detect edges
        edges = cv2.Canny(gray, 50, 150)
        
        # Calculate edge density (more edges = more fitted/tailored)
        edge_density = np.sum(edges > 0) / edges.size
        
        if edge_density > 0.3:
            return 'fitted'
        elif edge_density > 0.15:
            return 'regular'
        else:
            return 'loose'
    
    def _estimate_length(self, image: np.ndarray) -> str:
        """Estimate length (short, medium, long)"""
        h, w = image.shape[:2]
        
        # Simple heuristic based on aspect ratio
        if h > w * 1.5:
            return 'long'
        elif h < w * 0.8:
            return 'short'
        else:
            return 'medium'
    
    def _analyze_texture(self, image: np.ndarray) -> Dict:
        """Analyze texture patterns"""
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        
        # Calculate texture statistics
        grad_x = cv2.Sobel(gray, cv2.CV_64F, 1, 0, ksize=3)
        grad_y = cv2.Sobel(gray, cv2.CV_64F, 0, 1, ksize=3)
        grad_mag = np.sqrt(grad_x**2 + grad_y**2)
        
        return {
            'roughness': float(np.mean(grad_mag)),
            'variance': float(np.var(grad_mag)),
            'pattern': 'solid' if np.var(grad_mag) < 100 else 'patterned'
        }
    
    def _apply_mask(self, image: np.ndarray, mask: np.ndarray) -> np.ndarray:
        """Apply mask to remove background"""
        masked = image.copy()
        masked[mask == 0] = [255, 255, 255]  # White background
        return masked
    
    def _fallback_extraction(self, image: np.ndarray) -> Dict:
        """Fallback feature extraction when model unavailable"""
        return {
            'embedding': self._histogram_features(image).tolist(),
            'category': {'main': 'unknown', 'subcategory': 'unknown', 'confidence': 0.5},
            'colors': self._extract_color_palette(image),
            'fabric': 'unknown',
            'fit': 'regular',
            'length': 'medium',
            'texture': {'roughness': 0.0, 'variance': 0.0, 'pattern': 'unknown'},
            'metadata': {'extraction_method': 'fallback'}
        }
