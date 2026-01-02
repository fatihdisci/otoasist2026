import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../garage/presentation/providers/garage_providers.dart'; 
import '../../data/repositories/ai_repository_interface.dart';
import '../../data/repositories/ai_repository_impl.dart';
import '../../data/datasources/ai_data_sources.dart';

final aiLocalDataSourceProvider = Provider((ref) {
  return AiLocalDataSource(ref.watch(firestoreProvider));
});

final aiRemoteDataSourceProvider = Provider((ref) {
  // --- KRİTİK NOKTA: API KEY ---
  // Buraya kendi API anahtarını tırnaklar içine yapıştır.
  const String apiKey = "BURAYA_GEMINI_API_KEY_YAZILACAK"; 
  
  return AiRemoteDataSource(apiKey);
});

final aiRepositoryProvider = Provider<IAiRepository>((ref) {
  return AiRepositoryImpl(
    ref.watch(aiLocalDataSourceProvider),
    ref.watch(aiRemoteDataSourceProvider),
  );
});