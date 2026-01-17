/// Try-On State Machine for Sora-like VTON Pipeline
/// States: idle → uploading → reasoning → diffusing → success/failed
enum TryOnState {
  idle,
  uploading,
  reasoning,
  diffusing,
  success,
  failed,
}

/// Try-On Result
class TryOnResult {
  final String? imageBase64;
  final Map<String, double>? qualityScores;
  final String? errorStage;
  final String? errorReason;
  final String? errorMessage;

  TryOnResult({
    this.imageBase64,
    this.qualityScores,
    this.errorStage,
    this.errorReason,
    this.errorMessage,
  });

  bool get isSuccess => imageBase64 != null && qualityScores != null;
  bool get isFailed => errorStage != null || errorReason != null;

  /// Get face similarity score (0-1)
  double? get faceSimilarity => qualityScores?['face_similarity'];

  /// Get pose alignment score (0-1)
  double? get poseAlignment => qualityScores?['pose_alignment'];

  /// Get mask integrity score (0-1)
  double? get maskIntegrity => qualityScores?['mask_integrity'];

  /// Check if quality scores meet thresholds
  bool get meetsQualityThresholds {
    if (qualityScores == null) return false;
    final faceSim = faceSimilarity ?? 0.0;
    final maskInt = maskIntegrity ?? 0.0;
    return faceSim >= 0.99 && maskInt >= 1.0;
  }
}
