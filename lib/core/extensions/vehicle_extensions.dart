import '../../features/garage/domain/models/vehicle_model.dart';

extension FuelTypeX on FuelType {
  String get label {
    switch (this) {
      case FuelType.gasoline: return 'Benzin';
      case FuelType.diesel: return 'Dizel';
      case FuelType.hybrid: return 'Hibrit';
      case FuelType.electric: return 'Elektrik';
      case FuelType.lpg: return 'LPG';
    }
  }
}

extension TransmissionTypeX on TransmissionType {
  String get label {
    switch (this) {
      case TransmissionType.manual: return 'Manuel';
      case TransmissionType.automatic: return 'Otomatik';
      case TransmissionType.semiAutomatic: return 'Yarı Otomatik';
      case TransmissionType.cvt: return 'CVT';
    }
  }
}