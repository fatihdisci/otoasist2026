import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'features/garage/presentation/pages/garage_dashboard_screen.dart';
import 'integrations/notification_service.dart';
// Aşağıdaki dosya "flutterfire configure" ile oluşmuştu, şimdi onu kullanıyoruz:
import 'firebase_options.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Environment variables yükle
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Uyarı: .env dosyası yüklenemedi. API key kontrol edin: $e");
  }
  
  // HATA ÇÖZÜMÜ: Web için options parametresi EKLENDİ
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Bildirim servisini başlat
  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint("Bildirim servisi başlatılamadı: $e");
  }
  
  final auth = FirebaseAuth.instance;
  // Kullanıcı giriş yapmamışsa anonim giriş yap
  if (auth.currentUser == null) {
    try {
      await auth.signInAnonymously();
      debugPrint("Anonim giriş yapıldı: ${auth.currentUser?.uid}");
    } catch (e) {
      debugPrint("Giriş Hatası: $e");
    }
  }

  runApp(const ProviderScope(child: OtoAsistApp()));
}

class OtoAsistApp extends StatelessWidget {
  const OtoAsistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oto Asist',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const GarageDashboardScreen(),
    );
  }
}