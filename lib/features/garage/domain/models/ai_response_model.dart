enum RiskLevel { low, medium, high }

class ChronicIssue {
  final String title;
  final String description;
  final RiskLevel riskLevel;

  ChronicIssue({
    required this.title, 
    required this.description, 
    required this.riskLevel
  });

  factory ChronicIssue.fromJson(Map<String, dynamic> json) {
    return ChronicIssue(
      title: (json['title'] ?? '').toString().trim(),
      description: (json['description'] ?? '').toString().trim(),
      riskLevel: RiskLevel.values.firstWhere(
        (e) => e.name == json['risk_level'],
        orElse: () => RiskLevel.medium,
      ),
    );
  }
}

class AiAnalysisResponse {
  final int healthScore;
  final String summary;
  final List<ChronicIssue> chronicIssues;
  final List<String> checklist;
  final String confidenceNote; // Modele eklenen yeni alan

  AiAnalysisResponse({
    required this.healthScore,
    required this.summary,
    required this.chronicIssues,
    required this.checklist,
    required this.confidenceNote,
  });

  factory AiAnalysisResponse.fromJson(Map<String, dynamic> json) {
    // 1. Güvenli Tip Dönüşümü
    int rawScore = json['health_score'] is int ? json['health_score'] : 50;
    
    // 2. Liste Dönüşümleri
    var rawIssues = (json['chronic_issues'] as List<dynamic>?)
            ?.map((e) => ChronicIssue.fromJson(e))
            .toList() ?? [];

    var rawChecklist = (json['checklist'] as List<dynamic>?)
            ?.map((e) => e.toString().trim())
            .toList() ?? [];

    // 3. Normalize Etme ve Validasyon
    return AiAnalysisResponse(
      healthScore: rawScore.clamp(0, 100), // Skor 0-100 arasına sıkıştırıldı
      summary: (json['summary'] ?? '').toString().trim(),
      chronicIssues: rawIssues, // İstenirse .take(10) ile sınır konulabilir
      checklist: rawChecklist,
      confidenceNote: (json['confidence_note'] ?? 
          'Sonuçlar genel pazar verilerine ve kullanıcı istatistiklerine dayanmaktadır.')
          .toString(),
    );
  }
}