import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/vton_service.dart';

/// Try-on status provider
final tryonStatusProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, sessionId) async {
    final service = ref.read(vtonServiceProvider);
    return await service.getTryOnStatus(sessionId);
  },
);

