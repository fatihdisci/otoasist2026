import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AiLocalDataSource {
  final FirebaseFirestore _firestore;
  AiLocalDataSource(this._firestore);

  Future<Map<String, dynamic>?> getCachedAnalysis(String signature) async {
    try {
      final doc = await _firestore.collection('ai_cache').doc(signature).get();
      
      if (doc.exists && doc.data() != null) {
        // Cache'de veri var, ancak eski olabilir (opsiyonel: TTL kontrolü eklenebilir)
        final data = doc.data()!;
        // Timestamp alanlarını kontrol et ve gerekirse güncelle
        if (data.containsKey('cachedAt')) {
          final cachedAt = (data['cachedAt'] as Timestamp).toDate();
          final daysSinceCache = DateTime.now().difference(cachedAt).inDays;
          
          // 30 günden eski cache'i kullanma (opsiyonel)
          if (daysSinceCache > 30) {
            debugPrint("Cache çok eski ($daysSinceCache gün), yeniden analiz yapılıyor.");
            return null;
          }
        }
        
        debugPrint("Cache'den veri bulundu: $signature");
        return data;
      }
      
      return null;
    } catch (e) {
      debugPrint("Cache okuma hatası: $e");
      return null; // Hata durumunda null dön, remote'tan al
    }
  }

  Future<void> cacheAnalysis(String signature, Map<String, dynamic> data) async {
    try {
      // Cache'e kaydederken timestamp ekle
      final dataWithTimestamp = Map<String, dynamic>.from(data);
      dataWithTimestamp['cachedAt'] = FieldValue.serverTimestamp();
      
      await _firestore.collection('ai_cache').doc(signature).set(dataWithTimestamp);
      debugPrint("Analiz cache'lendi: $signature");
    } catch (e) {
      debugPrint("Cache kaydetme hatası: $e");
      // Cache hatası kritik değil, devam et
    }
  }
}

class AiRemoteDataSource {
  final String _apiKey;
  AiRemoteDataSource(this._apiKey);

  Future<Map<String, dynamic>> fetchAnalysis(Map<String, dynamic> vehicleData) async {
    
    // 1. Veri Temizliği (Timestamp -> String)
    final sanitizedData = Map<String, dynamic>.from(vehicleData);
    for (var key in sanitizedData.keys) {
      final value = sanitizedData[key];
      if (value is Timestamp) {
        sanitizedData[key] = value.toDate().toIso8601String();
      } else if (value is FieldValue) {
        sanitizedData[key] = DateTime.now().toIso8601String();
      }
    }

    final model = GenerativeModel(
      model: 'gemini-2.5-flash', 
      apiKey: _apiKey,
    );

    // 2. Prompt Hazırlığı (Daha Agresif Analiz)
    // Buraya özellikle "Kronik Sorunları Gizleme" talimatı ekledim.
    final prompt = """
    Sen deneyimli bir otomobil ekspertiz uzmanısın. Görevin araç sahiplerini olası masraflara karşı uyarmak.
    Aşağıdaki aracı teknik verilerine göre analiz et.

    ARAÇ BİLGİLERİ:
    ${jsonEncode(sanitizedData)}

    ÖNEMLİ TALİMATLAR:
    1. Bu marka/model/yıl kombinasyonunun bilinen KRONİK sorunlarını mutlaka yaz. (Örn: DSG şanzıman, triger zinciri, yağ yakma vb.)
    2. Eğer araç temizse bile, o kilometrede (currentKm) yapılması gereken ağır bakımları listele.
    3. "Sorun yok" demek yerine "Potansiyel Riskleri" vurgula.
    4. Cevabı aşağıdaki JSON formatında ver (Markdown kullanma).

    İSTENEN JSON FORMATI:
    {
      "healthScore": (0-100 arası puan, sorunlu araçlarda düşük ver),
      "summary": (Sert ve gerçekçi teknik özet),
      "chronicIssues": [
        {"title": "Kısa Başlık", "description": "Teknik açıklama ve çözüm önerisi", "riskLevel": "high" | "medium" | "low"}
      ],
      "checklist": ["Kontrol 1", "Kontrol 2"],
      "confidenceNote": "Analiz notu"
    }
    """;

    // --- LOGLAMA: Giden Mesajı Gör ---
    debugPrint("\n🔵 ================== AI GİDEN MESAJ (PROMPT) ================== 🔵");
    debugPrint(prompt);
    debugPrint("🔵 ============================================================= 🔵\n");

    try {
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      final responseText = response.text;

      if (responseText == null) throw Exception("AI boş cevap döndü.");

      // --- LOGLAMA: Gelen Mesajı Gör ---
      debugPrint("\n🟢 ================== AI GELEN MESAJ (RESPONSE) ================== 🟢");
      debugPrint(responseText);
      debugPrint("🟢 ============================================================== 🟢\n");

      String cleanJson = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
      return jsonDecode(cleanJson) as Map<String, dynamic>;

    } catch (e) {
      debugPrint("🔴 AI HATASI: $e");
      throw Exception("AI Servis Hatası: $e");
    }
  }
}