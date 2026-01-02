import 'package:flutter_test/flutter_test.dart';
import 'package:oto_asist/features/garage/domain/models/vehicle_model.dart';
import 'package:oto_asist/features/garage/domain/services/km_calculator_service.dart';

void main() {
  group('KmCalculatorService Tests', () {
    late KmCalculatorService calculator;
    late Vehicle testVehicle;

    setUp(() {
      calculator = KmCalculatorService();
      testVehicle = Vehicle(
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
    });

    test('should calculate new stats correctly', () {
      final newKm = 105000;
      final newDate = DateTime.now();

      final result = calculator.calculateNewStats(testVehicle, newKm, newDate);

      expect(result.currentKm, newKm);
      expect(result.lastKmUpdateDate, newDate);
      expect(result.dailyAvgKm, greaterThan(0));
    });

    test('should throw exception when newKm is less than currentKm', () {
      final newKm = 90000; // Düşük KM

      expect(
        () => calculator.calculateNewStats(testVehicle, newKm, DateTime.now()),
        throwsA(isA<KmValidationException>()),
      );
    });

    test('should update dailyAvgKm when valid data provided', () {
      final newKm = 101500; // 30 günde 1500 km
      final newDate = DateTime.now();

      final result = calculator.calculateNewStats(testVehicle, newKm, newDate);

      // 1500 km / 30 gün = 50 km/gün (yaklaşık)
      expect(result.dailyAvgKm, closeTo(50.0, 5.0));
      expect(result.isDailyAvgKmAutoCalculated, true);
    });

    test('should preserve old dailyAvgKm when time difference is too small', () {
      final newKm = 100100;
      final newDate = testVehicle.lastKmUpdateDate.add(const Duration(minutes: 30));

      final result = calculator.calculateNewStats(testVehicle, newKm, newDate);

      // Çok kısa süre, eski ortalama korunmalı
      expect(result.dailyAvgKm, testVehicle.dailyAvgKm);
    });
  });
}

