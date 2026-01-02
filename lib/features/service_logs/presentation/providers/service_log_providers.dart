import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/service_log_repository.dart';
import '../../data/repositories/service_log_repository_impl.dart';
import '../../domain/models/service_log_model.dart';
import '../../../garage/presentation/providers/garage_providers.dart'; // Core providers

// Repository Provider
final serviceLogRepositoryProvider = Provider<IServiceLogRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  // Domain Logic servisini tekrar kullanıyoruz (Code Reusability)
  final kmCalculator = ref.watch(kmCalculatorProvider); 
  
  return ServiceLogRepositoryImpl(firestore, kmCalculator);
});

// Stream Provider
final vehicleLogsProvider = StreamProvider.family<List<ServiceLog>, String>((ref, vehicleId) {
  final auth = ref.watch(authProvider); // Core provider kullanımı
  final repo = ref.watch(serviceLogRepositoryProvider);
  
  final userId = auth.currentUser?.uid;
  if (userId == null) {
    // Tip güvenli boş stream
    return const Stream<List<ServiceLog>>.empty();
  }

  return repo.getVehicleLogs(userId, vehicleId);
});