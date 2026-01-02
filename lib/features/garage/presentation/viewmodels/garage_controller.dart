import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/vehicle_model.dart';
import '../../domain/services/km_calculator_service.dart'; // Exception buradan gelir
import '../providers/garage_providers.dart';

class GarageState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess; // UI'da dialog kapatmak veya toast göstermek için

  GarageState({this.isLoading = false, this.errorMessage, this.isSuccess = false});
}

class GarageController extends StateNotifier<GarageState> {
  final Ref _ref;

  GarageController(this._ref) : super(GarageState());

  Future<void> updateKm(Vehicle vehicle, int newKm) async {
    // Validasyon: UI tarafında boş kontrolü yapılmış olsa da burada da Logic öncesi basit check
    if (newKm < 0) return;

    try {
      state = GarageState(isLoading: true);

      final calculator = _ref.read(kmCalculatorProvider);
      
      // Domain Exception fırlatabilir (Örn: KmValidationException)
      final updatedVehicle = calculator.calculateNewStats(vehicle, newKm, DateTime.now());

      await _ref.read(vehicleRepositoryProvider).updateKmInfo(
            userId: vehicle.userId,
            vehicleId: vehicle.id,
            newKm: updatedVehicle.currentKm,
            newDailyAvg: updatedVehicle.dailyAvgKm,
            isAutoCalculated: updatedVehicle.isDailyAvgKmAutoCalculated,
            updateDate: updatedVehicle.lastKmUpdateDate,
          );

      state = GarageState(isLoading: false, isSuccess: true);
    } on KmValidationException catch (e) {
      // Domain hatası: Kullanıcıya gösterilebilir, güvenli mesaj.
      state = GarageState(isLoading: false, errorMessage: e.message);
    } catch (e) {
      // Teknik hata: Logla ama kullanıcıya genel mesaj dön.
      state = GarageState(isLoading: false, errorMessage: "Güncelleme sırasında bir sorun oluştu.");
    }
  }
  
  // State'i resetlemek için (Dialog kapandıktan sonra vb.)
  void resetState() {
    state = GarageState();
  }
}

final garageControllerProvider = StateNotifierProvider<GarageController, GarageState>((ref) {
  return GarageController(ref);
});