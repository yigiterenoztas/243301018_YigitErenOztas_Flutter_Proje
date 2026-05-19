import 'package:flutter/material.dart';
import '../../constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'oda_tipi_arama_screen.dart';
import 'tesis_profil_screen.dart';

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

  // ── MOD 0: Tesis listesi ───────────────────────────────────────
  List<Map<String, dynamic>> _oteller = [];
  bool _otelllerYukleniyor = true;
  final _aramaCtrl = TextEditingController();
  String _aramaMetni = '';
  String? _filtreIl;
  String? _filtreIlce;

  // ── MOD 1: Yatak filtresi ──────────────────────────────────────
  // 0 = filtre yok, 1+ = en az bu kadar yatak
  int _ciftSayisi = 0;
  int _tekSayisi  = 0;

  // ── Ortak: tarih & kişi (modal ve mod-1 formu paylaşır) ────────
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

  @override
  void dispose() {
    _aramaCtrl.dispose();
    super.dispose();
  }

  Future<void> _otelleriYukle() async {
    final snap = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'yonetici')
        .get();
    final liste = snap.docs.map((d) {
      final data = d.data();
      return {
        'uid': d.id,
        'tesisAdi': data['tesisAdi'] ?? 'İsimsiz Tesis',
        'il': data['il'] ?? '',
        'ilce': data['ilce'] ?? '',
        'yildiz': (data['yildiz'] ?? 0) as int,
      };
    }).toList();
    if (mounted) {
      setState(() {
        _oteller = liste;
        _otelllerYukleniyor = false;
      });
    }
  }

  Future<void> _tarihSec(bool giris, {StateSetter? modalSet}) async {
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
      modalSet?.call(() {});
    }
  }

  void _kisiDegistir(String tip, bool artir, {StateSetter? modalSet}) {
    setState(() {
      if (tip == 'erkek') {
        if (artir) { _erkek++; } else if (_erkek > 0) { _erkek--; }
      } else if (tip == 'kadin') {
        if (artir) { _kadin++; } else if (_kadin > 0) { _kadin--; }
      } else {
        if (artir) { _cocuk++; } else if (_cocuk > 0) { _cocuk--; }
      }
    });
    modalSet?.call(() {});
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

  void _odaTipiListele() {
    if (_girisTarihi == null || _cikisTarihi == null) {
      _mesajGoster('Lütfen giriş ve çıkış tarihlerini seçin.');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OdaTipiAramaScreen(
          minCift: _ciftSayisi,
          minTek: _tekSayisi,
          girisTarihi: _girisTarihi!,
          cikisTarihi: _cikisTarihi!,
          erkekSayisi: _erkek,
          kadinSayisi: _kadin,
          cocukSayisi: _cocuk,
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
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
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: _buildAramaModuToggle(),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: _aramaModu == 0
                      ? _buildTesisListesiView()
                      : _buildOdaTipiFormView(),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 10),
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
                Text('Konakla',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text('Hayalinizdeki konaklamayı bulun',
                    style:
                        TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white54),
            onPressed: () async {
              final nav = Navigator.of(context);
              await _authService.logout();
              nav.pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
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
                  color: aktif ? Colors.white : Colors.white38,
                  size: 16),
              const SizedBox(width: 7),
              Text(baslik,
                  style: TextStyle(
                    color: aktif ? Colors.white : Colors.white38,
                    fontSize: 13,
                    fontWeight:
                        aktif ? FontWeight.w700 : FontWeight.normal,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ── MOD 0: TESİS LİSTESİ ─────────────────────────────────────
  Widget _buildTesisListesiView() {
    // İl listesi (yüklü tesislerden benzersiz)
    final ilListesi = _oteller
        .map((o) => o['il'] as String)
        .where((il) => il.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    // İlçe listesi (seçili ile göre)
    final ilceListesi = _filtreIl == null
        ? <String>[]
        : _oteller
            .where((o) => o['il'] == _filtreIl)
            .map((o) => o['ilce'] as String)
            .where((ilce) => ilce.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    // Filtre uygula
    final filtreli = _oteller.where((o) {
      final adEslesme = _aramaMetni.isEmpty ||
          (o['tesisAdi'] as String)
              .toLowerCase()
              .contains(_aramaMetni.toLowerCase());
      final ilEslesme =
          _filtreIl == null || o['il'] == _filtreIl;
      final ilceEslesme =
          _filtreIlce == null || o['ilce'] == _filtreIlce;
      return adEslesme && ilEslesme && ilceEslesme;
    }).toList();

    return Column(
      key: const ValueKey('tesis_listesi'),
      children: [
        // Arama çubuğu
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: TextField(
            controller: _aramaCtrl,
            onChanged: (v) => setState(() => _aramaMetni = v),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Tesis ara...',
              hintStyle:
                  const TextStyle(color: Colors.white38, fontSize: 14),
              prefixIcon: const Icon(Icons.search,
                  color: Colors.white38, size: 20),
              suffixIcon: _aramaMetni.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear,
                          color: Colors.white38, size: 18),
                      onPressed: () {
                        _aramaCtrl.clear();
                        setState(() => _aramaMetni = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.teal, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        // İl / İlçe filtre satırı
        if (!_otelllerYukleniyor && ilListesi.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Row(
              children: [
                // İl dropdown
                Expanded(
                  child: _filtreDropdown(
                    hint: 'Tüm İller',
                    value: _filtreIl,
                    items: ilListesi,
                    onChanged: (v) => setState(() {
                      _filtreIl = v;
                      _filtreIlce = null;
                    }),
                  ),
                ),
                const SizedBox(width: 10),
                // İlçe dropdown
                Expanded(
                  child: _filtreDropdown(
                    hint: 'Tüm İlçeler',
                    value: _filtreIlce,
                    items: ilceListesi,
                    onChanged: _filtreIl == null
                        ? null
                        : (v) => setState(() => _filtreIlce = v),
                  ),
                ),
              ],
            ),
          ),
        // Liste
        Expanded(
          child: _otelllerYukleniyor
              ? const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.teal, strokeWidth: 2))
              : filtreli.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off,
                              color: Colors.white24, size: 52),
                          const SizedBox(height: 12),
                          Text(
                            'Eşleşen tesis bulunamadı.',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: filtreli.length,
                      itemBuilder: (context, index) =>
                          _buildTesisKarti(filtreli[index]),
                    ),
        ),
      ],
    );
  }

  Widget _filtreDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
  }) {
    final aktif = value != null;
    return GestureDetector(
      onTap: onChanged == null
          ? null
          : () {
              // Seçimi temizleme özelliği için normal DropdownButton kullanıyoruz
            },
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: aktif
              ? AppColors.teal.withValues(alpha: 0.12)
              : AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: aktif
                ? AppColors.teal.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            hint: Text(hint,
                style: TextStyle(
                    color: onChanged == null
                        ? Colors.white24
                        : Colors.white38,
                    fontSize: 12)),
            dropdownColor: const Color(0xFF1A3A3A),
            isExpanded: true,
            icon: Icon(Icons.keyboard_arrow_down,
                color: aktif ? AppColors.teal : Colors.white38,
                size: 16),
            style:
                const TextStyle(color: Colors.white, fontSize: 12),
            onChanged: onChanged,
            items: [
              // "Tümü" seçeneği (null seçmek için)
              DropdownMenuItem<String>(
                value: null,
                child: Text(hint,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12)),
              ),
              ...items.map((item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTesisKarti(Map<String, dynamic> otel) {
    final int yildiz = (otel['yildiz'] ?? 0) as int;
    final String il = otel['il'] ?? '';
    final String ilce = otel['ilce'] ?? '';
    final String adres = [if (ilce.isNotEmpty) ilce, if (il.isNotEmpty) il]
        .join(' / ');

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TesisProfilScreen(otel: otel),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.hotel,
                  color: AppColors.teal, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otel['tesisAdi'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (yildiz > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < yildiz ? Icons.star : Icons.star_border,
                          color: i < yildiz
                              ? Colors.amber
                              : Colors.white24,
                          size: 13,
                        ),
                      ),
                    ),
                  ],
                  if (adres.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            color: Colors.white38, size: 12),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            adres,
                            style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white24, size: 14),
          ],
        ),
      ),
    );
  }

  // ── MOD 1: ODA TİPİ FORMU ────────────────────────────────────
  Widget _buildOdaTipiFormView() {
    return SingleChildScrollView(
      key: const ValueKey('odatipi_form'),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: Column(
        children: [
          _buildYatakSecimi(),
          const SizedBox(height: 14),
          _buildTarihSecimi(),
          const SizedBox(height: 14),
          _buildKisiSayisi(),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _odaTipiListele,
              icon: const Icon(Icons.search, color: Colors.white),
              label: const Text('Listele',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Çift / tek kişilik yatak sayısı — sayaç tarzı seçim
  Widget _buildYatakSecimi() {
    return _buildKart(
      baslik: 'Yatak Seçeneği',
      ikon: Icons.bed_outlined,
      icerik: Column(
        children: [
          _yatakSayaci(
            ikon: Icons.king_bed_outlined,
            renk: Colors.blue,
            etiket: 'Çift Kişilik Yatak',
            sayi: _ciftSayisi,
            onAzalt: _ciftSayisi > 0
                ? () => setState(() => _ciftSayisi--)
                : null,
            onArtir: () => setState(() => _ciftSayisi++),
          ),
          Divider(height: 20, color: Colors.white.withValues(alpha: 0.07)),
          _yatakSayaci(
            ikon: Icons.single_bed_outlined,
            renk: Colors.purple,
            etiket: 'Tek Kişilik Yatak',
            sayi: _tekSayisi,
            onAzalt: _tekSayisi > 0
                ? () => setState(() => _tekSayisi--)
                : null,
            onArtir: () => setState(() => _tekSayisi++),
          ),
          if (_ciftSayisi == 0 && _tekSayisi == 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.info_outline,
                    color: Colors.white24, size: 13),
                const SizedBox(width: 5),
                const Expanded(
                  child: Text(
                    'Seçim yapmazsanız tüm oda tipleri listelenir.',
                    style: TextStyle(
                        color: Colors.white24, fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Tek bir yatak tipi için +/- sayaç satırı
  Widget _yatakSayaci({
    required IconData ikon,
    required Color renk,
    required String etiket,
    required int sayi,
    required VoidCallback? onAzalt,
    required VoidCallback onArtir,
  }) {
    return Row(
      children: [
        Icon(ikon, color: renk, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            etiket,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500),
          ),
        ),
        // Azalt
        _sayacButon(Icons.remove, onAzalt ?? () {}, onAzalt != null),
        // Sayı göstergesi
        SizedBox(
          width: 36,
          child: Text(
            sayi == 0 ? '-' : '$sayi',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: sayi > 0 ? Colors.white : Colors.white38,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Artır
        _sayacButon(Icons.add, onArtir, true),
      ],
    );
  }

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
                      onTap: () => _tarihSec(true))),
              const SizedBox(width: 12),
              Expanded(
                  child: _tarihButon(
                      label: 'Çıkış',
                      tarih: _cikisTarihi,
                      onTap: () => _tarihSec(false))),
            ],
          ),
          if (_geceSayisi > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
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
                  Text('$_geceSayisi gece konaklama',
                      style: const TextStyle(
                          color: AppColors.teal,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKisiSayisi() {
    return _buildKart(
      baslik: 'Kişi Sayısı',
      ikon: Icons.people_outline,
      icerik: Column(
        children: [
          _kisiSatiri('Yetişkin (Erkek)', Icons.man, _erkek, 'erkek'),
          Divider(
              height: 22, color: Colors.white.withValues(alpha: 0.08)),
          _kisiSatiri('Yetişkin (Kadın)', Icons.woman, _kadin, 'kadin'),
          Divider(
              height: 22, color: Colors.white.withValues(alpha: 0.08)),
          _kisiSatiri('Çocuk', Icons.child_care, _cocuk, 'cocuk'),
        ],
      ),
    );
  }

  // ── YARDIMCI WİDGET'LAR ───────────────────────────────────────

  Widget _buildKart({
    required String baslik,
    required IconData ikon,
    required Widget icerik,
  }) {
    return Container(
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
              Text(baslik,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  )),
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
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                style: const TextStyle(
                    color: Colors.white38, fontSize: 11)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_month,
                    color:
                        secildi ? AppColors.teal : Colors.white38,
                    size: 14),
                const SizedBox(width: 5),
                Text(_tarihFormat(tarih),
                    style: TextStyle(
                      color:
                          secildi ? Colors.white : Colors.white38,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _kisiSatiri(
      String label, IconData ikon, int sayi, String tip) {
    return Row(
      children: [
        Icon(ikon, color: AppColors.teal, size: 22),
        const SizedBox(width: 10),
        Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500))),
        _sayacButon(
            Icons.remove, () => _kisiDegistir(tip, false), sayi > 0),
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

  Widget _sayacButon(
      IconData ikon, VoidCallback onTap, bool aktif) {
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
