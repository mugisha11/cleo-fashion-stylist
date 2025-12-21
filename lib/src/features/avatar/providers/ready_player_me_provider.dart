import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ready_player_me_avatar_service.dart';

/// Provider for Ready Player Me Avatar Service
final readyPlayerMeServiceProvider = Provider<ReadyPlayerMeAvatarService>((ref) {
  return ReadyPlayerMeAvatarService();
});




