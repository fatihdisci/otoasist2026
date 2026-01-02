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

      // 1. Remote'tan al (Şimdilik direkt remote)
      debugPrint("AI Repo: Remote DataSource çağrılıyor...");
      final rawJson = await _remoteDataSource.fetchAnalysis(vehicle.toMap());

      // 2. Parse et
      debugPrint("AI Repo: JSON parse ediliyor...");
      final response = AiAnalysisResponse.fromJson(rawJson);
      
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