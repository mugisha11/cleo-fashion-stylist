import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/tryon_memory_service.dart';
import '../models/tryon_session_model.dart';

final tryonMemoryServiceProvider = Provider<TryOnMemoryService>((ref) {
  final supabase = Supabase.instance.client;
  final auth = FirebaseAuth.instance;
  return TryOnMemoryService(supabase, auth);
});

final savedTryOnsProvider = FutureProvider<List<TryOnSession>>((ref) async {
  final service = ref.watch(tryonMemoryServiceProvider);
  return service.getSavedTryOns();
});
