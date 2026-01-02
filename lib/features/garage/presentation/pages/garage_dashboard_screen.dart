import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/garage_providers.dart';
import '../viewmodels/garage_controller.dart';
import '../../domain/extensions/vehicle_maintenance_logic.dart'; 
import '../../domain/extensions/maintenance_ui_mapper.dart';
// Core Extensions (Label hatasını çözen import)
import '../../../../core/extensions/vehicle_extensions.dart'; 
// Onboarding
import '../../../onboarding/presentation/pages/add_vehicle_wizard_screen.dart';
// Advisor (AI Raporu)
import '../../../advisor/presentation/pages/advisor_report_screen.dart'; 

class GarageDashboardScreen extends ConsumerWidget {
  const GarageDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(userVehiclesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Garajım"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToWizard(context),
          ),
        ],
      ),
      body: vehiclesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Hata: $err")),
        data: (vehicles) {
          if (vehicles.isEmpty) {
            return _buildEmptyState(context);
          }

          final vehicle = vehicles.first;
          final maintenanceState = vehicle.maintenanceState;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // 1. Araç Bilgileri
                Text(
                  "${vehicle.brand} ${vehicle.model}", 
                  style: Theme.of(context).textTheme.headlineMedium
                ),
                Text(
                  "${vehicle.year} • ${vehicle.engine} • ${vehicle.fuelType.label}", // Label artık çalışır
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                ),
                
                const SizedBox(height: 30),

                // 2. Bakım Durumu Göstergesi
                maintenanceState.status == MaintenanceStatus.unknown
                    ? _buildSetupCard(context) 
                    : _buildHealthGauge(context, maintenanceState, vehicle.estimatedKm),

                const SizedBox(height: 30),

                // 3. AI Rapor Butonu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdvisorReportScreen(vehicle: vehicle),
                        ),
                      );
                    },
                    icon: const Icon(Icons.psychology, color: Colors.white),
                    label: const Text("AI Ekspertiz Raporu Oluştur"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                
                const Spacer(),

                // 4. KM Güncelleme
                OutlinedButton.icon(
                  onPressed: () => _showUpdateKmDialog(context, vehicle), 
                  icon: const Icon(Icons.speed),
                  label: const Text("Güncel KM Gir"),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.directions_car_filled_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text("Henüz bir araç eklemediniz.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToWizard(context),
            icon: const Icon(Icons.add),
            label: const Text("Araç Ekle"),
          ),
        ],
      ),
    );
  }

  void _navigateToWizard(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const AddVehicleWizardScreen()));
  }

  Widget _buildHealthGauge(BuildContext context, MaintenanceState state, int estimatedKm) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: state.status.color.withValues(alpha: 0.3), width: 15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(state.status.icon, size: 48, color: state.status.color),
          const SizedBox(height: 10),
          Text(state.message, style: TextStyle(color: state.status.color, fontSize: 20, fontWeight: FontWeight.bold)),
          Text("$estimatedKm KM", style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSetupCard(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20), 
        child: Text("Bakım verisi bulunamadı.")
      )
    );
  }

  void _showUpdateKmDialog(BuildContext context, var vehicle) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _UpdateKmDialog(vehicle: vehicle),
    );
  }
}

class _UpdateKmDialog extends ConsumerStatefulWidget {
  final dynamic vehicle;
  const _UpdateKmDialog({required this.vehicle});

  @override
  ConsumerState<_UpdateKmDialog> createState() => _UpdateKmDialogState();
}

class _UpdateKmDialogState extends ConsumerState<_UpdateKmDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.vehicle.estimatedKm.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(garageControllerProvider);

    ref.listen(garageControllerProvider, (previous, next) {
      if (next.isSuccess) {
        Navigator.pop(context);
        ref.read(garageControllerProvider.notifier).resetState();
      }
    });

    return AlertDialog(
      title: const Text("KM Güncelle"),
      content: TextField(
        controller: _controller, 
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(suffixText: "KM"),
      ),
      actions: [
        if (state.isLoading)
          const CircularProgressIndicator()
        else ...[
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(_controller.text);
              if (val != null) {
                ref.read(garageControllerProvider.notifier).updateKm(widget.vehicle, val);
              }
            },
            child: const Text("Kaydet"),
          ),
        ]
      ],
    );
  }
}