import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/vehicle_wizard_viewmodel.dart';
import '../../data/repositories/master_data_repository.dart';
import '../../../garage/domain/models/vehicle_model.dart';
import '../../../../core/extensions/vehicle_extensions.dart'; 
import '../../../garage/presentation/providers/garage_providers.dart';

class AddVehicleWizardScreen extends ConsumerWidget {
  const AddVehicleWizardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vehicleWizardProvider);
    final viewModel = ref.read(vehicleWizardProvider.notifier);
    
    final steps = ["Araç Kimliği", "Teknik Özellikler", "Son Durum"];

    return Scaffold(
      appBar: AppBar(
        title: Text("Yeni Araç Ekle (${state.currentStep + 1}/3)"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            value: (state.currentStep + 1) / 3,
            backgroundColor: Colors.grey.shade200,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              steps[state.currentStep],
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildStepContent(context, ref, state),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                if (state.currentStep > 0)
                  TextButton(
                    onPressed: state.isLoading ? null : viewModel.previousStep,
                    child: const Text("Geri"),
                  ),
                const Spacer(),
                ElevatedButton(
                  onPressed: state.isLoading 
                    ? null 
                    : () => _onNextPressed(context, ref, state),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(120, 50)),
                  child: state.isLoading 
                    ? const SizedBox(
                        height: 20, 
                        width: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                      ) 
                    : Text(state.currentStep == 2 ? "Tamamla" : "İleri"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(BuildContext context, WidgetRef ref, WizardState state) {
    final masterDataRepo = ref.read(masterDataRepositoryProvider); 
    final viewModel = ref.read(vehicleWizardProvider.notifier);

    switch (state.currentStep) {
      case 0: 
        return Column(
          children: [
            FutureBuilder<List<String>>(
              future: masterDataRepo.getBrands(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();
                return DropdownButtonFormField<String>(
                  value: state.selectedBrand,
                  decoration: const InputDecoration(labelText: "Marka", border: OutlineInputBorder()),
                  items: snapshot.data!.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                  onChanged: (val) { if (val != null) viewModel.setBrand(val); },
                );
              },
            ),
            const SizedBox(height: 16),
            if (state.selectedBrand != null)
              FutureBuilder<List<String>>(
                future: masterDataRepo.getModels(state.selectedBrand!),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  return DropdownButtonFormField<String>(
                    key: ValueKey(state.selectedBrand), 
                    value: state.selectedModel,
                    decoration: const InputDecoration(labelText: "Model", border: OutlineInputBorder()),
                    items: snapshot.data!.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (val) { if (val != null) viewModel.setModel(val); },
                  );
                },
              ),
            const SizedBox(height: 16),
            if (state.selectedModel != null)
              DropdownButtonFormField<int>(
                value: state.selectedYear,
                decoration: const InputDecoration(labelText: "Model Yılı", border: OutlineInputBorder()),
                items: masterDataRepo.getYears().map((y) => DropdownMenuItem(value: y, child: Text("$y"))).toList(),
                onChanged: (val) { if (val != null) viewModel.setYear(val); },
              ),
          ],
        );

      case 1: 
        return Column(
          children: [
            DropdownButtonFormField<FuelType>(
              value: state.selectedFuel,
              decoration: const InputDecoration(labelText: "Yakıt Tipi", border: OutlineInputBorder()),
              items: FuelType.values.map((f) => DropdownMenuItem(value: f, child: Text(f.label))).toList(),
              onChanged: (val) { if (val != null) viewModel.setFuel(val); },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TransmissionType>(
              value: state.selectedTransmission,
              decoration: const InputDecoration(labelText: "Şanzıman", border: OutlineInputBorder()),
              items: TransmissionType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
              onChanged: (val) { if (val != null) viewModel.setTransmission(val); },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: state.engineInput,
              decoration: const InputDecoration(
                labelText: "Motor Hacmi / Gücü", 
                hintText: "Örn: 1.6 TDI 110 HP", 
                border: OutlineInputBorder()
              ),
              onChanged: (val) => viewModel.setEngine(val),
            ),
          ],
        );

      case 2: 
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.speed, size: 80, color: Colors.blueGrey),
            const SizedBox(height: 20),
            const Text("Aracın şu anki kilometresi nedir?", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            TextFormField(
              initialValue: state.kmInput?.toString(),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(suffixText: "KM", border: OutlineInputBorder()),
              onChanged: (val) {
                final km = int.tryParse(val);
                if (km != null) viewModel.setKm(km);
              },
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  Future<void> _onNextPressed(BuildContext context, WidgetRef ref, WizardState state) async {
    final viewModel = ref.read(vehicleWizardProvider.notifier);
    final navigator = Navigator.of(context); // Navigator referansını erken alıyoruz
    
    // Validasyonlar
    if (state.currentStep == 0 && !state.isStep1Valid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen tüm alanları doldurun.")));
      return;
    }
    if (state.currentStep == 1 && !state.isStep2Valid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Motor bilgisi giriniz.")));
      return;
    }
    if (state.currentStep == 2 && !state.isStep3Valid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("KM bilgisi giriniz.")));
      return;
    }

    if (state.currentStep == 2) {
      final auth = ref.read(authProvider);
      if (auth.currentUser != null) {
        try {
          // Firebase'e kaydetme işlemini bekle
          await viewModel.submitVehicle(auth.currentUser!.uid);
          
          // İşlem bittiğinde ekranı kapat
          if (navigator.canPop()) {
            navigator.pop();
            // Geri dönülen ekranda (Garaj) bildirimi göster
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Araç başarıyla eklendi! 🚗"))
              );
            }
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red)
            );
          }
        }
      }
    } else {
      viewModel.nextStep();
    }
  }
}