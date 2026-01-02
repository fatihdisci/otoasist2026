import 'package:cloud_firestore/cloud_firestore.dart';

enum ServiceType { maintenance, repair }

class ServiceLog {
  final String? id; // Firestore ID'si repo'da oluşur, UI'da null olabilir
  final String vehicleId;
  final ServiceType type;
  final DateTime date;
  final int odometerKm;
  final double cost;
  
  final List<String> performedItems;
  final String? complaint;
  final String? diagnosis;
  final DateTime? createdAt;

  // Private Constructor
  ServiceLog._({
    this.id,
    required this.vehicleId,
    required this.type,
    required this.date,
    required this.odometerKm,
    required this.cost,
    this.performedItems = const [],
    this.complaint,
    this.diagnosis,
    this.createdAt,
  });

String get title {
    if (type == ServiceType.maintenance) {
      return "Periyodik Bakım";
    } else {
      return diagnosis ?? complaint ?? "Onarım Kaydı";
    }
  }

  // --- FACTORY: BAKIM (Maintenance) ---
  factory ServiceLog.createMaintenance({
    String? id,
    required String vehicleId,
    required DateTime date,
    required int odometerKm,
    required double cost,
    required List<String> items,
  }) {
    if (items.isEmpty) {
      throw ArgumentError("Bakım kaydı için en az 1 işlem girilmelidir.");
    }
    return ServiceLog._(
      id: id,
      vehicleId: vehicleId,
      type: ServiceType.maintenance,
      date: date,
      odometerKm: odometerKm,
      cost: cost,
      performedItems: items,
    );
  }

  // --- FACTORY: ONARIM (Repair) ---
  factory ServiceLog.createRepair({
    String? id,
    required String vehicleId,
    required DateTime date,
    required int odometerKm,
    required double cost,
    required String complaint,
    required String diagnosis,
  }) {
    if (complaint.trim().isEmpty || diagnosis.trim().isEmpty) {
      throw ArgumentError("Onarım kaydı için şikayet ve teşhis zorunludur.");
    }
    return ServiceLog._(
      id: id,
      vehicleId: vehicleId,
      type: ServiceType.repair,
      date: date,
      odometerKm: odometerKm,
      cost: cost,
      complaint: complaint,
      diagnosis: diagnosis,
    );
  }

  factory ServiceLog.fromMap(Map<String, dynamic> map, String docId) {
    return ServiceLog._(
      id: docId, // ID burada set edilir
      vehicleId: map['vehicleId'] ?? '',
      type: ServiceType.values.firstWhere((e) => e.name == map['type']),
      date: (map['date'] as Timestamp).toDate(),
      odometerKm: map['odometerKm'] ?? 0,
      cost: (map['cost'] ?? 0).toDouble(),
      performedItems: List<String>.from(map['performedItems'] ?? []),
      complaint: map['complaint'],
      diagnosis: map['diagnosis'],
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vehicleId': vehicleId,
      'type': type.name,
      'date': Timestamp.fromDate(date),
      'odometerKm': odometerKm,
      'cost': cost,
      'performedItems': performedItems,
      'complaint': complaint,
      'diagnosis': diagnosis,
    };
  }
}