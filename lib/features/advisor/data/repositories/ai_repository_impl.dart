import 'package:flutter/foundation.dart';
import '../../../garage/domain/models/vehicle_model.dart';
import '../../../garage/domain/models/ai_response_model.dart';
import '../datasources/ai_data_sources.dart';
import '../../domain/utils/ai_helpers.dart';
import 'ai_repository_interface.dart';

class AiRepositoryImpl implements IAiRepository {
  final AiLocalDataSource _localDataSource;
  final AiRemoteDataSource _remoteDataSource;

  AiRepositoryImpl(this._localDataSource, this._remoteDataSource);

  @override
  Future<AiAnalysisResponse> getVehicleAnalysis(Vehicle vehicle) async {
    try {
      debugPrint("AI Repo: Analiz başlatılıyor...");
      final signature = AiHelpers.generateVehicleSignature(vehicle);

      // 1. Önce cache'den kontrol et
      debugPrint("AI Repo: Cache kontrol ediliyor...");
      final cachedData = await _localDataSource.getCachedAnalysis(signature);
      
      if (cachedData != null) {
        debugPrint("AI Repo: Cache'den veri bulundu!");
        return AiAnalysisResponse.fromJson(cachedData);
      }

      // 2. Cache'de yoksa remote'tan al
      debugPrint("AI Repo: Cache'de veri yok, Remote DataSource çağrılıyor...");
      final rawJson = await _remoteDataSource.fetchAnalysis(vehicle.toMap());

      // 3. Parse et
      debugPrint("AI Repo: JSON parse ediliyor...");
      final response = AiAnalysisResponse.fromJson(rawJson);
      
      // 4. Cache'e kaydet (async, hata olursa da devam et)
      try {
        await _localDataSource.cacheAnalysis(signature, rawJson);
        debugPrint("AI Repo: Veri cache'lendi.");
      } catch (cacheError) {
        debugPrint("AI Repo: Cache kaydetme hatası (önemsiz): $cacheError");
      }
      
      debugPrint("AI Repo: Başarılı!");
      return response;
      
    } catch (e, stack) {
      debugPrint("AI REPO HATASI: $e");
      debugPrint("STACK TRACE: $stack");
      // Hatayı yukarı fırlat ki UI 'error' durumuna geçsin, loading'de kalmasın
      rethrow;
    }
  }
}