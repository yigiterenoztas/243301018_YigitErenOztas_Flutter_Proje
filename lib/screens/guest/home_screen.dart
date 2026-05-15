import 'package:flutter/material.dart';
import '../../constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'room_detail_screen.dart';
import 'oda_tipi_arama_screen.dart';

// Misafir ana ekranı - iki arama modu: tesis bazlı ve oda tipi bazlı
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _authService = AuthService();

  // 0 → Tesis Seç, 1 → Oda Tipi Seç
  int _aramaModu = 0;

  // ── MOD 0: Tesis bazlı ──────────────────────────────────────────
  Map<String, dynamic>? _secilenOtel;
  List<Map<String, dynamic>> _oteller = [];
  bool _otelllerYukleniyor = true;

  // ── MOD 1: Oda tipi bazlı ───────────────────────────────────────
  String? _secilenOdaTipi;
  List<String> _odaTipleri = [];
  bool _odaTipleriYukleniyor = false;

  // ── Ortak: tarih & kişi ─────────────────────────────────────────
  DateTime? _girisTarihi;
  DateTime? _cikisTarihi;
  int _erkek = 1;
  int _kadin = 0;
  int _cocuk = 0;

  @override
  void initState() {
    super.initState();
    _otelleriYukle();
  }

  Future<void> _otelleriYukle() async {
    final snap = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'yonetici')
        .get();
    final liste = snap.docs
        .map((d) => {'uid': d.id, 'tesisAdi': d['tesisAdi'] ?? 'İsimsiz Tesis'})
        .toList();
    if (mounted) {
      setState(() {
        _oteller = liste;
        _otelllerYukleniyor = false;
      });
    }
  }

  Future<void> _odaTipleriniYukle() async {
    setState(() => _odaTipleriYukleniyor = true);
    final snap = await _firestore.collection('odalar').get();
    final tipler = snap.docs
        .map((d) => (d.data()['odaTipiAdi'] ?? '') as String)
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    if (mounted) {
      setState(() {
        _odaTipleri = tipler;
        _odaTipleriYukleniyor = false;
      });
    }
  }

  Future<void> _tarihSec(bool giris) async {
    final simdi = DateTime.now();
    final secilen = await showDatePicker(
      context: context,
      initialDate: giris
          ? (_girisTarihi ?? simdi)
          : (_cikisTarihi ?? simdi.add(const Duration(days: 1))),
      firstDate: simdi,
      lastDate: simdi.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.teal,
            onPrimary: Colors.white,
            surface: AppColors.card,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (secilen != null) {
      setState(() {
        if (giris) {
          _girisTarihi = secilen;
          if (_cikisTarihi != null && !_cikisTarihi!.isAfter(secilen)) {
            _cikisTarihi = null;
          }
        } else {
          _cikisTarihi = secilen;
        }
      });
    }
  }

  void _kisiDegistir(String tip, bool artir) {
    setState(() {
      if (tip == 'erkek') {
        if (artir) { _erkek++; } else if (_erkek > 0) { _erkek--; }
      } else if (tip == 'kadin') {
        if (artir) { _kadin++; } else if (_kadin > 0) { _kadin--; }
      } else {
        if (artir) { _cocuk++; } else if (_cocuk > 0) { _cocuk--; }
      }
    });
  }

  int get _geceSayisi {
    if (_girisTarihi == null || _cikisTarihi == null) return 0;
    return _cikisTarihi!.difference(_girisTarihi!).inDays;
  }

  String _tarihFormat(DateTime? tarih) {
    if (tarih == null) return 'Seçilmedi';
    return '${tarih.day.toString().padLeft(2, '0')}.'
        '${tarih.month.toString().padLeft(2, '0')}.'
        '${tarih.year}';
  }

  void _ara() {
    if (_girisTarihi == null || _cikisTarihi == null) {
      _mesajGoster('Lütfen giriş ve çıkış tarihlerini seçin.');
      return;
    }
    if (_erkek + _kadin + _cocuk == 0) {
      _mesajGoster('En az 1 kişi seçmelisiniz.');
      return;
    }

    if (_aramaModu == 0) {
      // Tesis bazlı
      if (_secilenOtel == null) {
        _mesajGoster('Lütfen bir tesis seçin.');
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RoomDetailScreen(
            yoneticiUid: _secilenOtel!['uid'],
            tesisAdi: _secilenOtel!['tesisAdi'],
            girisTarihi: _girisTarihi!,
            cikisTarihi: _cikisTarihi!,
            erkekSayisi: _erkek,
            kadinSayisi: _kadin,
            cocukSayisi: _cocuk,
          ),
        ),
      );
    } else {
      // Oda tipi bazlı
      if (_secilenOdaTipi == null) {
        _mesajGoster('Lütfen bir oda tipi seçin.');
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OdaTipiAramaScreen(
            odaTipiAdi: _secilenOdaTipi!,
            girisTarihi: _girisTarihi!,
            cikisTarihi: _cikisTarihi!,
            erkekSayisi: _erkek,
            kadinSayisi: _kadin,
            cocukSayisi: _cocuk,
          ),
        ),
      );
    }
  }

  void _mesajGoster(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mesaj),
        backgroundColor: AppColors.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgTop,
      body: Container(
        decoration: const BoxDecoration(gradient: appGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAramaModuToggle(),
                      const SizedBox(height: 14),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder: (child, anim) =>
                            FadeTransition(opacity: anim, child: child),
                        child: _aramaModu == 0
                            ? _buildTesisSecimi()
                            : _buildOdaTipiSecimi(),
                      ),
                      const SizedBox(height: 14),
                      _buildTarihSecimi(),
                      const SizedBox(height: 14),
                      _buildKisiSayisi(),
                      const SizedBox(height: 28),
                      _buildAraButon(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── ÜST BAŞLIK ────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.hotel, color: AppColors.teal, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Konakla',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  'Hayalinizdeki konaklamayı bulun',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white54),
            onPressed: () async {
              final nav = Navigator.of(context);
              await _authService.logout();
              nav.pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── ARAMA MODU TOGGLE ─────────────────────────────────────────
  Widget _buildAramaModuToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          _modButon(0, Icons.hotel_outlined, 'Tesis Seç'),
          _modButon(1, Icons.bed_outlined, 'Oda Tipi Seç'),
        ],
      ),
    );
  }

  Widget _modButon(int mod, IconData ikon, String baslik) {
    final aktif = _aramaModu == mod;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_aramaModu == mod) return;
          setState(() => _aramaModu = mod);
          // Oda tiplerini ilk geçişte yükle
          if (mod == 1 && _odaTipleri.isEmpty && !_odaTipleriYukleniyor) {
            _odaTipleriniYukle();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: aktif ? AppColors.teal : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(ikon,
                  color: aktif ? Colors.white : Colors.white38, size: 16),
              const SizedBox(width: 7),
              Text(
                baslik,
                style: TextStyle(
                  color: aktif ? Colors.white : Colors.white38,
                  fontSize: 13,
                  fontWeight:
                      aktif ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── MOD 0: TESİS SEÇİMİ ──────────────────────────────────────
  Widget _buildTesisSecimi() {
    return _buildKart(
      key: const ValueKey('tesis'),
      baslik: 'Tesis Seçin',
      ikon: Icons.hotel_outlined,
      icerik: _otelllerYukleniyor
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: CircularProgressIndicator(
                    color: AppColors.teal, strokeWidth: 2),
              ),
            )
          : _oteller.isEmpty
              ? const Text('Henüz onaylı tesis bulunmuyor.',
                  style: TextStyle(color: Colors.white38, fontSize: 13))
              : DropdownButtonHideUnderline(
                  child: DropdownButton<Map<String, dynamic>>(
                    value: _secilenOtel,
                    hint: const Text('Tesis seçiniz...',
                        style:
                            TextStyle(color: Colors.white38, fontSize: 14)),
                    dropdownColor: AppColors.card,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down,
                        color: AppColors.teal),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 15),
                    items: _oteller.map((otel) {
                      return DropdownMenuItem(
                        value: otel,
                        child: Text(otel['tesisAdi']),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _secilenOtel = value),
                  ),
                ),
    );
  }

  // ── MOD 1: ODA TİPİ SEÇİMİ ───────────────────────────────────
  Widget _buildOdaTipiSecimi() {
    return _buildKart(
      key: const ValueKey('odatipi'),
      baslik: 'Oda Tipi Seçin',
      ikon: Icons.bed_outlined,
      icerik: _odaTipleriYukleniyor
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: CircularProgressIndicator(
                    color: AppColors.teal, strokeWidth: 2),
              ),
            )
          : _odaTipleri.isEmpty
              ? const Text('Henüz kayıtlı oda tipi bulunamadı.',
                  style: TextStyle(color: Colors.white38, fontSize: 13))
              : DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _secilenOdaTipi,
                    hint: const Text('Oda tipi seçiniz...',
                        style:
                            TextStyle(color: Colors.white38, fontSize: 14)),
                    dropdownColor: AppColors.card,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down,
                        color: AppColors.teal),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 15),
                    items: _odaTipleri
                        .map((tip) => DropdownMenuItem(
                            value: tip, child: Text(tip)))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _secilenOdaTipi = value),
                  ),
                ),
    );
  }

  // ── TARİH SEÇİMİ ──────────────────────────────────────────────
  Widget _buildTarihSecimi() {
    return _buildKart(
      baslik: 'Tarih Seçin',
      ikon: Icons.calendar_today_outlined,
      icerik: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _tarihButon(
                  label: 'Giriş',
                  tarih: _girisTarihi,
                  onTap: () => _tarihSec(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _tarihButon(
                  label: 'Çıkış',
                  tarih: _cikisTarihi,
                  onTap: () => _tarihSec(false),
                ),
              ),
            ],
          ),
          if (_geceSayisi > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.teal.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.nights_stay_outlined,
                      color: AppColors.teal, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '$_geceSayisi gece konaklama',
                    style: const TextStyle(
                        color: AppColors.teal,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── KİŞİ SAYISI ───────────────────────────────────────────────
  Widget _buildKisiSayisi() {
    return _buildKart(
      baslik: 'Kişi Sayısı',
      ikon: Icons.people_outline,
      icerik: Column(
        children: [
          _kisiSatiri('Yetişkin (Erkek)', Icons.man, _erkek, 'erkek'),
          Divider(height: 22, color: Colors.white.withValues(alpha: 0.08)),
          _kisiSatiri('Yetişkin (Kadın)', Icons.woman, _kadin, 'kadin'),
          Divider(height: 22, color: Colors.white.withValues(alpha: 0.08)),
          _kisiSatiri('Çocuk', Icons.child_care, _cocuk, 'cocuk'),
        ],
      ),
    );
  }

  // ── ARA BUTONU ────────────────────────────────────────────────
  Widget _buildAraButon() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _ara,
        icon: const Icon(Icons.search, color: Colors.white),
        label: Text(
          _aramaModu == 0 ? 'Odaları Listele' : 'Tesisleri Ara',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }

  // ── YARDIMCI WİDGET'LAR ───────────────────────────────────────

  Widget _buildKart({
    Key? key,
    required String baslik,
    required IconData ikon,
    required Widget icerik,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(ikon, color: AppColors.teal, size: 17),
              ),
              const SizedBox(width: 10),
              Text(
                baslik,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          icerik,
        ],
      ),
    );
  }

  Widget _tarihButon({
    required String label,
    required DateTime? tarih,
    required VoidCallback onTap,
  }) {
    final secildi = tarih != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: secildi
              ? AppColors.teal.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: secildi
                ? AppColors.teal.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_month,
                    color: secildi ? AppColors.teal : Colors.white38,
                    size: 14),
                const SizedBox(width: 5),
                Text(
                  _tarihFormat(tarih),
                  style: TextStyle(
                    color: secildi ? Colors.white : Colors.white38,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _kisiSatiri(String label, IconData ikon, int sayi, String tip) {
    return Row(
      children: [
        Icon(ikon, color: AppColors.teal, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
        ),
        _sayacButon(Icons.remove, () => _kisiDegistir(tip, false), sayi > 0),
        SizedBox(
          width: 36,
          child: Text('$sayi',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
        ),
        _sayacButon(Icons.add, () => _kisiDegistir(tip, true), true),
      ],
    );
  }

  Widget _sayacButon(IconData ikon, VoidCallback onTap, bool aktif) {
    final artir = ikon == Icons.add;
    return GestureDetector(
      onTap: aktif ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: aktif
              ? (artir
                  ? AppColors.teal.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.07))
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: aktif
                ? (artir
                    ? AppColors.teal.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.15))
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Icon(ikon,
            color: aktif
                ? (artir ? AppColors.teal : Colors.white70)
                : Colors.white24,
            size: 16),
      ),
    );
  }
}
