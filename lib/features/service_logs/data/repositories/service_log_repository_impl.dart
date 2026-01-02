import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/service_log_repository.dart';
import '../../domain/models/service_log_model.dart';
import '../../../garage/domain/models/vehicle_model.dart';
import '../../../garage/domain/services/km_calculator_service.dart';

class ServiceLogRepositoryImpl implements IServiceLogRepository {
  final FirebaseFirestore _firestore;
  final KmCalculatorService _kmCalculator; // Logic Enjeksiyonu

  ServiceLogRepositoryImpl(this._firestore, this._kmCalculator);

  // Helper Paths
  DocumentReference _userVehicleDoc(String userId, String vehicleId) {
    return _firestore.collection('users').doc(userId).collection('vehicles').doc(vehicleId);
  }

  CollectionReference _logsCollection(String userId, String vehicleId) {
    return _userVehicleDoc(userId, vehicleId).collection('logs');
  }

  @override
  Stream<List<ServiceLog>> getVehicleLogs(String userId, String vehicleId) {
    return _logsCollection(userId, vehicleId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ServiceLog.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  @override
  Future<void> addLogAndRefreshVehicle(String userId, ServiceLog log) async {
    final vehicleRef = _userVehicleDoc(userId, log.vehicleId);
    final newLogRef = _logsCollection(userId, log.vehicleId).doc(); // ID'yi biz üretiyoruz

    // --- ATOMİK TRANSACTION ---
    await _firestore.runTransaction((transaction) async {
      // 1. Aracı Oku (Read before Write kuralı)
      final vehicleSnapshot = await transaction.get(vehicleRef);
      if (!vehicleSnapshot.exists) {
        throw Exception("Araç bulunamadı!");
      }

      final vehicle = Vehicle.fromMap(vehicleSnapshot.data() as Map<String, dynamic>, vehicleSnapshot.id);

      // 2. Log Verisini Hazırla
      final logData = log.toMap();
      logData['createdAt'] = FieldValue.serverTimestamp(); // Server zamanı
      
      // Logu yaz
      transaction.set(newLogRef, logData);

      // 3. KM Mantığını İşlet (KM Calculator Logic)
      // Kural: Eğer servis KM'si > Araç Güncel KM ise güncelle
      if (log.odometerKm > vehicle.currentKm) {
        try {
          // Domain Servisi kullanarak güvenli hesaplama yap (Validation dahil)
          // Not: Log tarihi işlem tarihi olduğu için lastKmUpdateDate olarak log.date kullanılır.
          final updatedVehicle = _kmCalculator.calculateNewStats(
            vehicle, 
            log.odometerKm, 
            DateTime.now() // Güncelleme zamanı olarak "şimdi"yi alıyoruz
          );

          // Aracı güncelle
          transaction.update(vehicleRef, {
            'currentKm': updatedVehicle.currentKm,
            'dailyAvgKm': updatedVehicle.dailyAvgKm,
            'isDailyAvgKmAutoCalculated': updatedVehicle.isDailyAvgKmAutoCalculated,
            'lastKmUpdateDate': Timestamp.fromDate(updatedVehicle.lastKmUpdateDate),
          });
        } catch (e) {
          // KM validation hatası olursa (örn: km düşürme) transaction iptal olmalı mı?
          // Servis kaydı geçmişe dönük giriliyor olabilir. 
          // Bu durumda sadece aracı güncelleme, logu yine de yaz.
          // LOGIC KARARI: Servis KM < Güncel KM ise araç güncellenmez, log yazılır.
          print("KM güncellenmedi (Geçmiş kayıt): $e");
        }
      }
    });
  }

  @override
  Future<void> deleteLog(String userId, String vehicleId, String logId) async {
    await _logsCollection(userId, vehicleId).doc(logId).delete();
  }
}