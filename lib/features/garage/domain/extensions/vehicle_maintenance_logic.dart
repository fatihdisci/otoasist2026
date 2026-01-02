import '../models/vehicle_model.dart';

enum MaintenanceStatus { 
  safe, 
  warning, 
  critical, 
  unknown // Yeni: Bakım verisi girilmemişse
}

class MaintenanceState {
  final MaintenanceStatus status;
  final String message;
  final double progress; // 0.0 ile 1.0 arası garantili
  final bool isKmDriven; // Sorun KM kaynaklı mı Tarih kaynaklı mı?

  MaintenanceState({
    required this.status, 
    required this.message, 
    required this.progress,
    required this.isKmDriven,
  });
}

extension VehicleMaintenanceLogic on Vehicle {
  // Configs (İleride RemoteConfig'den gelebilir)
  static const int _targetIntervalKm = 15000;
  static const int _targetIntervalDays = 365;
  static const int _warningThresholdKm = 1000;
  static const int _warningThresholdDays = 30;

  MaintenanceState get maintenanceState {
    // NOT: İleride ServiceLogs entegrasyonu ile burası dinamikleşecek.
    // Şimdilik varsayılan değerlerle çalışıyor.

    // --- 1. Hesaplama ---
    final int lastMaintenanceKm = 0; 
    final DateTime lastMaintenanceDate = createdAt ?? DateTime.now();

    final int remainingKm = (lastMaintenanceKm + _targetIntervalKm) - estimatedKm;
    
    final DateTime targetDate = lastMaintenanceDate.add(const Duration(days: _targetIntervalDays));
    final int remainingDays = targetDate.difference(DateTime.now()).inDays;

    // --- 2. Normalizasyon & Clamp (UI Taşmasını Önle) ---
    double kmProgress = (estimatedKm - lastMaintenanceKm) / _targetIntervalKm;
    kmProgress = kmProgress.clamp(0.0, 1.0); // 0..1 garantisi

    double timeProgress = (DateTime.now().difference(lastMaintenanceDate).inDays) / _targetIntervalDays;
    timeProgress = timeProgress.clamp(0.0, 1.0);

    // --- 3. Whichever Comes First ---
    // Hangisi bitişe daha yakınsa (progress daha büyükse) o dominanttır.
    final bool isKmDriven = kmProgress >= timeProgress;

    if (isKmDriven) {
      return _evaluateKmState(remainingKm, kmProgress);
    } else {
      return _evaluateDateState(remainingDays, timeProgress);
    }
  }

  MaintenanceState _evaluateKmState(int remaining, double progress) {
    if (remaining <= 0) {
      return MaintenanceState(
          status: MaintenanceStatus.critical,
          message: "KM Sınırı Aşıldı!",
          progress: 1.0,
          isKmDriven: true);
    } else if (remaining < _warningThresholdKm) {
      return MaintenanceState(
          status: MaintenanceStatus.warning,
          message: "$remaining KM Kaldı",
          progress: progress,
          isKmDriven: true);
    } else {
      return MaintenanceState(
          status: MaintenanceStatus.safe,
          message: "$remaining KM Kaldı",
          progress: progress,
          isKmDriven: true);
    }
  }

  MaintenanceState _evaluateDateState(int remaining, double progress) {
    if (remaining <= 0) {
      return MaintenanceState(
          status: MaintenanceStatus.critical,
          message: "Süre Doldu!",
          progress: 1.0,
          isKmDriven: false);
    } else if (remaining < _warningThresholdDays) {
      return MaintenanceState(
          status: MaintenanceStatus.warning,
          message: "$remaining Gün Kaldı",
          progress: progress,
          isKmDriven: false);
    } else {
      return MaintenanceState(
          status: MaintenanceStatus.safe,
          message: "$remaining Gün Kaldı",
          progress: progress,
          isKmDriven: false);
    }
  }
}