import 'package:flutter_test/flutter_test.dart';
import 'package:oto_asist/features/service_logs/domain/models/service_log_model.dart';

void main() {
  group('ServiceLog Model Tests', () {
    test('createMaintenance should create valid maintenance log', () {
      final log = ServiceLog.createMaintenance(
        vehicleId: 'vehicle-1',
        date: DateTime.now(),
        odometerKm: 100000,
        cost: 1500.0,
        items: ['Yağ değişimi', 'Filtre değişimi'],
      );

      expect(log.type, ServiceType.maintenance);
      expect(log.vehicleId, 'vehicle-1');
      expect(log.odometerKm, 100000);
      expect(log.cost, 1500.0);
      expect(log.performedItems.length, 2);
      expect(log.title, 'Periyodik Bakım');
    });

    test('createMaintenance should throw when items is empty', () {
      expect(
        () => ServiceLog.createMaintenance(
          vehicleId: 'vehicle-1',
          date: DateTime.now(),
          odometerKm: 100000,
          cost: 1500.0,
          items: [],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('createRepair should create valid repair log', () {
      final log = ServiceLog.createRepair(
        vehicleId: 'vehicle-1',
        date: DateTime.now(),
        odometerKm: 100000,
        cost: 5000.0,
        complaint: 'Motor çalışmıyor',
        diagnosis: 'Alternatör arızası',
      );

      expect(log.type, ServiceType.repair);
      expect(log.vehicleId, 'vehicle-1');
      expect(log.odometerKm, 100000);
      expect(log.cost, 5000.0);
      expect(log.complaint, 'Motor çalışmıyor');
      expect(log.diagnosis, 'Alternatör arızası');
      expect(log.title, 'Alternatör arızası');
    });

    test('createRepair should throw when complaint is empty', () {
      expect(
        () => ServiceLog.createRepair(
          vehicleId: 'vehicle-1',
          date: DateTime.now(),
          odometerKm: 100000,
          cost: 5000.0,
          complaint: '',
          diagnosis: 'Test',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('toMap and fromMap should be reversible', () {
      final original = ServiceLog.createMaintenance(
        vehicleId: 'vehicle-1',
        date: DateTime(2024, 1, 15),
        odometerKm: 100000,
        cost: 1500.0,
        items: ['Yağ değişimi'],
      );

      final map = original.toMap();
      final restored = ServiceLog.fromMap(map, 'log-id');

      expect(restored.vehicleId, original.vehicleId);
      expect(restored.type, original.type);
      expect(restored.odometerKm, original.odometerKm);
      expect(restored.cost, original.cost);
      expect(restored.performedItems, original.performedItems);
    });
  });
}

