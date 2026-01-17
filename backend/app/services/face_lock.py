"""
Face Locking Service (CRITICAL)
Preserves user face, hair, and head region - NO MODIFICATIONS ALLOWED
"""
import cv2
import numpy as np
from typing import Tuple, Optional, Dict
import logging

# Optional: face_recognition for advanced face detection
try:
    import face_recognition
    FACE_RECOGNITION_AVAILABLE = True
except ImportError:
    FACE_RECOGNITION_AVAILABLE = False
    logging.warning("face_recognition not available - using OpenCV fallback")

try:
    from scipy.spatial.distance import euclidean
    SCIPY_AVAILABLE = True
except ImportError:
    SCIPY_AVAILABLE = False
    logging.warning("scipy not available - using numpy fallback for distance calculation")

logger = logging.getLogger(__name__)


class FaceLocker:
    """
    Critical service that ensures face is NEVER modified during VTON
    Face similarity must be ≥ 98% before/after
    """
    
    def __init__(self, similarity_threshold: float = 0.98):
        self.similarity_threshold = similarity_threshold
    
    def detect_face_region(self, image: np.ndarray) -> Optional[Tuple[int, int, int, int]]:
        """
        Detect face region (x, y, width, height)
        Returns None if no face detected
        """
        try:
            if FACE_RECOGNITION_AVAILABLE:
                # Use face_recognition if available
                rgb_image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
                face_locations = face_recognition.face_locations(rgb_image)
                
                if len(face_locations) == 0:
                    logger.warning("No face detected")
                    return None
                
                # Use first detected face
                top, right, bottom, left = face_locations[0]
            else:
                # Fallback: Use OpenCV Haar Cascade
                gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
                face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
                faces = face_cascade.detectMultiScale(gray, 1.1, 4)
                
                if len(faces) == 0:
                    logger.warning("No face detected")
                    return None
                
                # Use first detected face
                x, y, w, h = faces[0]
                left, top, right, bottom = x, y, x + w, y + h
            
            # Expand region to include hair and head
            h, w = image.shape[:2]
            face_height = bottom - top
            face_width = right - left
            
            # Expand by 50% to include hair
            expand_y = int(face_height * 0.5)
            expand_x = int(face_width * 0.3)
            
            x = max(0, left - expand_x)
            y = max(0, top - expand_y)
            width = min(w - x, right - left + 2 * expand_x)
            height = min(h - y, bottom - top + 2 * expand_y)
            
            return (x, y, width, height)
        except Exception as e:
            logger.error(f"Face detection error: {str(e)}")
            return None
    
    def create_protection_mask(
        self,
        image: np.ndarray,
        face_region: Optional[Tuple[int, int, int, int]] = None
    ) -> np.ndarray:
        """
        Create binary mask for protected regions (face + hair)
        White = protected, Black = can be modified
        """
        h, w = image.shape[:2]
        mask = np.zeros((h, w), dtype=np.uint8)
        
        if face_region is None:
            face_region = self.detect_face_region(image)
        
        if face_region:
            x, y, width, height = face_region
            # Create elliptical mask for more natural blending
            center_x = x + width // 2
            center_y = y + height // 2
            axes_x = width // 2
            axes_y = height // 2
            
            # Create ellipse
            cv2.ellipse(
                mask,
                (center_x, center_y),
                (axes_x, axes_y),
                0, 0, 360,
                255, -1
            )
            
            # Also include hair region above face
            hair_y_start = max(0, y - height // 2)
            hair_y_end = y
            hair_x_start = max(0, x - width // 4)
            hair_x_end = min(w, x + width + width // 4)
            mask[hair_y_start:hair_y_end, hair_x_start:hair_x_end] = 255
        
        return mask
    
    def extract_face_encoding(self, image: np.ndarray) -> Optional[np.ndarray]:
        """Extract face encoding for similarity comparison"""
        try:
            if FACE_RECOGNITION_AVAILABLE:
                rgb_image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
                face_locations = face_recognition.face_locations(rgb_image)
                
                if len(face_locations) == 0:
                    return None
                
                encodings = face_recognition.face_encodings(rgb_image, face_locations)
                return encodings[0] if encodings else None
            else:
                # Fallback: Use simple face region histogram as encoding
                face_region = self.detect_face_region(image)
                if face_region is None:
                    return None
                
                x, y, w, h = face_region
                face_crop = image[y:y+h, x:x+w]
                if face_crop.size == 0:
                    return None
                
                # Create a simple encoding from face region histogram
                hist = cv2.calcHist([face_crop], [0, 1, 2], None, [8, 8, 8], [0, 256, 0, 256, 0, 256])
                return hist.flatten()
        except Exception as e:
            logger.error(f"Face encoding error: {str(e)}")
            return None
    
    def verify_face_preservation(
        self,
        original_image: np.ndarray,
        result_image: np.ndarray,
        face_region: Optional[Tuple[int, int, int, int]] = None
    ) -> Tuple[bool, float, str]:
        """
        Verify that face is preserved (CRITICAL CHECK)
        
        Returns:
            (passed, similarity_score, error_message)
        """
        try:
            # Extract face encodings
            orig_encoding = self.extract_face_encoding(original_image)
            result_encoding = self.extract_face_encoding(result_image)
            
            if orig_encoding is None:
                return False, 0.0, "No face detected in original image"
            
            if result_encoding is None:
                return False, 0.0, "No face detected in result image"
            
            # Calculate similarity
            if SCIPY_AVAILABLE:
                distance = euclidean(orig_encoding, result_encoding)
            else:
                # Fallback: Use numpy for distance
                distance = np.linalg.norm(orig_encoding - result_encoding)
            
            # Normalize distance (adjust threshold based on encoding type)
            if FACE_RECOGNITION_AVAILABLE:
                similarity = 1.0 - min(1.0, distance / 0.6)
            else:
                # For histogram-based encoding, use different normalization
                similarity = 1.0 - min(1.0, distance / np.max(orig_encoding) if np.max(orig_encoding) > 0 else 1.0)
            
            # Also check face region directly if provided
            if face_region:
                x, y, w, h = face_region
                orig_face = original_image[y:y+h, x:x+w]
                result_face = result_image[y:y+h, x:x+w]
                
                if orig_face.size > 0 and result_face.size > 0:
                    # Resize to same size if needed
                    if orig_face.shape != result_face.shape:
                        result_face = cv2.resize(result_face, (orig_face.shape[1], orig_face.shape[0]))
                    
                    # Calculate structural similarity
                    from skimage.metrics import structural_similarity as ssim
                    orig_gray = cv2.cvtColor(orig_face, cv2.COLOR_BGR2GRAY)
                    result_gray = cv2.cvtColor(result_face, cv2.COLOR_BGR2GRAY)
                    
                    ssim_score = ssim(orig_gray, result_gray)
                    similarity = (similarity + ssim_score) / 2.0
            
            passed = similarity >= self.similarity_threshold
            error_msg = "" if passed else f"Face similarity {similarity:.3f} < {self.similarity_threshold}"
            
            return passed, similarity, error_msg
        except Exception as e:
            return False, 0.0, f"Face verification error: {str(e)}"
    
    def apply_face_lock(
        self,
        original_image: np.ndarray,
        modified_image: np.ndarray,
        face_region: Optional[Tuple[int, int, int, int]] = None
    ) -> np.ndarray:
        """
        Apply face lock - replace modified face region with original
        This ensures face is NEVER changed
        """
        if face_region is None:
            face_region = self.detect_face_region(original_image)
        
        if face_region is None:
            logger.warning("No face region to lock")
            return modified_image
        
        # Create protection mask
        protection_mask = self.create_protection_mask(original_image, face_region)
        
        # Blend: use original in protected regions, modified elsewhere
        result = modified_image.copy()
        
        # Apply face lock with smooth blending
        mask_3channel = cv2.cvtColor(protection_mask, cv2.COLOR_GRAY2BGR) / 255.0
        result = (original_image * mask_3channel + modified_image * (1 - mask_3channel)).astype(np.uint8)
        
        return result
    
    def get_face_landmarks(self, image: np.ndarray) -> Optional[Dict]:
        """Get detailed face landmarks for precise protection"""
        try:
            if FACE_RECOGNITION_AVAILABLE:
                rgb_image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
                face_landmarks_list = face_recognition.face_landmarks(rgb_image)
                
                if len(face_landmarks_list) == 0:
                    return None
                
                return face_landmarks_list[0]
            else:
                # Fallback: Return basic face region as landmarks
                face_region = self.detect_face_region(image)
                if face_region is None:
                    return None
                
                x, y, w, h = face_region
                return {
                    'chin': [(x + w//2, y + h)],
                    'left_eyebrow': [(x, y + h//4)],
                    'right_eyebrow': [(x + w, y + h//4)],
                    'nose_bridge': [(x + w//2, y), (x + w//2, y + h//2)],
                    'nose_tip': [(x + w//2, y + h//2)],
                    'left_eye': [(x + w//4, y + h//3)],
                    'right_eye': [(x + 3*w//4, y + h//3)],
                    'top_lip': [(x + w//2, y + 2*h//3)],
                    'bottom_lip': [(x + w//2, y + 3*h//4)]
                }
        except Exception as e:
            logger.error(f"Face landmarks error: {str(e)}")
            return None

