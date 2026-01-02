import '../../../garage/domain/models/vehicle_model.dart';
import '../../../garage/domain/models/ai_response_model.dart';

/// Clean Architecture: Dependency Inversion için arayüz.
/// UI ve ViewModel, implementasyon detaylarını (Firestore, Cloud Functions) bilmez.
abstract class IAiRepository {
  Future<AiAnalysisResponse> getVehicleAnalysis(Vehicle vehicle);
}