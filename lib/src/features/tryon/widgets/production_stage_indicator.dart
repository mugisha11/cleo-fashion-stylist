/// Production Stage Indicator
/// Shows current backend processing stage
library;
import 'package:flutter/material.dart';
import '../../../core/models/production_vton_state.dart';
import '../../../core/theme/design_tokens.dart';

class ProductionStageIndicator extends StatelessWidget {
  final ProductionVTONStage stage;
  final ColorScheme colorScheme;

  const ProductionStageIndicator({
    super.key,
    required this.stage,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final stageName = _getStageName(stage);
    final progress = _getProgress(stage);
    final accent = Theme.of(context).brightness == Brightness.dark
        ? DesignTokens.darkAccent
        : DesignTokens.lightAccent;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Progress bar
        LinearProgressIndicator(
          value: progress,
          backgroundColor: colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(accent),
          minHeight: 2,
        ),
        const SizedBox(height: 8),
        // Stage name
        Text(
          stageName,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  String _getStageName(ProductionVTONStage stage) {
    switch (stage) {
      case ProductionVTONStage.stage0_validation:
        return 'Validating inputs...';
      case ProductionVTONStage.stage1_reasoning:
        return 'Analyzing garment placement...';
      case ProductionVTONStage.stage2_body_understanding:
        return 'Understanding body structure...';
      case ProductionVTONStage.stage3_garment_segmentation:
        return 'Segmenting garment...';
      case ProductionVTONStage.stage4_constraint:
        return 'Applying constraints...';
      case ProductionVTONStage.stage5_prompt_synthesis:
        return 'Preparing generation...';
      case ProductionVTONStage.stage6_gemini_generation:
        return 'Generating result...';
      case ProductionVTONStage.stage7_quality:
        return 'Validating quality...';
      default:
        return 'Processing...';
    }
  }

  double _getProgress(ProductionVTONStage stage) {
    switch (stage) {
      case ProductionVTONStage.stage0_validation:
        return 0.125;
      case ProductionVTONStage.stage1_reasoning:
        return 0.25;
      case ProductionVTONStage.stage2_body_understanding:
        return 0.375;
      case ProductionVTONStage.stage3_garment_segmentation:
        return 0.5;
      case ProductionVTONStage.stage4_constraint:
        return 0.625;
      case ProductionVTONStage.stage5_prompt_synthesis:
        return 0.75;
      case ProductionVTONStage.stage6_gemini_generation:
        return 0.875;
      case ProductionVTONStage.stage7_quality:
        return 0.95;
      case ProductionVTONStage.success:
        return 1.0;
      default:
        return 0.0;
    }
  }
}
