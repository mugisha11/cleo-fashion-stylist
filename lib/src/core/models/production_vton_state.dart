/// Production Virtual Try-On State
/// Represents the 7-stage pipeline states
enum ProductionVTONStage {
  idle,
  stage0_validation,
  stage1_reasoning,
  stage2_body_understanding,
  stage3_garment_segmentation,
  stage4_constraint,
  stage5_prompt_synthesis,
  stage6_gemini_generation,
  stage7_quality,
  success,
  failed,
  rejected,
}

/// Production VTON State
class ProductionVTONState {
  final ProductionVTONStage stage;
  final String? resultImageUrl;
  final Map<String, dynamic>? metadata;
  final Map<String, dynamic>? qualityMetrics;
  final String? error;
  final String? errorStage;

  const ProductionVTONState({
    this.stage = ProductionVTONStage.idle,
    this.resultImageUrl,
    this.metadata,
    this.qualityMetrics,
    this.error,
    this.errorStage,
  });

  ProductionVTONState copyWith({
    ProductionVTONStage? stage,
    String? resultImageUrl,
    Map<String, dynamic>? metadata,
    Map<String, dynamic>? qualityMetrics,
    String? error,
    String? errorStage,
  }) {
    return ProductionVTONState(
      stage: stage ?? this.stage,
      resultImageUrl: resultImageUrl ?? this.resultImageUrl,
      metadata: metadata ?? this.metadata,
      qualityMetrics: qualityMetrics ?? this.qualityMetrics,
      error: error ?? this.error,
      errorStage: errorStage ?? this.errorStage,
    );
  }

  bool get isProcessing => stage != ProductionVTONStage.idle &&
      stage != ProductionVTONStage.success &&
      stage != ProductionVTONStage.failed &&
      stage != ProductionVTONStage.rejected;

  bool get isSuccess => stage == ProductionVTONStage.success;
  bool get isFailed => stage == ProductionVTONStage.failed;
  bool get isRejected => stage == ProductionVTONStage.rejected;

  String get stageDisplayName {
    switch (stage) {
      case ProductionVTONStage.idle:
        return 'Ready';
      case ProductionVTONStage.stage0_validation:
        return 'Validating';
      case ProductionVTONStage.stage1_reasoning:
        return 'Analyzing garment';
      case ProductionVTONStage.stage2_body_understanding:
        return 'Understanding body';
      case ProductionVTONStage.stage3_garment_segmentation:
        return 'Segmenting garment';
      case ProductionVTONStage.stage4_constraint:
        return 'Applying constraints';
      case ProductionVTONStage.stage5_prompt_synthesis:
        return 'Preparing generation';
      case ProductionVTONStage.stage6_gemini_generation:
        return 'Generating result';
      case ProductionVTONStage.stage7_quality:
        return 'Validating quality';
      case ProductionVTONStage.success:
        return 'Complete';
      case ProductionVTONStage.failed:
        return 'Failed';
      case ProductionVTONStage.rejected:
        return 'Rejected';
    }
  }
}
