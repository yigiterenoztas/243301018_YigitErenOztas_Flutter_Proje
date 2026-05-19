import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';

// Kayıt ekranı - yeni kullanıcı oluşturmak için
// İki farklı kayıt modu var: Misafir ve Tesis Yöneticisi
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Form alanları için controller'lar
  final _adController = TextEditingController();
  final _soyadController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _tesisController = TextEditingController(); // Sadece yönetici kaydında kullanılır

  // Kimlik doğrulama servisi
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  // Seçilen kayıt tipi: 0 = Misafir, 1 = Tesis Yöneticisi
  int _seciliRol = 0;

  // Renk sabitleri

  // Kayıt işlemini gerçekleştiren metot
  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String? error;

    if (_seciliRol == 0) {
      // Misafir kaydı - role: 'guest' olarak kaydedilir
      error = await _authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        ad: _adController.text.trim(),
        soyad: _soyadController.text.trim(),
      );
    } else {
      // Tesis yöneticisi kaydı - role: 'pending_yonetici' olarak kaydedilir
      // Süper admin onaylayana kadar giriş yapamaz
      error = await _authService.registerYonetici(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        ad: _adController.text.trim(),
        soyad: _soyadController.text.trim(),
        tesisAdi: _tesisController.text.trim(),
      );
    }

    // Hata varsa ekranda göster
    if (error != null) {
      setState(() {
        _errorMessage = error;
        _isLoading = false;
      });
      return;
    }

    // Kayıt başarılı → giriş ekranına yönlendir
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgTop,
      body: Container(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bgTop, AppColors.bgBottom],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 48),
                _buildHeader(),          // Logo ve başlık
                const SizedBox(height: 24),
                _buildRolToggle(),       // Misafir / Tesis Yöneticisi seçimi
                const SizedBox(height: 20),
                _buildCard(),            // Kayıt formu
                const SizedBox(height: 28),
                _buildLoginLink(),       // "Zaten hesabın var mı?" linki
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Logo ve başlık bölümü
  Widget _buildHeader() {
    return Column(
      children: [
        Image.asset(
          'assets/konakla_logo.png',
          width: 100,
          height: 100,
          fit: BoxFit.contain,
        ),
        const Text(
          'Konakla',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Yeni hesap oluşturun',
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
      ],
    );
  }

  // Kayıt tipi seçim toggle'ı (Misafir / Tesis Yöneticisi)
  Widget _buildRolToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Misafir seçeneği
          _rolButon(index: 0, label: 'Misafir', icon: Icons.person_outline),
          // Tesis Yöneticisi seçeneği
          _rolButon(
              index: 1,
              label: 'Tesis Yöneticisi',
              icon: Icons.business_outlined),
        ],
      ),
    );
  }

  // Toggle buton widget'ı
  // index: hangi role ait, label: buton yazısı, icon: buton ikonu
  Widget _rolButon(
      {required int index, required String label, required IconData icon}) {
    final secili = _seciliRol == index; // Bu buton seçili mi?
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _seciliRol = index;
          _errorMessage = null; // Rol değişince hata mesajını temizle
        }),
        child: AnimatedContainer(
          // Geçiş animasyonu - 200ms
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            // Seçiliyse teal arka plan, değilse şeffaf
            color: secili ? AppColors.teal : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: secili ? Colors.white : Colors.white54),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: secili ? Colors.white : Colors.white54,
                  fontWeight:
                      secili ? FontWeight.w700 : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Kayıt formu kartı
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
          // Başlık seçilen role göre değişir
          Text(
            _seciliRol == 0 ? 'Misafir Kaydı' : 'Tesis Yöneticisi Kaydı',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Bilgilerinizi girin',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
          const SizedBox(height: 24),
          // Ad ve Soyad alanları yan yana
          Row(
            children: [
              Expanded(
                child: _buildField(
                  controller: _adController,
                  label: 'Ad',
                  icon: Icons.person_outline_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildField(
                  controller: _soyadController,
                  label: 'Soyad',
                  icon: Icons.person_outline_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // E-posta alanı
          _buildField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          // Şifre alanı
          _buildField(
            controller: _passwordController,
            label: 'Şifre',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            suffix: IconButton(
              icon: Icon(
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
          // Tesis adı alanı - SADECE yönetici kaydında görünür
          if (_seciliRol == 1) ...[
            const SizedBox(height: 16),
            _buildField(
              controller: _tesisController,
              label: 'Tesis Adı',
              icon: Icons.business_outlined,
            ),
          ],
          const SizedBox(height: 10),
          // Şifre kuralı bilgi notu
          Row(
            children: const [
              Icon(Icons.info_outline, color: Colors.white24, size: 13),
              SizedBox(width: 6),
              Text(
                'Şifre en az 6 karakter olmalıdır.',
                style: TextStyle(color: Colors.white24, fontSize: 11),
              ),
            ],
          ),
          // Hata mesajı varsa göster
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            _buildError(_errorMessage!),
          ],
          const SizedBox(height: 20),
          _buildButton(), // Hesap Oluştur butonu
        ],
      ),
    );
  }

  // Giriş ekranına yönlendiren link
  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Zaten hesabın var mı? ',
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
        GestureDetector(
          // pop() ile bu ekranı kapat, login ekranı altta bekliyor
          onTap: () => Navigator.pop(context),
          child: const Text(
            'Giriş Yap',
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
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffix,
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
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

  // Hesap Oluştur butonu
  Widget _buildButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _register,
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
                    color: Colors.white, strokeWidth: 2.5),
              )
            : const Text(
                'Hesap Oluştur',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }

  // Widget kaldırılırken tüm controller'ları temizle (bellek sızıntısını önle)
  @override
  void dispose() {
    _adController.dispose();
    _soyadController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _tesisController.dispose();
    super.dispose();
  }
}
