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
      if (doc.exists) {
        debugPrint("AI: Veri önbellekten (Cache) çekildi.");
        return doc.data();
      }
    } catch (e) {
      debugPrint("Cache Okuma Hatası: $e");
    }
    return null;
  }

  Future<void> cacheAnalysis(String signature, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('ai_cache').doc(signature).set(data);
    } catch (e) {
      debugPrint("Cache Yazma Hatası: $e");
    }
  }
}

class AiRemoteDataSource {
  final String _apiKey;

  AiRemoteDataSource(this._apiKey);

  Future<Map<String, dynamic>> fetchAnalysis(Map<String, dynamic> vehicleData) async {
    debugPrint("AI: Gemini API'ye bağlanılıyor...");

    // --- KRİTİK DÜZELTME: Timestamp Temizliği ---
    // Firestore Timestamp nesneleri JSON olamaz, bu yüzden onları String'e çeviriyoruz.
    final sanitizedData = Map<String, dynamic>.from(vehicleData);
    
    // Haritadaki her veriyi kontrol et, Timestamp varsa String yap
    for (var key in sanitizedData.keys) {
      final value = sanitizedData[key];
      if (value is Timestamp) {
        sanitizedData[key] = value.toDate().toIso8601String();
      }
    }
    // ---------------------------------------------
    
    // 1. Modeli Başlat
    final model = GenerativeModel(
      model: 'gemini-2.5-flash', // Model ismini değiştirdim, 2.5 henüz kararlı olmayabilir
      apiKey: _apiKey,
    );

    // 2. Prompt (İstem) Hazırla
    final prompt = """
    Sen uzman bir araç teknisyeni ve ekspertiz danışmanısın.
    Aşağıdaki araç verilerini analiz et ve JSON formatında bir rapor oluştur.
    
    ARAÇ VERİSİ:
    ${jsonEncode(sanitizedData)}  <-- DÜZELTİLDİ: Artık temizlenmiş veri gönderiliyor

    İSTENEN JSON FORMATI:
    {
      "healthScore": (0-100 arası tahmini sağlık puanı, int),
      "summary": (Araç hakkında 2 cümlelik teknik özet, string),
      "chronicIssues": [
        {"title": "Sorun Başlığı", "description": "Detaylı açıklama", "riskLevel": "low" | "medium" | "high"}
      ],
      "checklist": ["Kontrol edilmesi gereken madde 1", "Madde 2"],
      "confidenceNote": (Analizin doğruluğu hakkında kısa not, string)
    }

    KURALLAR:
    - Sadece saf JSON döndür. Markdown (```json) kullanma.
    - Yorum satırı ekleme.
    - Türkçe cevap ver.
    """;

    // 3. İsteği Gönder
    final content = [Content.text(prompt)];
    final response = await model.generateContent(content);

    debugPrint("AI: Cevap alındı, işleniyor...");
    
    final responseText = response.text;
    if (responseText == null) throw Exception("AI boş cevap döndü.");

    // 4. JSON Temizliği
    String cleanJson = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
    
    try {
      return jsonDecode(cleanJson) as Map<String, dynamic>;
    } catch (e) {
      debugPrint("JSON Parse Hatası: $cleanJson");
      throw Exception("AI cevabı işlenemedi: $e");
    }
  }
}