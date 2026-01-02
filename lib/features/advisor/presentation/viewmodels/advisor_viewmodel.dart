import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../garage/domain/models/ai_response_model.dart'; // DÜZELTİLDİ
import '../../data/repositories/ai_repository_interface.dart'; // DÜZELTİLDİ
import '../providers/advisor_providers.dart';
import '../../../garage/domain/models/vehicle_model.dart';

// State Sınıfı
class AdvisorState {
  final AsyncValue<AiAnalysisResponse?> analysis;
  
  AdvisorState({required this.analysis});
  
  AdvisorState copyWith({AsyncValue<AiAnalysisResponse?>? analysis}) {
    return AdvisorState(analysis: analysis ?? this.analysis);
  }
}

// ViewModel Sınıfı
class AdvisorViewModel extends StateNotifier<AdvisorState> {
  final IAiRepository _repository; // Interface bağımlılığı

  // Başlangıçta "loading" ile başlatıyoruz
  AdvisorViewModel(this._repository) 
      : super(AdvisorState(analysis: const AsyncValue.loading()));

  Future<void> analyzeVehicle(Vehicle vehicle) async {
    // UI'a işlemin başladığını bildir
    state = state.copyWith(analysis: const AsyncValue.loading());

    try {
      // Repository üzerinden veriyi çek (Cache veya Remote)
      final response = await _repository.getVehicleAnalysis(vehicle);
      
      // Başarılı
      state = state.copyWith(analysis: AsyncValue.data(response));
    } catch (e, st) {
      // Hata
      state = state.copyWith(analysis: AsyncValue.error(e, st));
    }
  }
}

// ViewModel Provider
final advisorViewModelProvider = StateNotifierProvider<AdvisorViewModel, AdvisorState>((ref) {
  final repo = ref.watch(aiRepositoryProvider);
  return AdvisorViewModel(repo);
});