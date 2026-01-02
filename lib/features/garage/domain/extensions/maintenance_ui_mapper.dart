import 'package:flutter/material.dart';
import '../../domain/extensions/vehicle_maintenance_logic.dart';

extension MaintenanceStatusUI on MaintenanceStatus {
  Color get color {
    switch (this) {
      case MaintenanceStatus.safe: return Colors.green;
      case MaintenanceStatus.warning: return Colors.orange;
      case MaintenanceStatus.critical: return Colors.red;
      case MaintenanceStatus.unknown: return Colors.grey;
    }
  }

  IconData get icon {
    switch (this) {
      case MaintenanceStatus.safe: return Icons.check_circle_outline;
      case MaintenanceStatus.warning: return Icons.warning_amber_rounded;
      case MaintenanceStatus.critical: return Icons.error_outline;
      case MaintenanceStatus.unknown: return Icons.settings_suggest_outlined;
    }
  }
}