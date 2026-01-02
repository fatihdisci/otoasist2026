import 'package:cloud_firestore/cloud_firestore.dart';

// Enumlar
enum FuelType { gasoline, diesel, hybrid, electric, lpg }
enum TransmissionType { manual, automatic, semiAutomatic, cvt }

class Vehicle {
  final String id;
  final String userId;
  
  // --- 7 Kritik Parametre ---
  final String brand;
  final String model;
  final int year;
  final FuelType fuelType;
  final String engine;
  final TransmissionType transmission;
  final int currentKm;
  
  // --- Hesaplamalı ve Sistem Verileri ---
  final DateTime lastKmUpdateDate;
  final double dailyAvgKm;
  final bool isDailyAvgKmAutoCalculated;
  final DateTime? createdAt;

  Vehicle({
    required this.id,
    required this.userId,
    required this.brand,
    required this.model,
    required this.year,
    required this.fuelType,
    required this.engine,
    required this.transmission,
    required this.currentKm,
    required this.lastKmUpdateDate,
    this.dailyAvgKm = 35.0,
    this.isDailyAvgKmAutoCalculated = false,
    this.createdAt,
  });

  // --- Güvenli Tahmin Motoru (Capped) ---
  int get estimatedKm {
    final daysDiff = DateTime.now().difference(lastKmUpdateDate).inDays;
    
    if (daysDiff <= 0) return currentKm;

    // KORUMA: 6 aydan fazla giriş yoksa tahmini durdur.
    final cappedDays = daysDiff.clamp(0, 180); 
    
    return currentKm + (cappedDays * dailyAvgKm).round();
  }

  // --- Serialization ---
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'brand': brand,
      'model': model,
      'year': year,
      'fuelType': fuelType.name,
      'engine': engine,
      'transmission': transmission.name,
      'currentKm': currentKm,
      'lastKmUpdateDate': Timestamp.fromDate(lastKmUpdateDate),
      'dailyAvgKm': dailyAvgKm,
      'isDailyAvgKmAutoCalculated': isDailyAvgKmAutoCalculated,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  factory Vehicle.fromMap(Map<String, dynamic> map, String docId) {
    return Vehicle(
      id: docId,
      userId: map['userId'] ?? '',
      brand: map['brand'] ?? '',
      model: map['model'] ?? '',
      year: map['year'] ?? 0,
      fuelType: FuelType.values.firstWhere(
        (e) => e.name == map['fuelType'], 
        orElse: () => FuelType.gasoline
      ),
      engine: map['engine'] ?? '',
      transmission: TransmissionType.values.firstWhere(
        (e) => e.name == map['transmission'],
        orElse: () => TransmissionType.manual
      ),
      currentKm: map['currentKm'] ?? 0,
      lastKmUpdateDate: map['lastKmUpdateDate'] != null 
          ? (map['lastKmUpdateDate'] as Timestamp).toDate() 
          : DateTime.now(),
      dailyAvgKm: (map['dailyAvgKm'] ?? 35.0).toDouble(),
      isDailyAvgKmAutoCalculated: map['isDailyAvgKmAutoCalculated'] ?? false,
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate() 
          : null,
    );
  }

  // GÜNCEL COPYWITH: id ve userId eklendi
  Vehicle copyWith({
    String? id,
    String? userId,
    String? brand,
    String? model,
    int? currentKm,
    DateTime? lastKmUpdateDate,
    double? dailyAvgKm,
    bool? isDailyAvgKmAutoCalculated,
  }) {
    return Vehicle(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year,
      fuelType: fuelType,
      engine: engine,
      transmission: transmission,
      currentKm: currentKm ?? this.currentKm,
      lastKmUpdateDate: lastKmUpdateDate ?? this.lastKmUpdateDate,
      dailyAvgKm: dailyAvgKm ?? this.dailyAvgKm,
      isDailyAvgKmAutoCalculated: isDailyAvgKmAutoCalculated ?? this.isDailyAvgKmAutoCalculated,
      createdAt: createdAt,
    );
  }
}