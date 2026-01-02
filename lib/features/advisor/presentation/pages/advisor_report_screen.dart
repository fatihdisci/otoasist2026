import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/advisor_viewmodel.dart';
import '../widgets/chronic_issue_card.dart';
import '../../../garage/domain/models/vehicle_model.dart';
import '../../../garage/domain/models/ai_response_model.dart';

class AdvisorReportScreen extends ConsumerStatefulWidget {
  final Vehicle vehicle;

  const AdvisorReportScreen({super.key, required this.vehicle});

  @override
  ConsumerState<AdvisorReportScreen> createState() => _AdvisorReportScreenState();
}

class _AdvisorReportScreenState extends ConsumerState<AdvisorReportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _checkedItems = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Açılışta analizi başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(advisorViewModelProvider.notifier).analyzeVehicle(widget.vehicle);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(advisorViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Ekspertiz Raporu"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Risk Analizi", icon: Icon(Icons.analytics)),
            Tab(text: "Kontrol Listesi", icon: Icon(Icons.checklist)),
          ],
        ),
      ),
      body: state.analysis.when(
        // 1. YÜKLENİYOR
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Gemini AI aracı analiz ediyor..."),
              Text("Bu işlem 5-10 saniye sürebilir.", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        
        // 2. HATA (GÜNCELLENDİ: Gerçek hatayı gösteriyor)
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView( // Hata mesajı uzunsa kaydırılabilir olsun
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    "Bağlantı Hatası Oluştu",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      "$err", // Hatanın teknik detayını buraya basıyoruz
                      style: const TextStyle(color: Colors.red, fontFamily: 'Courier'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => ref.read(advisorViewModelProvider.notifier).analyzeVehicle(widget.vehicle),
                    icon: const Icon(Icons.refresh),
                    label: const Text("Tekrar Dene"),
                  )
                ],
              ),
            ),
          ),
        ),
        
        // 3. BAŞARILI
        data: (analysis) {
          if (analysis == null) return const SizedBox(); 

          return TabBarView(
            controller: _tabController,
            children: [
              // SEKME 1
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHealthScoreHeader(analysis.healthScore, analysis.summary),
                  const Divider(height: 30),
                  
                  if (analysis.chronicIssues.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text("Kronik sorun bulunamadı. 🎉", textAlign: TextAlign.center),
                    )
                  else ...[
                    Text("Kronik Sorunlar", style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    ...analysis.chronicIssues.map((issue) => ChronicIssueCard(issue: issue)).toList(),
                  ],
                  const SizedBox(height: 20),
                  _buildNote(analysis.confidenceNote),
                ],
              ),

              // SEKME 2
              ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: analysis.checklist.length,
                itemBuilder: (context, index) {
                  final item = analysis.checklist[index];
                  final isChecked = _checkedItems.contains(item);
                  return Card(
                    color: isChecked ? Colors.green.shade50 : null,
                    child: CheckboxListTile(
                      value: isChecked,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) _checkedItems.add(item);
                          else _checkedItems.remove(item);
                        });
                      },
                      title: Text(item, style: TextStyle(decoration: isChecked ? TextDecoration.lineThrough : null)),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHealthScoreHeader(int score, String summary) {
    Color color = score >= 80 ? Colors.green : (score >= 50 ? Colors.orange : Colors.red);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 4),
          ),
          child: Text("$score", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
        ),
        const SizedBox(height: 16),
        Text(summary, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildNote(String note) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
      child: Text(note, style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12)),
    );
  }
}