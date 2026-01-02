import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/garage/domain/models/vehicle_model.dart';
import '../../../../features/garage/domain/repositories/vehicle_repository.dart';
import '../../../../features/garage/presentation/providers/garage_providers.dart';

// State
class WizardState {
  final int currentStep;
  final String? selectedBrand;
  final String? selectedModel;
  final int? selectedYear;
  final FuelType selectedFuel;
  final TransmissionType selectedTransmission;
  final String engineInput;
  final int? kmInput;
  final bool isLoading; // Çember kontrolü

  WizardState({
    this.currentStep = 0,
    this.selectedBrand,
    this.selectedModel,
    this.selectedYear,
    this.selectedFuel = FuelType.gasoline,
    this.selectedTransmission = TransmissionType.manual,
    this.engineInput = '',
    this.kmInput,
    this.isLoading = false,
  });

  // Validasyonlar
  bool get isStep1Valid => selectedBrand != null && selectedModel != null && selectedYear != null;
  bool get isStep2Valid => engineInput.isNotEmpty;
  bool get isStep3Valid => kmInput != null && kmInput! > 0;

  WizardState copyWith({
    int? currentStep,
    String? selectedBrand,
    String? selectedModel,
    int? selectedYear,
    FuelType? selectedFuel,
    TransmissionType? selectedTransmission,
    String? engineInput,
    int? kmInput,
    bool? isLoading,
  }) {
    return WizardState(
      currentStep: currentStep ?? this.currentStep,
      selectedBrand: selectedBrand ?? this.selectedBrand,
      selectedModel: selectedModel ?? this.selectedModel,
      selectedYear: selectedYear ?? this.selectedYear,
      selectedFuel: selectedFuel ?? this.selectedFuel,
      selectedTransmission: selectedTransmission ?? this.selectedTransmission,
      engineInput: engineInput ?? this.engineInput,
      kmInput: kmInput ?? this.kmInput,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ViewModel
class VehicleWizardViewModel extends StateNotifier<WizardState> {
  final IVehicleRepository _repository;

  VehicleWizardViewModel(this._repository) : super(WizardState());

  void nextStep() {
    if (state.currentStep < 2) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  // Setters
  void setBrand(String val) => state = state.copyWith(selectedBrand: val, selectedModel: null, selectedYear: null);
  void setModel(String val) => state = state.copyWith(selectedModel: val);
  void setYear(int val) => state = state.copyWith(selectedYear: val);
  void setFuel(FuelType val) => state = state.copyWith(selectedFuel: val);
  void setTransmission(TransmissionType val) => state = state.copyWith(selectedTransmission: val);
  void setEngine(String val) => state = state.copyWith(engineInput: val);
  void setKm(int val) => state = state.copyWith(kmInput: val);

  // SAVE VEHICLE (Düzeltilen Kısım)
  Future<void> submitVehicle(String userId) async {
    // 1. Çemberi Başlat
    state = state.copyWith(isLoading: true);

    try {
      final vehicle = Vehicle(
        id: '', // Repo oluşturacak
        userId: userId,
        brand: state.selectedBrand!,
        model: state.selectedModel!,
        year: state.selectedYear!,
        fuelType: state.selectedFuel,
        engine: state.engineInput,
        transmission: state.selectedTransmission,
        currentKm: state.kmInput!,
        lastKmUpdateDate: DateTime.now(),
      );

      await _repository.addVehicle(userId, vehicle);
      
      // Başarılı olduğunda burada ekstra bir şey yapmaya gerek yok,
      // UI tarafı await bitince sayfayı kapatacak.
      
    } catch (e) {
      // Hata olursa UI'a fırlat
      rethrow;
    } finally {
      // 2. İşlem ne olursa olsun çemberi durdur
      if (mounted) {
        state = state.copyWith(isLoading: false);
      }
    }
  }
}

final vehicleWizardProvider = StateNotifierProvider.autoDispose<VehicleWizardViewModel, WizardState>((ref) {
  final repo = ref.watch(vehicleRepositoryProvider);
  return VehicleWizardViewModel(repo);
});