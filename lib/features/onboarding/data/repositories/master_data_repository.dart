import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MasterDataRepository {
  // Bellek İçi Önbellek (Memoization)
  Map<String, dynamic>? _cachedData;
  List<String>? _cachedBrands;
  Map<String, List<String>> _cachedModels = {};

  /// JSON dosyasını okur ve cache'ler.
  Future<void> _ensureInitialized() async {
    if (_cachedData != null) return;

    try {
      final jsonString = await rootBundle.loadString('assets/data/car_data.json');
      _cachedData = json.decode(jsonString);
    } catch (e) {
      // Fallback veya Loglama
      print("Master Data Okuma Hatası: $e");
      _cachedData = {"brands": []};
    }
  }

  /// Tüm markaları getirir.
  Future<List<String>> getBrands() async {
    await _ensureInitialized();
    
    if (_cachedBrands != null) return _cachedBrands!;

    final brandsList = _cachedData?['brands'] as List<dynamic>? ?? [];
    _cachedBrands = brandsList.map((b) => b['name'] as String).toList();
    _cachedBrands!.sort(); // Alfabetik sırala
    
    return _cachedBrands!;
  }

  /// Seçilen markaya göre modelleri getirir.
  Future<List<String>> getModels(String brandName) async {
    await _ensureInitialized();

    if (_cachedModels.containsKey(brandName)) {
      return _cachedModels[brandName]!;
    }

    final brandsList = _cachedData?['brands'] as List<dynamic>? ?? [];
    
    // Marka ismine göre bul (İdealde ID ile çalışmak daha iyidir ama UI basitleştirildi)
    final brandData = brandsList.firstWhere(
      (b) => b['name'] == brandName, 
      orElse: () => null
    );

    if (brandData != null) {
      final models = List<String>.from(brandData['models'] ?? []);
      models.sort();
      _cachedModels[brandName] = models;
      return models;
    }

    return []; // Marka bulunamazsa boş liste
  }
  
  // Yıllar: 2000 - Bugün (Statik olduğu için cache gerekmez)
  List<int> getYears() {
    final currentYear = DateTime.now().year;
    // 1990'a kadar inelim
    return List.generate(currentYear - 1989, (index) => currentYear - index);
  }
}

final masterDataRepositoryProvider = Provider((ref) => MasterDataRepository());