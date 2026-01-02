import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // TextInputFormatter için
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/service_log_model.dart';
import '../viewmodels/service_log_viewmodel.dart';
import '../../../garage/domain/models/vehicle_model.dart';
import '../../../garage/presentation/providers/garage_providers.dart';

class AddServiceLogScreen extends ConsumerStatefulWidget {
  final Vehicle vehicle;

  const AddServiceLogScreen({super.key, required this.vehicle});

  @override
  ConsumerState<AddServiceLogScreen> createState() => _AddServiceLogScreenState();
}

class _AddServiceLogScreenState extends ConsumerState<AddServiceLogScreen> {
  final _formKey = GlobalKey<FormState>();
  ServiceType _selectedType = ServiceType.maintenance;
  
  late DateTime _selectedDate;
  late TextEditingController _kmController;
  late TextEditingController _costController;

  final List<TextEditingController> _itemControllers = [TextEditingController()];
  final _complaintController = TextEditingController();
  final _diagnosisController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _kmController = TextEditingController();
    _costController = TextEditingController();
  }

  @override
  void dispose() {
    _kmController.dispose();
    _costController.dispose();
    // Memory Leak Fix: Listedeki tüm controller'ları dispose et
    for (var c in _itemControllers) { c.dispose(); }
    _complaintController.dispose();
    _diagnosisController.dispose();
    super.dispose();
  }

  // Helper: Türk Para Formatı Çevirici
  // 1.250,50 -> 1250.50
  double? _parseTurkishCurrency(String input) {
    String clean = input.trim();
    // Binlik ayracı olan noktaları kaldır
    clean = clean.replaceAll('.', '');
    // Ondalık ayracı olan virgülü noktaya çevir
    clean = clean.replaceAll(',', '.');
    return double.tryParse(clean);
  }

  // Helper: Controller Silme (Güvenli)
  void _removeItemController(int index) {
    final controller = _itemControllers[index];
    controller.dispose(); // ÖNCE DISPOSE
    setState(() {
      _itemControllers.removeAt(index); // SONRA REMOVE
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(serviceLogViewModelProvider);
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Kayıt Ekle")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<ServiceType>(
              segments: const [
                ButtonSegment(value: ServiceType.maintenance, label: Text("Periyodik Bakım"), icon: Icon(Icons.build)),
                ButtonSegment(value: ServiceType.repair, label: Text("Arıza / Onarım"), icon: Icon(Icons.warning)),
              ],
              selected: {_selectedType},
              onSelectionChanged: (Set<ServiceType> newSelection) {
                setState(() => _selectedType = newSelection.first);
              },
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _kmController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Sadece rakam
                    decoration: const InputDecoration(
                      labelText: "Kilometre", 
                      suffixText: "KM", 
                      hintText: "Örn: 125000",
                      border: OutlineInputBorder()
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return "Zorunlu";
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _selectedDate = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: "Tarih", border: OutlineInputBorder()),
                      child: Text(DateFormat("dd.MM.yyyy").format(_selectedDate)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _costController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: "Toplam Maliyet", 
                suffixText: "₺", 
                hintText: "Örn: 1.250,50",
                border: OutlineInputBorder()
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return "Zorunlu";
                if (_parseTurkishCurrency(val) == null) return "Geçersiz format";
                return null;
              },
            ),
            const SizedBox(height: 20),

            if (_selectedType == ServiceType.maintenance) _buildMaintenanceFields(),
            if (_selectedType == ServiceType.repair) _buildRepairFields(),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: state.isLoading ? null : () async {
                if (_formKey.currentState!.validate()) {
                  await _submitForm(auth.currentUser?.uid);
                }
              },
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              child: state.isLoading 
                  ? const CircularProgressIndicator() 
                  : const Text("Kaydı Tamamla"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Yapılan İşlemler", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        ..._itemControllers.asMap().entries.map((entry) {
          final index = entry.key;
          final controller = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: "Örn: Yağ Filtresi",
                      prefixIcon: const Icon(Icons.check, size: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty) ? "Boş bırakılamaz" : null,
                  ),
                ),
                if (_itemControllers.length > 1)
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => _removeItemController(index), // Güvenli silme
                  )
              ],
            ),
          );
        }).toList(),
        TextButton.icon(
          onPressed: () => setState(() => _itemControllers.add(TextEditingController())),
          icon: const Icon(Icons.add),
          label: const Text("İşlem Ekle"),
        ),
      ],
    );
  }

  Widget _buildRepairFields() {
    return Column(
      children: [
        TextFormField(
          controller: _complaintController,
          maxLines: 2,
          decoration: const InputDecoration(labelText: "Şikayet", border: OutlineInputBorder()),
          validator: (val) => (val == null || val.trim().isEmpty) ? "Zorunlu" : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _diagnosisController,
          maxLines: 2,
          decoration: const InputDecoration(labelText: "Teşhis / Onarım", border: OutlineInputBorder()),
          validator: (val) => (val == null || val.trim().isEmpty) ? "Zorunlu" : null,
        ),
      ],
    );
  }

  Future<void> _submitForm(String? userId) async {
    if (userId == null) return;

    final km = int.parse(_kmController.text);
    final cost = _parseTurkishCurrency(_costController.text)!; // Validator kontrol etti

    ServiceLog log;

    // Factory Constructor'lar kullanımı
    if (_selectedType == ServiceType.maintenance) {
      log = ServiceLog.createMaintenance(
        vehicleId: widget.vehicle.id,
        date: _selectedDate,
        odometerKm: km,
        cost: cost,
        items: _itemControllers.map((c) => c.text.trim()).toList(),
      );
    } else {
      log = ServiceLog.createRepair(
        vehicleId: widget.vehicle.id,
        date: _selectedDate,
        odometerKm: km,
        cost: cost,
        complaint: _complaintController.text.trim(),
        diagnosis: _diagnosisController.text.trim(),
      );
    }

    try {
      await ref.read(serviceLogViewModelProvider.notifier).addLog(
        userId: userId, 
        log: log
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kayıt başarıyla eklendi.")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
  }
}