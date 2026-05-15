import 'package:flutter/material.dart';

// Uygulama genelinde kullanılan renk ve stil sabitleri
// Tüm ekranlar bu dosyadan renkleri çeker, böylece tek yerden değiştirilebilir

class AppColors {
  // Ana arka plan renkleri (koyu teal gradient)
  static const Color bgTop = Color(0xFF0B2E2E);
  static const Color bgBottom = Color(0xFF134E4A);

  // Vurgu rengi (açık teal - butonlar, ikonlar, aktif elemanlar)
  static const Color teal = Color(0xFF2DD4C0);

  // Kart arka plan rengi
  static const Color card = Color(0xFF0F3B39);
}

// Uygulama genelinde kullanılan gradient tanımı
// LinearGradient: iki renk arasında yumuşak geçiş sağlar
const appGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AppColors.bgTop, AppColors.bgBottom],
);
