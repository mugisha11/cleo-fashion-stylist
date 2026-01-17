/// AI Service Providers
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/ai_image_understanding_service.dart';
import '../../../core/services/ai_reasoning_service.dart';
import '../../../core/services/calendar_intelligence_service.dart';
import '../../../core/services/multilingual_nlu_service.dart';
import '../../../core/services/weather_service.dart';

final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

final aiImageUnderstandingServiceProvider = Provider<AIImageUnderstandingService>((ref) {
  final supabase = Supabase.instance.client;
  final auth = FirebaseAuth.instance;
  return AIImageUnderstandingService(supabase, auth);
});

final aiReasoningServiceProvider = Provider<AIReasoningService>((ref) {
  final supabase = Supabase.instance.client;
  final auth = FirebaseAuth.instance;
  final weatherService = ref.watch(weatherServiceProvider);
  return AIReasoningService(supabase, auth, weatherService);
});

final calendarIntelligenceServiceProvider = Provider<CalendarIntelligenceService>((ref) {
  final supabase = Supabase.instance.client;
  final auth = FirebaseAuth.instance;
  final aiReasoning = ref.watch(aiReasoningServiceProvider);
  return CalendarIntelligenceService(supabase, auth, aiReasoning);
});

final multilingualNLUServiceProvider = Provider<MultilingualNLUService>((ref) {
  final supabase = Supabase.instance.client;
  final auth = FirebaseAuth.instance;
  return MultilingualNLUService(supabase, auth);
});
