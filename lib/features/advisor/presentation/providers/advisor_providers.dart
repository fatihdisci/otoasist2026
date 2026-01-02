import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../garage/presentation/providers/garage_providers.dart'; 
import '../../data/repositories/ai_repository_interface.dart';
import '../../data/repositories/ai_repository_impl.dart';
import '../../data/datasources/ai_data_sources.dart';

final aiLocalDataSourceProvider = Provider((ref) {
  return AiLocalDataSource(ref.watch(firestoreProvider));
});

final aiRemoteDataSourceProvider = Provider((ref) {
  // API Key'i .env dosyasından güvenli şekilde oku
  final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  
  if (apiKey.isEmpty) {
    throw Exception(
      'GEMINI_API_KEY bulunamadı! Lütfen .env dosyasını oluşturup API anahtarınızı ekleyin. '
      '.env.example dosyasını referans alabilirsiniz.'
    );
  }
  
  return AiRemoteDataSource(apiKey);
});

final aiRepositoryProvider = Provider<IAiRepository>((ref) {
  return AiRepositoryImpl(
    ref.watch(aiLocalDataSourceProvider),
    ref.watch(aiRemoteDataSourceProvider),
  );
});
