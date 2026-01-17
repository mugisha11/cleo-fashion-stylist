import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/fashion_ai_chat_service.dart';
import '../services/weather_service.dart';
import '../services/tryon_memory_service.dart';
import '../../features/wardrobe/providers/wardrobe_provider.dart';
import '../providers/tryon_memory_provider.dart';
import 'ai_recommendation_provider.dart';

final fashionAIChatServiceProvider = Provider<FashionAIChatService>((ref) {
  final supabase = Supabase.instance.client;
  final auth = FirebaseAuth.instance;
  final weatherService = ref.watch(weatherServiceProvider);
  final tryOnMemory = ref.watch(tryonMemoryServiceProvider);
  final wardrobeService = ref.watch(wardrobeServiceProvider);
  
  return FashionAIChatService(
    supabase,
    auth,
    weatherService,
    tryOnMemory,
    wardrobeService,
    ref,
  );
});
