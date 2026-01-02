import 'package:flutter_test/flutter_test.dart';
import 'package:oto_asist/features/garage/domain/models/vehicle_model.dart';

void main() {
  group('Vehicle Model Tests', () {
    test('estimatedKm should calculate correctly', () {
      final vehicle = Vehicle(
        id: 'test-id',
        userId: 'user-1',
        brand: 'Volkswagen',
        model: 'Golf',
        year: 2020,
        fuelType: FuelType.diesel,
        engine: '1.6 TDI',
        transmission: TransmissionType.manual,
        currentKm: 100000,
        lastKmUpdateDate: DateTime.now().subtract(const Duration(days: 30)),
        dailyAvgKm: 50.0,
      );

      // 30 gün * 50 km/gün = 1500 km
      expect(vehicle.estimatedKm, 101500);
    });

    test('estimatedKm should cap at 180 days', () {
      final vehicle = Vehicle(
        id: 'test-id',
        userId: 'user-1',
        brand: 'Volkswagen',
        model: 'Golf',
        year: 2020,
        fuelType: FuelType.diesel,
        engine: '1.6 TDI',
        transmission: TransmissionType.manual,
        currentKm: 100000,
        lastKmUpdateDate: DateTime.now().subtract(const Duration(days: 365)),
        dailyAvgKm: 50.0,
      );

      // 180 gün cap: 180 * 50 = 9000 km
      expect(vehicle.estimatedKm, 109000);
    });

    test('toMap and fromMap should be reversible', () {
      final original = Vehicle(
        id: 'test-id',
        userId: 'user-1',
        brand: 'Volkswagen',
        model: 'Golf',
        year: 2020,
        fuelType: FuelType.diesel,
        engine: '1.6 TDI',
        transmission: TransmissionType.manual,
        currentKm: 100000,
        lastKmUpdateDate: DateTime.now(),
        dailyAvgKm: 50.0,
      );

      final map = original.toMap();
      final restored = Vehicle.fromMap(map, 'test-id');

      expect(restored.brand, original.brand);
      expect(restored.model, original.model);
      expect(restored.year, original.year);
      expect(restored.fuelType, original.fuelType);
      expect(restored.currentKm, original.currentKm);
    });

    test('copyWith should update only specified fields', () {
      final original = Vehicle(
        id: 'test-id',
        userId: 'user-1',
        brand: 'Volkswagen',
        model: 'Golf',
        year: 2020,
        fuelType: FuelType.diesel,
        engine: '1.6 TDI',
        transmission: TransmissionType.manual,
        currentKm: 100000,
        lastKmUpdateDate: DateTime.now(),
        dailyAvgKm: 50.0,
      );

      final updated = original.copyWith(currentKm: 110000);

      expect(updated.currentKm, 110000);
      expect(updated.brand, original.brand); // Değişmedi
      expect(updated.model, original.model); // Değişmedi
    });
  });
}

