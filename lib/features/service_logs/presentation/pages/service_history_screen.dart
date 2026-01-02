import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/service_log_providers.dart';
import '../widgets/service_log_card.dart';
import 'add_service_log_screen.dart';
import '../../../garage/domain/models/vehicle_model.dart';
import '../viewmodels/service_log_viewmodel.dart';
import '../../../garage/presentation/providers/garage_providers.dart'; // Auth Provider için

class ServiceHistoryScreen extends ConsumerWidget {
  final Vehicle vehicle;

  const ServiceHistoryScreen({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Veri Kaynağı: Logları dinle
    final logsAsync = ref.watch(vehicleLogsProvider(vehicle.id));
    // 2. Auth: Kullanıcı ID'si işlemlerde lazım
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Servis Geçmişi"),
      ),
      
      // Kayıt Ekleme Butonu (FAB)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddServiceLogScreen(vehicle: vehicle),
            ),
          );
        },
        label: const Text("Kayıt Ekle"),
        icon: const Icon(Icons.add),
      ),
      
      body: logsAsync.when(
        // YÜKLENİYOR
        loading: () => const Center(child: CircularProgressIndicator()),
        
        // HATA
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("Veriler yüklenemedi: $err", textAlign: TextAlign.center),
          ),
        ),
        
        // VERİ GELDİ
        data: (logs) {
          // Boş Durum (Empty State)
          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    "Henüz kayıt bulunmuyor.",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Bakım veya onarım işlemlerini ekleyerek\naracınızın karnesini oluşturun.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Liste Görünümü
          return ListView.builder(
            itemCount: logs.length,
            // FAB listenin son elemanını kapatmasın diye alt boşluk
            padding: const EdgeInsets.only(bottom: 80, top: 10),
            itemBuilder: (context, index) {
              final log = logs[index];
              
              return ServiceLogCard(
                log: log,
                onDelete: () async {
                  // Silme Onay Diyaloğu
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Kaydı Sil"),
                      content: const Text("Bu işlem geri alınamaz ve kalıcıdır. Emin misiniz?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text("İptal"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text("Sil", style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );

                  // Kullanıcı onayladıysa ve giriş yapmışsa sil
                  if (confirm == true && auth.currentUser != null) {
                    try {
                      // Log ID'si Firestore'dan okunduğu için null olamaz (!), güvenli.
                      await ref.read(serviceLogViewModelProvider.notifier).deleteLog(
                        auth.currentUser!.uid, 
                        vehicle.id, 
                        log.id! 
                      );
                      
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Kayıt başarıyla silindi.")),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text("Silme işlemi başarısız."),
                            backgroundColor: Colors.red.shade700,
                          ),
                        );
                      }
                    }
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}