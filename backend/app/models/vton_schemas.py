"""
Pydantic Schemas for Production Virtual Try-On System
Strict validation for all pipeline stages
"""
from pydantic import BaseModel, Field, field_validator
from typing import List, Optional, Dict, Any, Literal
from enum import Enum


class GarmentType(str, Enum):
    """Supported garment types"""
    SHOES = "shoes"
    SHIRT = "shirt"
    TOP = "top"
    T_SHIRT = "t_shirt"
    BLOUSE = "blouse"
    PANTS = "pants"
    JEANS = "jeans"
    SHORTS = "shorts"
    DRESS = "dress"
    JACKET = "jacket"
    COAT = "coat"
    HAT = "hat"
    ACCESSORY = "accessory"
    OTHER = "other"


class BodyRegion(str, Enum):
    """Anatomical body regions"""
    FACE = "face"
    HAIR = "hair"
    NECK = "neck"
    TORSO = "torso"
    LEFT_ARM = "left_arm"
    RIGHT_ARM = "right_arm"
    LEFT_HAND = "left_hand"
    RIGHT_HAND = "right_hand"
    HIPS = "hips"
    LEFT_LEG = "left_leg"
    RIGHT_LEG = "right_leg"
    LEFT_FOOT = "left_foot"
    RIGHT_FOOT = "right_foot"
    FULL_BODY = "full_body"


class GarmentAnalysis(BaseModel):
    """Analysis result for a single garment"""
    type: GarmentType = Field(..., description="Garment type")
    confidence: float = Field(..., ge=0.0, le=1.0, description="Confidence score")
    allowed_regions: List[BodyRegion] = Field(..., description="Allowed anatomical regions")
    style: Optional[str] = Field(None, description="Style description")
    material: Optional[str] = Field(None, description="Material description")
    fit: Optional[str] = Field(None, description="Fit description (loose/regular/tight)")
    
    @field_validator('confidence')
    @classmethod
    def validate_confidence(cls, v):
        if v < 0.9:
            raise ValueError(f"Confidence {v} below minimum threshold 0.9")
        return v
    
    @field_validator('allowed_regions')
    @classmethod
    def validate_regions(cls, v):
        if not v:
            raise ValueError("allowed_regions cannot be empty")
        return v


class Stage1ReasoningOutput(BaseModel):
    """Output from Stage 1: Vision-Language Reasoning"""
    garments: List[GarmentAnalysis] = Field(..., description="Analyzed garments")
    layering_order: List[int] = Field(..., description="Layering order (indices into garments)")
    reject: bool = Field(False, description="Whether to reject this request")
    reason: Optional[str] = Field(None, description="Rejection reason if reject=True")
    ambiguity_detected: bool = Field(False, description="Whether ambiguity was detected")
    
    @field_validator('garments')
    @classmethod
    def validate_garments(cls, v):
        if not v:
            raise ValueError("garments list cannot be empty")
        return v
    
    @field_validator('layering_order')
    @classmethod
    def validate_layering(cls, v, info):
        if 'garments' in info.data:
            num_garments = len(info.data['garments'])
            if len(v) != num_garments:
                raise ValueError(f"layering_order length {len(v)} must match garments length {num_garments}")
            if set(v) != set(range(num_garments)):
                raise ValueError(f"layering_order must contain all indices 0..{num_garments-1}")
        return v


class BodyPartMask(BaseModel):
    """Body part segmentation mask"""
    region: BodyRegion = Field(..., description="Body region")
    mask: Any = Field(..., description="Binary mask (numpy array)")
    confidence: float = Field(..., ge=0.0, le=1.0, description="Segmentation confidence")


class PoseLandmarks(BaseModel):
    """Pose landmarks from MediaPipe/OpenPose"""
    keypoints: Dict[str, List[float]] = Field(..., description="Keypoint name -> [x, y, confidence]")
    image_shape: List[int] = Field(..., description="[height, width] of image")


class Stage2BodyUnderstandingOutput(BaseModel):
    """Output from Stage 2: Human Body Understanding"""
    body_part_masks: Dict[BodyRegion, Any] = Field(..., description="Masks for each body part")
    pose_landmarks: PoseLandmarks = Field(..., description="Pose landmarks")
    occlusion_map: Optional[Any] = Field(None, description="Occlusion awareness map")
    full_body_mask: Any = Field(..., description="Full body mask")


class GarmentMask(BaseModel):
    """Garment segmentation mask"""
    garment_index: int = Field(..., description="Index in garments list")
    alpha_mask: Any = Field(..., description="Alpha mask (numpy array)")
    texture_image: Any = Field(..., description="Texture-preserved garment image")
    confidence: float = Field(..., ge=0.0, le=1.0, description="Segmentation confidence")


