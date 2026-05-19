import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../services/auth_service.dart';
import '../guest/guest_main_screen.dart';
import '../admin/dashboard_screen.dart';
import '../admin/super_admin_screen.dart';
import 'register_screen.dart';

// Giriş ekranı - uygulamanın ilk açılan ekranı
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Metin alanlarını kontrol eden controller'lar
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Kimlik doğrulama işlemleri için servis nesnesi
  final _authService = AuthService();

  // Yükleniyor mu? (buton spinner için)
  bool _isLoading = false;

  // Şifre gizlensin mi?
  bool _obscurePassword = true;

  // Hata mesajı (null ise gösterilmez)
  String? _errorMessage;

  // Renk sabitleri

  // Giriş yapma işlemini yöneten metot
  Future<void> _login() async {
    // Yükleniyor durumuna geç, eski hata mesajını temizle
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // AuthService üzerinden Firebase'e giriş isteği gönder
    String? error = await _authService.login(
      email: _emailController.text.trim(),     // Baştaki/sondaki boşlukları sil
      password: _passwordController.text.trim(),
    );

    // Hata varsa ekranda göster ve dur
    if (error != null) {
      setState(() {
        _errorMessage = error;
        _isLoading = false;
      });
      return;
    }

    // Giriş başarılı → kullanıcının rolünü Firestore'dan çek
    String? role;
    try {
      role = await _authService.getUserRole();
    } catch (e) {
      // getUserRole() hata verdiyse ekranda göster
      setState(() {
        _errorMessage = 'Rol alınamadı: $e';
        _isLoading = false;
      });
      return;
    }
    if (!mounted) return;

    // Role göre farklı ekrana yönlendir
    if (role == 'superadmin') {
      // Süper admin → süper admin paneline git
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SuperAdminScreen()),
      );
    } else if (role == 'yonetici') {
      // Onaylı yönetici → tesis yönetim paneline git
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else if (role == 'pending_yonetici') {
      // Henüz onaylanmamış yönetici → oturumu kapat, hata mesajı göster
      await _authService.logout();
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Hesabınız henüz onaylanmadı. Süper admin onayı bekleniyor.';
      });
    } else {
      // Misafir → ana ekrana git
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const GuestMainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgTop, // Scaffold arka planını gradient ile eşleştir
      body: Container(
        // Ekranın tüm yüksekliğini kapla (kaydırma olmasa bile)
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
        // Gradient arka plan
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bgTop, AppColors.bgBottom],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            // İçerik klavyeden taşarsa kaydırılabilir olsun
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 40),
                _buildHeader(),   // Logo ve başlık
                const SizedBox(height: 32),
                _buildCard(),     // Giriş formu kartı
                const SizedBox(height: 28),
                _buildRegisterLink(), // "Hesabın yok mu?" linki
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Logo ve uygulama adı bölümü
  Widget _buildHeader() {
    return Column(
      children: [
        // assets klasöründeki logo görseli
        Image.asset(
          'assets/konakla_logo.png',
          width: 120,
          height: 120,
          fit: BoxFit.contain,
        ),
        const Text(
          'Konakla',
          style: TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 1),
        const Text(
          'Konaklama Rezervasyon Sistemi',
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
      ],
    );
  }

  // Giriş formu kartı
  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hoş Geldiniz',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Hesabınıza giriş yapın',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
          const SizedBox(height: 28),
          // E-posta giriş alanı
          _buildField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          // Şifre giriş alanı (göster/gizle butonu ile)
          _buildField(
            controller: _passwordController,
            label: 'Şifre',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            suffix: IconButton(
              icon: Icon(
                // Şifre gizliyse "gözü kapalı" ikon, değilse "gözü açık"
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.white38,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          // Hata mesajı varsa göster
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            _buildError(_errorMessage!),
          ],
          const SizedBox(height: 28),
          _buildButton(), // Giriş Yap butonu
        ],
      ),
    );
  }

  // Kayıt ol linki
  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Hesabın yok mu? ',
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegisterScreen()),
          ),
          child: const Text(
            'Kayıt Ol',
            style: TextStyle(
              color: AppColors.teal,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // Yeniden kullanılabilir metin alanı widget'ı
  // Hem email hem şifre alanı bu metotla oluşturulur
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,       // Şifre gizleme
    TextInputType? keyboardType,    // Klavye tipi (email, sayı vb.)
    Widget? suffix,                 // Sağ taraftaki ek widget (göster/gizle butonu)
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        // Odaklanınca teal renkte kenarlık
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
      ),
    );
  }

  // Kırmızı hata mesajı kutusu
  Widget _buildError(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Giriş Yap butonu
  // Yükleniyorsa spinner, değilse "Giriş Yap" yazısı gösterir
  Widget _buildButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        // Yükleniyorken butonu devre dışı bırak
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.teal.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'Giriş Yap',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }

  // Widget ağaçtan kaldırılınca controller'ları bellekten temizle
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
