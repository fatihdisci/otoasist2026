import 'package:flutter/material.dart';
import '../../../garage/domain/models/ai_response_model.dart'; // Yol düzeltildi

class ChronicIssueCard extends StatelessWidget {
  final ChronicIssue issue;

  const ChronicIssueCard({super.key, required this.issue});

  Color _getRiskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.high: return Colors.red.shade50;
      case RiskLevel.medium: return Colors.orange.shade50;
      case RiskLevel.low: return Colors.green.shade50;
      default: return Colors.grey.shade50; // Default eklendi
    }
  }

  Color _getRiskTextColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.high: return Colors.red.shade900;
      case RiskLevel.medium: return Colors.orange.shade900;
      case RiskLevel.low: return Colors.green.shade900;
      default: return Colors.grey.shade900; // Default eklendi
    }
  }

  String _getRiskLabel(RiskLevel level) {
    switch (level) {
      case RiskLevel.high: return "Yüksek Risk";
      case RiskLevel.medium: return "Orta Risk";
      case RiskLevel.low: return "Düşük Risk";
      default: return "Bilinmiyor"; // Default eklendi
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      color: _getRiskColor(issue.riskLevel),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    issue.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _getRiskTextColor(issue.riskLevel),
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    _getRiskLabel(issue.riskLevel), 
                    style: TextStyle(fontSize: 11, color: _getRiskTextColor(issue.riskLevel)),
                  ),
                  backgroundColor: Colors.white.withValues(alpha: 0.6), // GÜNCELLENDİ
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                )
              ],
            ),
            const SizedBox(height: 6),
            Text(issue.description),
          ],
        ),
      ),
    );
  }
}