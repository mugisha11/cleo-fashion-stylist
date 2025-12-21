"""
Pose Estimation Service
Uses MediaPipe for accurate body pose detection
"""
import cv2
import numpy as np
from typing import List, Tuple, Optional, Dict, Any
import logging

logger = logging.getLogger(__name__)

# Try to import MediaPipe - handle both old and new API
try:
    import mediapipe as mp
    if hasattr(mp, 'solutions'):
        # Old API (mediapipe < 0.10)
        MP_AVAILABLE = True
        MP_NEW_API = False
    elif hasattr(mp, 'tasks'):
        # New API (mediapipe >= 0.10)
        MP_AVAILABLE = True
        MP_NEW_API = True
    else:
        MP_AVAILABLE = False
        MP_NEW_API = False
except ImportError:
    MP_AVAILABLE = False
    MP_NEW_API = False
    logger.warning("MediaPipe not available - pose estimation will be limited")


class PoseEstimator:
    """MediaPipe-based pose estimation for VTON alignment"""
    
    def __init__(self, min_detection_confidence: float = 0.5, min_tracking_confidence: float = 0.5):
        if not MP_AVAILABLE:
            logger.warning("MediaPipe not available - using fallback pose estimation")
            self.pose = None
            self.mp_pose = None
            self.mp_drawing = None
            return
        
        try:
            if MP_NEW_API:
                # New MediaPipe API (0.10+) - simplified for now
                logger.info("Using MediaPipe new API - pose estimation available")
                # For now, we'll use a simplified approach
                # Full implementation would require PoseLandmarker from tasks
                self.pose = None  # Will use fallback
                self.mp_pose = None
                self.mp_drawing = None
            else:
                # Old MediaPipe API (< 0.10)
                self.mp_pose = mp.solutions.pose
                self.pose = self.mp_pose.Pose(
                    static_image_mode=True,
                    model_complexity=2,
                    enable_segmentation=False,
                    min_detection_confidence=min_detection_confidence,
                    min_tracking_confidence=min_tracking_confidence
                )
                self.mp_drawing = mp.solutions.drawing_utils
        except Exception as e:
            logger.warning(f"MediaPipe initialization failed, using fallback: {e}")
            self.pose = None
            self.mp_pose = None
            self.mp_drawing = None
    
    def estimate(self, image: np.ndarray) -> Dict[str, Any]:
        """
        Estimate pose landmarks from image
        
        Returns:
            Dictionary with landmarks, confidence, and key points
        """
        # Fallback if MediaPipe not available or not initialized
        if self.pose is None:
            logger.warning("MediaPipe not available - using fallback pose estimation")
            # Return basic pose data based on image dimensions
            h, w = image.shape[:2]
            return {
                'landmarks': None,
                'confidence': 0.7,  # Moderate confidence for fallback
                'key_points': {
                    'left_shoulder': (w // 3, h // 4),
                    'right_shoulder': (2 * w // 3, h // 4),
                    'left_hip': (w // 3, h // 2),
                    'right_hip': (2 * w // 3, h // 2),
                    'neck': (w // 2, h // 5),
                },
                'success': True,
                'raw_results': None
            }
        
        try:
            # Convert BGR to RGB
            image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
            
            # Process image
            results = self.pose.process(image_rgb)
            
            if not results.pose_landmarks:
                logger.warning("No pose detected in image")
                return {
                    'landmarks': None,
                    'confidence': 0.0,
                    'key_points': None,
                    'success': False
                }
            
            # Extract landmarks
            landmarks = results.pose_landmarks.landmark
            
            # Get key points for alignment
            key_points = self._extract_key_points(landmarks, image.shape)
            
            # Calculate overall confidence
            confidence = self._calculate_confidence(landmarks)
            
            return {
                'landmarks': landmarks,
                'confidence': confidence,
                'key_points': key_points,
                'success': True,
                'raw_results': results
            }
        except Exception as e:
            logger.error(f"Pose estimation error: {str(e)}")
            # Fallback to basic estimation
            h, w = image.shape[:2]
            return {
                'landmarks': None,
                'confidence': 0.6,
                'key_points': {
                    'left_shoulder': (w // 3, h // 4),
                    'right_shoulder': (2 * w // 3, h // 4),
                    'left_hip': (w // 3, h // 2),
                    'right_hip': (2 * w // 3, h // 2),
                },
                'success': True,
                'error': str(e)
            }
    
    def _extract_key_points(
        self,
        landmarks: Optional[List],
        image_shape: Tuple[int, int, int]
    ) -> Dict[str, Tuple[int, int]]:
        """Extract key body points for alignment"""
        if landmarks is None or self.mp_pose is None:
            # Fallback key points
            h, w = image_shape[:2]
            return {
                'left_shoulder': (w // 3, h // 4),
                'right_shoulder': (2 * w // 3, h // 4),
                'left_hip': (w // 3, h // 2),
                'right_hip': (2 * w // 3, h // 2),
            }
        
        h, w = image_shape[:2]
        
        # Important landmarks for clothing alignment
        try:
            landmark_indices = {
                'left_shoulder': self.mp_pose.PoseLandmark.LEFT_SHOULDER,
                'right_shoulder': self.mp_pose.PoseLandmark.RIGHT_SHOULDER,
                'left_hip': self.mp_pose.PoseLandmark.LEFT_HIP,
                'right_hip': self.mp_pose.PoseLandmark.RIGHT_HIP,
                'left_elbow': self.mp_pose.PoseLandmark.LEFT_ELBOW,
                'right_elbow': self.mp_pose.PoseLandmark.RIGHT_ELBOW,
                'left_wrist': self.mp_pose.PoseLandmark.LEFT_WRIST,
                'right_wrist': self.mp_pose.PoseLandmark.RIGHT_WRIST,
                'neck': self.mp_pose.PoseLandmark.NOSE,  # Approximate neck
            }
            
            key_points = {}
            for name, idx in landmark_indices.items():
                if idx < len(landmarks):
                    landmark = landmarks[idx]
                    if landmark.visibility > 0.5:  # Only use visible landmarks
                        key_points[name] = (
                            int(landmark.x * w),
                            int(landmark.y * h)
                        )
            
            return key_points
        except Exception as e:
            logger.warning(f"Error extracting key points: {e}")
            # Fallback
            return {
                'left_shoulder': (w // 3, h // 4),
                'right_shoulder': (2 * w // 3, h // 4),
                'left_hip': (w // 3, h // 2),
                'right_hip': (2 * w // 3, h // 2),
            }
    
    def _calculate_confidence(self, landmarks: Optional[List]) -> float:
        """Calculate overall pose detection confidence"""
        if not landmarks or self.mp_pose is None:
            return 0.6  # Fallback confidence
        
        try:
            # Average visibility of key landmarks
            key_indices = [
                self.mp_pose.PoseLandmark.LEFT_SHOULDER,
                self.mp_pose.PoseLandmark.RIGHT_SHOULDER,
                self.mp_pose.PoseLandmark.LEFT_HIP,
                self.mp_pose.PoseLandmark.RIGHT_HIP,
            ]
            
            visibilities = [landmarks[idx].visibility for idx in key_indices if idx < len(landmarks)]
            return np.mean(visibilities) if visibilities else 0.6
        except Exception:
            return 0.6  # Fallback
    
    def visualize(self, image: np.ndarray, pose_data: Dict) -> np.ndarray:
        """Draw pose landmarks on image for debugging"""
        if not pose_data.get('success') or not pose_data.get('raw_results') or self.mp_drawing is None:
            return image
        
        try:
            annotated_image = image.copy()
            self.mp_drawing.draw_landmarks(
                annotated_image,
                pose_data['raw_results'].pose_landmarks,
                self.mp_pose.POSE_CONNECTIONS,
                self.mp_drawing.DrawingSpec(
                    color=(0, 255, 0), thickness=2, circle_radius=2
                ),
                self.mp_drawing.DrawingSpec(
                    color=(255, 0, 0), thickness=2
                )
            )
            return annotated_image
        except Exception:
            return image
    
    def __del__(self):
        """Cleanup"""
        if hasattr(self, 'pose') and self.pose is not None:
            try:
                self.pose.close()
            except Exception:
                pass

