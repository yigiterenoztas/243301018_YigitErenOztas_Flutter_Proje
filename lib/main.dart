import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'constants.dart';
import 'screens/auth/login_screen.dart';
import 'screens/guest/guest_main_screen.dart';
import 'screens/admin/dashboard_screen.dart';
import 'screens/admin/super_admin_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Konaklama Rezervasyon Sistemi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        // Tüm ekranların varsayılan arka planı — beyaz flash'ı önler
        scaffoldBackgroundColor: AppColors.bgTop,
        // Sayfa geçiş animasyonunda arka plan rengi
        canvasColor: AppColors.bgTop,
        // Geçiş animasyonlarını hızlandır ve siyah/beyaz flash'ı önle
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      // Uygulama açıldığında oturum durumunu kontrol et
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {

          // Firebase bağlantısı kurulurken yükleniyor göstergesi
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Oturum açık kullanıcı varsa rolünü Firestore'dan çek
          if (snapshot.hasData) {
            return FutureBuilder<String?>(
              future: AuthService().getUserRole(),
              builder: (context, roleSnapshot) {

                // Rol yüklenirken bekleme ekranı
                if (roleSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                // Hata olursa login ekranına gönder
                if (roleSnapshot.hasError) {
                  return const LoginScreen();
                }

                final role = roleSnapshot.data;

                // Role göre doğru ekrana yönlendir
                if (role == 'superadmin') {
                  return const SuperAdminScreen();
                } else if (role == 'yonetici') {
                  return const DashboardScreen();
                } else if (role == 'guest') {
                  return const GuestMainScreen();
                } else {
                  return const LoginScreen();
                }
              },
            );
          }

          // Oturum kapalıysa giriş ekranını göster
          return const LoginScreen();
        },
      ),
    );
  }
}