class Stage3GarmentSegmentationOutput(BaseModel):
    """Output from Stage 3: Garment Segmentation"""
    garment_masks: List[GarmentMask] = Field(..., description="Segmented garment masks")


class ConstraintMasks(BaseModel):
    """Constraint masks from Stage 4"""
    editable_mask: Any = Field(..., description="Where editing is allowed")
    locked_mask: Any = Field(..., description="Where editing is forbidden (face, hair, etc.)")
    region_maps: Dict[str, Any] = Field(..., description="Maps for each garment (key: 'garment_0', 'garment_1', etc.)")
    conflict_free: bool = Field(True, description="Whether constraints are conflict-free")


class Stage4ConstraintOutput(BaseModel):
    """Output from Stage 4: Constraint Engine"""
    constraints: ConstraintMasks = Field(..., description="Constraint masks")
    validation_passed: bool = Field(True, description="Whether validation passed")
    validation_errors: List[str] = Field(default_factory=list, description="Validation errors")


class WarpingParameters(BaseModel):
    """Geometric warping parameters for a garment"""
    garment_index: int = Field(..., description="Index of garment in garments list")
    source_keypoints: List[List[float]] = Field(..., description="Keypoints on garment (N, 2)")
    target_keypoints: List[List[float]] = Field(..., description="Target keypoints on body (N, 2)")
    target_mask: Any = Field(..., description="Target region mask (numpy array)")
    warping_method: str = Field("tps", description="Warping method (tps, affine, etc.)")


class Stage5WarpingOutput(BaseModel):
    """Output from Stage 5: Warping Preparation"""
    warping_parameters: List[WarpingParameters] = Field(..., description="Warping parameters for each garment")


class Stage6GenerationOutput(BaseModel):
    """Output from Stage 6: Gemini Generation"""
    result_image: Any = Field(..., description="Generated try-on result (numpy array)")
    generation_metadata: Dict[str, Any] = Field(default_factory=dict, description="Generation metadata")


class QualityMetrics(BaseModel):
    """Quality metrics from Stage 7"""
    face_similarity: float = Field(..., ge=0.0, le=1.0, description="Face similarity score")
    pose_deviation: float = Field(..., ge=0.0, description="Pose deviation")
    garment_coverage: float = Field(..., ge=0.0, le=1.0, description="Garment coverage")
    artifact_score: float = Field(..., ge=0.0, le=1.0, description="Artifact detection score")
    overall_quality: float = Field(..., ge=0.0, le=1.0, description="Overall quality score")


class Stage7QualityOutput(BaseModel):
    """Output from Stage 7: Quality Gates"""
    passed: bool = Field(..., description="Whether quality gates passed")
    metrics: QualityMetrics = Field(..., description="Quality metrics")
    decision: Literal["accept", "retry", "reject"] = Field(..., description="Quality decision")
    reason: Optional[str] = Field(None, description="Decision reason")


class ProductionVTONRequest(BaseModel):
    """Request for production virtual try-on"""
    user_image_url: Optional[str] = Field(None, description="URL of user photo")
    user_image_base64: Optional[str] = Field(None, description="Base64 encoded user photo")
    garment_image_urls: Optional[List[str]] = Field(None, description="URLs of garment images")
    garment_image_base64s: Optional[List[str]] = Field(None, description="Base64 encoded garment images")
    user_id: Optional[str] = Field(None, description="User ID")
    
    @field_validator('*', mode='before')
    @classmethod
    def validate_inputs(cls, v, info):
        field_name = info.field_name
        if field_name in ['user_image_url', 'user_image_base64']:
            if not v:
                raise ValueError(f"Either {field_name} must be provided")
        if field_name in ['garment_image_urls', 'garment_image_base64s']:
            if not v or len(v) == 0:
                raise ValueError("At least one garment image must be provided")
        return v


class ProductionVTONResponse(BaseModel):
    """Response from production virtual try-on"""
    status: Literal["success", "failed", "rejected"] = Field(..., description="Status")
    result_image_url: Optional[str] = Field(None, description="URL of result image")
    stage: Optional[str] = Field(None, description="Stage where processing stopped")
    error: Optional[str] = Field(None, description="Error message if failed")
    metadata: Dict[str, Any] = Field(default_factory=dict, description="Processing metadata")
    quality_metrics: Optional[QualityMetrics] = Field(None, description="Quality metrics if successful")
