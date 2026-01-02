import '../models/vehicle_model.dart';

// Domain'e özel hata sınıfı
class KmValidationException implements Exception {
  final String message;
  KmValidationException(this.message);
  @override
  String toString() => message;
}

class KmCalculatorService {
  Vehicle calculateNewStats(Vehicle currentVehicle, int newKm, DateTime newDate) {
    // 1. Validation
    if (newKm < currentVehicle.currentKm) {
      throw KmValidationException("Yeni kilometre (${newKm}), mevcut kilometreden (${currentVehicle.currentKm}) düşük olamaz.");
    }

    // Fark hesabı
    final kmDiff = newKm - currentVehicle.currentKm;
    final durationDiff = newDate.difference(currentVehicle.lastKmUpdateDate);
    
    // Saat bazlı hesaplama (Daha hassas)
    // Örn: 36 saat = 1.5 gün.
    final daysDiff = durationDiff.inHours / 24.0;

    double newDailyAvg;
    bool isAutoCalc;

    // Kural: En az 1 saat geçmiş olmalı ve KM artmış olmalı
    if (daysDiff >= (1.0 / 24.0) && kmDiff > 0) {
      
      // KORUMA: Eğer süre 1 günden az ise (örn: 12 saat), 
      // ani fırlamaları önlemek için paydayı en az 1.0 alabiliriz 
      // VEYA hassas hesap yapabiliriz. 
      // Karar: "Anlık ortalama" yerine "Günlük" dediğimiz için min 1 gün kabul etmek daha stabil sonuç verir.
      final effectiveDays = daysDiff < 1.0 ? 1.0 : daysDiff;
      
      newDailyAvg = kmDiff / effectiveDays;
      isAutoCalc = true;
    } else {
      // Değişiklik yok veya süre çok kısa: Eski ortalamayı koru
      newDailyAvg = currentVehicle.dailyAvgKm;
      isAutoCalc = currentVehicle.isDailyAvgKmAutoCalculated;
    }

    return currentVehicle.copyWith(
      currentKm: newKm,
      lastKmUpdateDate: newDate,
      dailyAvgKm: newDailyAvg,
      isDailyAvgKmAutoCalculated: isAutoCalc,
    );
  }
}