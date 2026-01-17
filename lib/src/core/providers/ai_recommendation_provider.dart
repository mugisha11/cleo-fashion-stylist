import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/ai_recommendation_engine.dart';
import '../services/weather_service.dart';
import '../services/tryon_memory_service.dart';
import '../../features/wardrobe/providers/wardrobe_provider.dart';
import '../../features/calendar/providers/calendar_provider.dart';
import '../models/tryon_session_model.dart';
import '../providers/tryon_memory_provider.dart';

final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

final aiRecommendationEngineProvider = Provider<AIRecommendationEngine>((ref) {
  final supabase = Supabase.instance.client;
  final auth = FirebaseAuth.instance;
  final weatherService = ref.watch(weatherServiceProvider);
  final tryOnMemory = ref.watch(tryonMemoryServiceProvider);
  final wardrobeService = ref.watch(wardrobeServiceProvider);
  
  return AIRecommendationEngine(
    supabase,
    auth,
    weatherService,
    tryOnMemory,
    wardrobeService,
  );
});

final dailyRecommendationsProvider = FutureProvider<List<OutfitRecommendation>>((ref) async {
  final engine = ref.watch(aiRecommendationEngineProvider);
  return engine.generateDailyRecommendations();
});
