"""
Supabase Storage Service
Handles image uploads and metadata storage
"""
import os
import uuid
from typing import Optional, Dict, Any
import numpy as np
import cv2
from supabase import create_client, Client
import logging
from datetime import datetime

logger = logging.getLogger(__name__)


class StorageService:
    """Supabase storage integration for VTON results"""
    
    def __init__(self, supabase_url: str, supabase_key: str, bucket_name: str = "tryon-results"):
        if not supabase_url or not supabase_key:
            raise ValueError("Supabase URL and key are required")
        self.supabase: Client = create_client(supabase_url, supabase_key)
        self.bucket_name = bucket_name
        self._ensure_bucket_exists()
    
    def _ensure_bucket_exists(self):
        """Ensure storage bucket exists"""
        try:
            buckets = self.supabase.storage.list_buckets()
            bucket_names = [b.name for b in buckets]
            if self.bucket_name not in bucket_names:
                logger.warning(f"Bucket {self.bucket_name} does not exist. Create it in Supabase dashboard.")
        except Exception as e:
            logger.error(f"Error checking bucket: {str(e)}")
    
    def upload_image(
        self,
        image: np.ndarray,
        user_id: str,
        image_type: str = "tryon_result",
        quality: int = 95
    ) -> Optional[str]:
        """
        Upload image to Supabase Storage
        
        Args:
            image: Image as numpy array (BGR format)
            user_id: User ID for organization
            image_type: Type of image (tryon_result, original, clothing, etc.)
            quality: JPEG quality (1-100)
        
        Returns:
            Public URL of uploaded image, or None if failed
        """
        try:
            # Generate unique filename
            file_id = str(uuid.uuid4())
            filename = f"{user_id}/{image_type}/{file_id}.jpg"
            
            # Encode image
            success, buffer = cv2.imencode('.jpg', image, [cv2.IMWRITE_JPEG_QUALITY, quality])
            if not success:
                raise Exception("Failed to encode image")
            
            # Upload to Supabase
            response = self.supabase.storage.from_(self.bucket_name).upload(
                filename,
                buffer.tobytes(),
                file_options={"content-type": "image/jpeg"}
            )
            
            # Get public URL
            public_url = self.supabase.storage.from_(self.bucket_name).get_public_url(filename)
            
            logger.info(f"Image uploaded: {public_url}")
            return public_url
            
        except Exception as e:
            logger.error(f"Upload error: {str(e)}")
            return None
    
    def save_tryon_metadata(
        self,
        user_id: str,
        original_image_url: str,
        clothing_image_url: str,
        result_image_url: str,
        metadata: Optional[Dict[str, Any]] = None
    ) -> Optional[str]:
        """
        Save try-on session metadata to database
        
        Returns:
            Session ID
        """
        try:
            session_id = str(uuid.uuid4())
            
            record = {
                'id': session_id,
                'user_id': user_id,
                'original_image_url': original_image_url,
                'clothing_image_url': clothing_image_url,
                'result_image_url': result_image_url,
                'metadata': metadata or {},
                'created_at': datetime.utcnow().isoformat(),
                'status': 'completed'
            }
            
            # Insert into tryon_sessions table
            response = self.supabase.table('tryon_sessions').insert(record).execute()
            
            logger.info(f"Metadata saved for session: {session_id}")
            return session_id
            
        except Exception as e:
            logger.error(f"Metadata save error: {str(e)}")
            return None
    
    def save_outfit_feedback(
        self,
        user_id: str,
        outfit_id: str,
        liked: bool,
        reason: Optional[str] = None
    ) -> bool:
        """Save user feedback for outfit recommendations"""
        try:
            record = {
                'user_id': user_id,
                'outfit_id': outfit_id,
                'liked': liked,
                'reason': reason,
                'created_at': datetime.utcnow().isoformat()
            }
            
            self.supabase.table('outfit_feedback').upsert(
                record,
                on_conflict='user_id,outfit_id'
            ).execute()
            
            return True
        except Exception as e:
            logger.error(f"Feedback save error: {str(e)}")
            return False

