import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import '../../domain/models/service_log_model.dart';

class ServiceLogCard extends StatelessWidget {
  final ServiceLog log;
  final VoidCallback onDelete;

  const ServiceLogCard({super.key, required this.log, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isMaintenance = log.type == ServiceType.maintenance;
    final color = isMaintenance ? Colors.green : Colors.orange;
    final icon = isMaintenance ? Icons.build_circle_outlined : Icons.warning_amber_rounded;
    final currencyFormat = NumberFormat.currency(locale: "tr_TR", symbol: "₺");
    final dateFormat = DateFormat("dd MMM yyyy", "tr_TR");

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1), // GÜNCELLENDİ
          child: Icon(icon, color: color),
        ),
        title: Text(
          log.title, 
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(dateFormat.format(log.date)),
        trailing: Text(
          currencyFormat.format(log.cost),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInfoRow(Icons.speed, "Kilometre", "${log.odometerKm} km"),
                const Divider(),
                if (isMaintenance) ...[
                  const Text("Yapılan İşlemler:", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  ...log.performedItems.map((item) => Text("• $item")),
                ] else ...[
                  _buildInfoRow(Icons.feedback_outlined, "Şikayet", log.complaint ?? "-"),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.manage_search, "Teşhis", log.diagnosis ?? "-"),
                ],
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    label: const Text("Kaydı Sil", style: TextStyle(color: Colors.red)),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black87),
              children: [
                TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}