import 'dart:convert';
import '../../../garage/domain/models/vehicle_model.dart';
// Enum label'ları için

class AiHelpers {
  /// Cache Key Üreticisi (Signature)
  /// Aynı konfigürasyondaki tüm araçlar aynı cache'i kullanır.
  static String generateVehicleSignature(Vehicle vehicle) {
    // String temizliği: Boşlukları sil, küçük harfe çevir
    final specSignature = '${vehicle.brand}|${vehicle.model}|${vehicle.year}|${vehicle.engine}|${vehicle.transmission.name}'
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '');

    // KM Bandı: Her 10.000 KM için bir bant.
    // Örn: 124.000 KM -> "12" bandı. (120k - 130k arası aynı sorunlar beklenir)
    final kmBand = (vehicle.estimatedKm / 10000).floor();

    // Örn: volkswagen|golf|2017|1.6tdi|dsg_12
    return '${specSignature}_$kmBand'; 
  }

  /// Robust JSON Extractor
  /// LLM'in "İşte yanıtınız:" gibi gevezeliklerini temizler.
  static Map<String, dynamic> extractJson(String rawText) {
    final start = rawText.indexOf('{');
    final end = rawText.lastIndexOf('}');

    if (start == -1 || end == -1) {
      throw FormatException("Metin içinde JSON bloğu bulunamadı.");
    }

    // Sadece { ... } arasını al
    final jsonString = rawText.substring(start, end + 1);
    
    // Burada import 'dart:convert'; kullanıldığını varsayıyoruz
    // Bu helper dosyası jsonDecode için dart:convert ister.
    // (Kod parçası olduğu için import'u yukarıda varsaydık)
    // Ancak tam kodda: import 'dart:convert'; eklenmeli.
    return Map<String, dynamic>.from(jsonDecode(jsonString)); // jsonDecode burada kullanılır
  }
}

// Yardımcı fonksiyon jsonDecode için gerekli
