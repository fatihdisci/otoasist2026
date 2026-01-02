import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/service_log_model.dart';
import '../../domain/repositories/service_log_repository.dart';
import '../providers/service_log_providers.dart';

// UI State: İşlem durumu ve olası hataları tutar
class ServiceLogState {
  final bool isLoading;
  final String? error;
  
  ServiceLogState({this.isLoading = false, this.error});
}

class ServiceLogViewModel extends StateNotifier<ServiceLogState> {
  final IServiceLogRepository _repo;

  ServiceLogViewModel(this._repo) : super(ServiceLogState());

  /// Yeni kayıt ekler ve Transaction ile araç KM'sini günceller.
  /// [userId]: İşlemi yapan kullanıcı
  /// [log]: Eklenecek kayıt modeli
  Future<void> addLog({
    required String userId, 
    required ServiceLog log
  }) async {
    // Loading başlat
    state = ServiceLogState(isLoading: true);
    
    try {
      // Repository'deki Transactional metodu çağır
      // (Hem logu ekler hem de gerekiyorsa araç KM'sini günceller)
      await _repo.addLogAndRefreshVehicle(userId, log);
      
      // Başarılı: Loading durdur
      state = ServiceLogState(isLoading: false);
    } catch (e) {
      // Hata: State'e yaz ve UI'ın Snackbar göstermesi için fırlat
      state = ServiceLogState(isLoading: false, error: "Kayıt eklenemedi: $e");
      rethrow; 
    }
  }

  /// Kayıt siler.
  Future<void> deleteLog(String userId, String vehicleId, String logId) async {
    // Silme işlemi genellikle hızlıdır, global loading yerine 
    // UI tarafında optimistic update veya sessiz işlem yapılabilir.
    // Ancak hata olursa bildirmek gerekir.
    try {
      await _repo.deleteLog(userId, vehicleId, logId);
    } catch (e) {
      state = ServiceLogState(error: "Silme işlemi başarısız: $e");
      rethrow;
    }
  }
}

// Provider Tanımı
final serviceLogViewModelProvider = StateNotifierProvider<ServiceLogViewModel, ServiceLogState>((ref) {
  final repo = ref.watch(serviceLogRepositoryProvider);
  return ServiceLogViewModel(repo);
});