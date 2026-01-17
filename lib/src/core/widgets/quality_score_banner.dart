import 'package:flutter/material.dart';
import '../models/tryon_state.dart';

/// Quality Score Banner
/// Shows warnings if quality scores don't meet thresholds
class QualityScoreBanner extends StatelessWidget {
  final TryOnResult result;

  const QualityScoreBanner({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    if (result.qualityScores == null) {
      return const SizedBox.shrink();
    }

    final issues = <String>[];

    // Check face similarity
    if (result.faceSimilarity != null && result.faceSimilarity! < 0.99) {
      issues.add('Face similarity below threshold (${(result.faceSimilarity! * 100).toStringAsFixed(1)}%)');
    }

    // Check mask integrity
    if (result.maskIntegrity != null && result.maskIntegrity! < 1.0) {
      issues.add('Mask integrity compromised (${(result.maskIntegrity! * 100).toStringAsFixed(1)}%)');
    }

    if (issues.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB800).withOpacity(0.1),
        border: Border.all(color: const Color(0xFFFFB800), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFFFB800),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quality Warning',
                  style: TextStyle(
                    color: Color(0xFFFFB800),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                ...issues.map((issue) => Text(
                      issue,
                      style: const TextStyle(
                        color: Color(0xFF808080),
                        fontSize: 12,
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
