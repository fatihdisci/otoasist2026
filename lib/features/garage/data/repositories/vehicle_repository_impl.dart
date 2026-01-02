import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/vehicle_model.dart';
import '../../domain/repositories/vehicle_repository.dart';

class VehicleRepositoryImpl implements IVehicleRepository {
  final FirebaseFirestore _firestore;

  VehicleRepositoryImpl(this._firestore);

  // Yardımcı: Kullanıcıya özel koleksiyon referansı
  CollectionReference _userVehiclesRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('vehicles');
  }

  @override
  Stream<List<Vehicle>> getUserVehicles(String userId) {
    return _userVehiclesRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        // Doc ID'yi modele enjekte ediyoruz
        return Vehicle.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  @override
  Future<String> addVehicle(String userId, Vehicle vehicle) async {
    // ID üretimini burada yapıyoruz (Repo sorumluluğu)
    // Vehicle modelindeki 'id' alanı boş gelse bile burada doc.id ile eşleşecek.
    final docRef = _userVehiclesRef(userId).doc();
    
    // Oluşan ID'yi modele yazıp kaydediyoruz
    final vehicleWithId = vehicle.copyWith(id: docRef.id);
    await docRef.set(vehicleWithId.toMap());
    
    return docRef.id;
  }

  @override
  Future<void> updateKmInfo({
    required String userId,
    required String vehicleId,
    required int newKm,
    required double newDailyAvg,
    required bool isAutoCalculated,
    required DateTime updateDate,
  }) async {
    // Race Condition Notu: İleride çok sık güncelleme olursa Transaction kullanılmalı.
    // Şimdilik MVP için doğrudan update yeterli.
    await _userVehiclesRef(userId).doc(vehicleId).update({
      'currentKm': newKm,
      'dailyAvgKm': newDailyAvg,
      'isDailyAvgKmAutoCalculated': isAutoCalculated,
      'lastKmUpdateDate': Timestamp.fromDate(updateDate),
    });
  }

  @override
  Future<void> deleteVehicle({required String userId, required String vehicleId}) async {
    await _userVehiclesRef(userId).doc(vehicleId).delete();
  }
}