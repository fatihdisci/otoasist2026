import '../models/vehicle_model.dart';

abstract class IVehicleRepository {
  // Kullanıcının araçlarını getir (Subcollection dinler)
  Stream<List<Vehicle>> getUserVehicles(String userId);

  // Yeni araç ekle - Geriye oluşturulan ID'yi döner
  Future<String> addVehicle(String userId, Vehicle vehicle);

  // KM güncelleme (userId güvenlik için eklendi)
  Future<void> updateKmInfo({
    required String userId,
    required String vehicleId,
    required int newKm,
    required double newDailyAvg,
    required bool isAutoCalculated,
    required DateTime updateDate,
  });

  // Araç sil (userId patika için zorunlu)
  Future<void> deleteVehicle({required String userId, required String vehicleId});
}