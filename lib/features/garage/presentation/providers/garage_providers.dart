import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/vehicle_repository_impl.dart';
import '../../domain/repositories/vehicle_repository.dart';
import '../../domain/models/vehicle_model.dart';
import '../../domain/services/km_calculator_service.dart';

// 1. Core Providers
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final authProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// 2. Repository Provider
final vehicleRepositoryProvider = Provider<IVehicleRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return VehicleRepositoryImpl(firestore);
});

// 3. Logic Service
final kmCalculatorProvider = Provider<KmCalculatorService>((ref) {
  return KmCalculatorService();
});

// 4. User Vehicles Stream (Ana Akış)
final userVehiclesProvider = StreamProvider.autoDispose<List<Vehicle>>((ref) {
  final auth = ref.watch(authProvider);
  final repo = ref.watch(vehicleRepositoryProvider);
  
  // Auth state değişikliklerini dinlemek yerine direkt user kontrolü 
  // (Daha reaktif olması için authStateChanges dinlenebilir ama şimdilik bu yeterli)
  final user = auth.currentUser;
  
  if (user == null) {
    // Explicit type belirterek boş stream dönüyoruz
    return const Stream<List<Vehicle>>.empty();
  }
  
  return repo.getUserVehicles(user.uid);
});