import '../models/service_log_model.dart';

abstract class IServiceLogRepository {
  Stream<List<ServiceLog>> getVehicleLogs(String userId, String vehicleId);
  
  // İSMİ GÜNCELLENDİ
  Future<void> addLogAndRefreshVehicle(String userId, ServiceLog log);
  
  Future<void> deleteLog(String userId, String vehicleId, String logId);
}