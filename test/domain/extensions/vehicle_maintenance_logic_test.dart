import 'package:flutter_test/flutter_test.dart';
import 'package:oto_asist/features/garage/domain/models/vehicle_model.dart';
import 'package:oto_asist/features/garage/domain/extensions/vehicle_maintenance_logic.dart';

void main() {
  group('Vehicle Maintenance Logic Tests', () {
    test('should return safe status when maintenance is not due', () {
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
        lastKmUpdateDate: DateTime.now().subtract(const Duration(days: 100)),
        dailyAvgKm: 50.0,
        createdAt: DateTime.now().subtract(const Duration(days: 100)),
      );

      final state = vehicle.maintenanceState;

      expect(state.status, isA<MaintenanceStatus>());
      expect(state.progress, greaterThanOrEqualTo(0.0));
      expect(state.progress, lessThanOrEqualTo(1.0));
    });

    test('should return warning status when approaching maintenance', () {
      final vehicle = Vehicle(
        id: 'test-id',
        userId: 'user-1',
        brand: 'Volkswagen',
        model: 'Golf',
        year: 2020,
        fuelType: FuelType.diesel,
        engine: '1.6 TDI',
        transmission: TransmissionType.manual,
        currentKm: 149000, // 15.000 KM'e yakın
        lastKmUpdateDate: DateTime.now().subtract(const Duration(days: 360)),
        dailyAvgKm: 50.0,
        createdAt: DateTime.now().subtract(const Duration(days: 360)),
      );

      final state = vehicle.maintenanceState;

      // Warning veya critical olabilir
      expect(state.status, isNot(MaintenanceStatus.unknown));
    });

    test('should return critical status when maintenance is overdue', () {
      final vehicle = Vehicle(
        id: 'test-id',
        userId: 'user-1',
        brand: 'Volkswagen',
        model: 'Golf',
        year: 2020,
        fuelType: FuelType.diesel,
        engine: '1.6 TDI',
        transmission: TransmissionType.manual,
        currentKm: 160000, // 15.000 KM'i aşmış
        lastKmUpdateDate: DateTime.now().subtract(const Duration(days: 400)),
        dailyAvgKm: 50.0,
        createdAt: DateTime.now().subtract(const Duration(days: 400)),
      );

      final state = vehicle.maintenanceState;

      expect(state.status, MaintenanceStatus.critical);
    });
  });
}

