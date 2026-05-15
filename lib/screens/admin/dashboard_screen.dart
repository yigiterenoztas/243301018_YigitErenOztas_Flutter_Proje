import 'package:flutter/material.dart';
import '../../constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'reservation_approval_screen.dart';

// Tesis Yöneticisi ana paneli
// 3 sekmeli yapı: Ana Sayfa | Düzenle | Rezervasyon İstekleri
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Aktif sekme indeksi (0: Anasayfa, 1: Düzenle, 2: Rezervasyonlar)
  int _secilenSekme = 0;

  // Giriş yapan yöneticinin Firestore'dan çekilen bilgileri
  Map<String, dynamic>? _kullaniciBilgi;

  @override
  void initState() {
    super.initState();
    _kullaniciBilgisiYukle();
  }

  // Firestore'dan kullanıcı bilgilerini çeker
  Future<void> _kullaniciBilgisiYukle() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && mounted) {
      setState(() => _kullaniciBilgi = doc.data());
    }
  }

  // Yönetici adı ve soyadını birleştirerek döndürür
  String get _yoneticiAdi {
    final ad = _kullaniciBilgi?['ad'] ?? '';
    final soyad = _kullaniciBilgi?['soyad'] ?? '';
    return '$ad $soyad'.trim();
  }

  // Tesis adını döndürür
  String get _tesisAdi => _kullaniciBilgi?['tesisAdi'] ?? 'Tesis';

  // Firebase Auth'tan giriş yapan kullanıcının UID'si
  String get _uid => _auth.currentUser?.uid ?? '';

  // Oturumu kapatıp login ekranına yönlendirir
  Future<void> _cikisYap() async {
    final nav = Navigator.of(context);
    await AuthService().logout();
    nav.pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgTop,
      body: Container(
        // Koyu teal gradient arka plan
        decoration: const BoxDecoration(gradient: appGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(), // Üst başlık
              // IndexedStack: sekme değişiminde widget'lar yok edilmez,
              // StreamBuilder bağlantıları sürekli açık kalır
              Expanded(
                child: IndexedStack(
                  index: _secilenSekme,
                  children: [
                    _buildAnasayfa(),        // Sekme 0
                    _buildDuzenle(),         // Sekme 1
                    ReservationApprovalScreen( // Sekme 2
                      yoneticiUid: _uid,
                      tesisAdi: _tesisAdi,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── ÜST BAŞLIK ────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      child: Row(
        children: [
          // Otel ikonu
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.hotel, color: AppColors.teal, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tesis adı - kalın yazı
                Text(
                  _tesisAdi,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                // Yönetici adı - ince yazı
                Text(
                  _yoneticiAdi.isNotEmpty
                      ? 'Hoş geldin, $_yoneticiAdi'
                      : 'Tesis Yöneticisi',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Çıkış butonu
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: _cikisYap,
          ),
        ],
      ),
    );
  }

  // ── ALT NAVİGASYON ÇUBUĞU ─────────────────────────────────────
  Widget _buildBottomNav() {
    // 3 sekme tanımı
    const items = [
      (icon: Icons.home_outlined,           activeIcon: Icons.home,           label: 'Ana Sayfa'),
      (icon: Icons.edit_outlined,           activeIcon: Icons.edit,           label: 'Düzenle'),
      (icon: Icons.event_note_outlined,     activeIcon: Icons.event_note,     label: 'Rezervasyonlar'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final secili = _secilenSekme == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _secilenSekme = i),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      secili ? items[i].activeIcon : items[i].icon,
                      color: secili ? AppColors.teal : Colors.white38,
                      size: 22,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      items[i].label,
                      style: TextStyle(
                        color: secili ? AppColors.teal : Colors.white38,
                        fontSize: 10,
                        fontWeight: secili ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // SEKME 0 – ANA SAYFA
  // Hoş geldin banner + tesisin oda tiplerini listeler
  // ══════════════════════════════════════════════════════════════
  Widget _buildAnasayfa() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Oda Tiplerimiz',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // Oda tiplerini Firestore'dan gerçek zamanlı dinle
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('odalar')
                .where('yoneticiUid', isEqualTo: _uid)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: CircularProgressIndicator(color: AppColors.teal),
                  ),
                );
              }

              final odaTipleri = snap.data!.docs;

              // Oda tipi yoksa yönlendirici mesaj göster
              if (odaTipleri.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.bed_outlined, color: Colors.white24, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'Henüz oda tipi eklenmedi.',
                        style: TextStyle(color: Colors.white38, fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '"Düzenle" sekmesinden oda tipi ekleyebilirsiniz.',
                        style: TextStyle(color: Colors.white24, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              // Oda tiplerini kart olarak listele
              // doc.id: listeye tıklandığında doğru belgeyi getirmek için gerekli
              return Column(
                children: odaTipleri.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _anasayfaOdaKarti(doc.id, data);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // Hoş geldin banner kartı

  // Ana sayfada gösterilen oda tipi kartı
  // Tıklandığında o tipe ait tüm odaların listesini açar
  Widget _anasayfaOdaKarti(String docId, Map<String, dynamic> data) {
    final tip = data['odaTipiAdi'] ?? 'Oda';
    final cift = data['ciftKisilikYatak'] ?? 0;
    final tek = data['tekKisilikYatak'] ?? 0;
    final fiyat = data['fiyat'] ?? 0.0;
    final odaSayisi = data['odaSayisi'] ?? 0;

    // GestureDetector: karta tıklandığında oda listesi açılır
    return GestureDetector(
      onTap: () => _odaListesiGoster(docId, tip, odaSayisi),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst satır: oda tipi adı + oda sayısı + ok ikonu
            Row(
              children: [
                const Icon(Icons.bed, color: AppColors.teal, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tip,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$odaSayisi Oda',
                    style: const TextStyle(
                      color: AppColors.teal,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Tıklanabilir olduğunu gösteren ok ikonu
                const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (cift > 0)
                  _bilgiCip(Icons.king_bed_outlined, '$cift Çift Kişilik', Colors.blue),
                if (tek > 0)
                  _bilgiCip(Icons.single_bed_outlined, '$tek Tek Kişilik', Colors.purple),
                _bilgiCip(Icons.attach_money, '₺${fiyat.toStringAsFixed(0)} / gece', AppColors.teal),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Küçük bilgi etiketi (ikon + yazı)
  Widget _bilgiCip(IconData ikon, String yazi, Color renk) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, color: renk, size: 14),
          const SizedBox(width: 4),
          Text(yazi, style: TextStyle(color: renk, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // SEKME 1 – DÜZENLE
  // Oda tiplerini ekleme / düzenleme / silme ekranı
  // ══════════════════════════════════════════════════════════════
  Widget _buildDuzenle() {
    return Column(
      children: [
        // Başlık + "Oda Tipi Ekle" butonu
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: [
              const Text(
                'Oda Tipleri',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _odaTipiDialog(), // Yeni ekleme formu aç
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ekle',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Oda tiplerini gerçek zamanlı listele
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('odalar')
                .where('yoneticiUid', isEqualTo: _uid)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: AppColors.teal));
              }

              final odaTipleri = snap.data!.docs;

              // Kayıt yoksa boş durum mesajı
              if (odaTipleri.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline, color: Colors.white24, size: 56),
                      const SizedBox(height: 12),
                      const Text(
                        'Henüz oda tipi yok.',
                        style: TextStyle(color: Colors.white38, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Sağ üstteki "Ekle" butonunu kullanın.',
                        style: TextStyle(color: Colors.white24, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }

              // Oda tipi kartlarını listele
              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: odaTipleri.length,
                itemBuilder: (ctx, i) {
                  return _duzenleOdaKarti(odaTipleri[i]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Düzenle sekmesindeki oda tipi kartı (düzenle + sil butonları var)
  Widget _duzenleOdaKarti(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final tip = data['odaTipiAdi'] ?? 'Oda';
    final cift = data['ciftKisilikYatak'] ?? 0;
    final tek = data['tekKisilikYatak'] ?? 0;
    final fiyat = data['fiyat'] ?? 0.0;
    final odaSayisi = data['odaSayisi'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst satır: oda tipi adı + düzenle/sil butonları
          Row(
            children: [
              const Icon(Icons.hotel, color: AppColors.teal, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tip,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Düzenle butonu - mevcut verileri forma doldurur
              IconButton(
                onPressed: () => _odaTipiDialog(mevcutDoc: doc),
                icon: const Icon(Icons.edit_outlined,
                    color: Colors.white54, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Düzenle',
              ),
              const SizedBox(width: 14),
              // Sil butonu - onay dialogu açar
              IconButton(
                onPressed: () => _odaTipiSil(doc.id, tip),
                icon: const Icon(Icons.delete_outline,
                    color: Colors.redAccent, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Sil',
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Alt satır: yatak ve oda sayısı detayları
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (cift > 0)
                _bilgiCip(Icons.king_bed_outlined, '$cift Çift Kişilik Yatak', Colors.blue),
              if (tek > 0)
                _bilgiCip(Icons.single_bed_outlined, '$tek Tek Kişilik Yatak', Colors.purple),
              _bilgiCip(Icons.meeting_room_outlined, '$odaSayisi Oda', AppColors.teal),
              _bilgiCip(Icons.attach_money, '₺${fiyat.toStringAsFixed(0)} / gece', Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  // ── ODA TİPİ EKLEME / DÜZENLEME BOTTOM SHEET ──────────────────
  // mevcutDoc: null → yeni ekleme, dolu → düzenleme modu
  void _odaTipiDialog({DocumentSnapshot? mevcutDoc}) {
    // Mevcut değerleri forma doldur (düzenleme modunda)
    final data = mevcutDoc?.data() as Map<String, dynamic>?;

    final tipCtrl = TextEditingController(text: data?['odaTipiAdi'] ?? '');
    final fiyatCtrl = TextEditingController(
        text: data?['fiyat'] != null
            ? (data!['fiyat'] as double).toStringAsFixed(0)
            : '');
    // Oda sayısı yazılabilir alan
    final odaSayisiCtrl = TextEditingController(
        text: '${data?['odaSayisi'] ?? 1}');

    // Yatak sayıları +/- butonlarıyla değişir
    int cift = data?['ciftKisilikYatak'] ?? 0;
    int tek  = data?['tekKisilikYatak']  ?? 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgTop,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      // StatefulBuilder: bottom sheet kendi içinde setState yapabilsin
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Başlık + kapat butonu
                Row(
                  children: [
                    Text(
                      mevcutDoc == null ? 'Yeni Oda Tipi Ekle' : 'Oda Tipini Düzenle',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Oda tipi adı metin alanı
                _modalField(tipCtrl, 'Oda Tipi Adı', Icons.label_outline),
                const SizedBox(height: 20),

                // Çift kişilik yatak sayacı
                _sayacSatiri(
                  ikon: Icons.king_bed_outlined,
                  etiket: 'Çift Kişilik Yatak',
                  deger: cift,
                  onAzalt: cift > 0 ? () => setModal(() => cift--) : null,
                  onArtir: () => setModal(() => cift++),
                ),
                const SizedBox(height: 12),

                // Tek kişilik yatak sayacı
                _sayacSatiri(
                  ikon: Icons.single_bed_outlined,
                  etiket: 'Tek Kişilik Yatak',
                  deger: tek,
                  onAzalt: tek > 0 ? () => setModal(() => tek--) : null,
                  onArtir: () => setModal(() => tek++),
                ),
                const SizedBox(height: 12),

                // Oda sayısı - elle yazılabilir metin alanı
                _modalField(
                  odaSayisiCtrl,
                  'Oda Sayısı',
                  Icons.meeting_room_outlined,
                  inputType: TextInputType.number,
                ),
                const SizedBox(height: 20),

                // Gecelik fiyat metin alanı
                _modalField(
                  fiyatCtrl,
                  'Gecelik Fiyat (₺)',
                  Icons.attach_money,
                  inputType: TextInputType.number,
                ),
                const SizedBox(height: 20),

                // Kaydet butonu
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _odaTipiKaydet(
                      ctx: ctx,
                      mevcutDoc: mevcutDoc,
                      tipCtrl: tipCtrl,
                      fiyatCtrl: fiyatCtrl,
                      odaSayisiCtrl: odaSayisiCtrl,
                      cift: cift,
                      tek: tek,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text(
                      mevcutDoc == null ? 'Oda Tipini Kaydet' : 'Güncelle',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // +/- sayaç satırı: ikon + etiket + azalt butonu + sayı + artır butonu
  Widget _sayacSatiri({
    required IconData ikon,
    required String etiket,
    required int deger,
    required VoidCallback? onAzalt, // null gelirse buton devre dışı
    required VoidCallback onArtir,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(ikon, color: Colors.white54, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              etiket,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          // Azalt butonu
          _sayacButon(Icons.remove, onAzalt),
          // Sayı göstergesi
          SizedBox(
            width: 36,
            child: Text(
              '$deger',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Artır butonu
          _sayacButon(Icons.add, onArtir),
        ],
      ),
    );
  }

  // Sayaç için +/- buton widget'ı
  Widget _sayacButon(IconData ikon, VoidCallback? onTap) {
    final aktif = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: aktif
              ? AppColors.teal.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: aktif
                ? AppColors.teal.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Icon(
          ikon,
          size: 16,
          color: aktif ? AppColors.teal : Colors.white24,
        ),
      ),
    );
  }

  // Oda tipini Firestore'a kaydeder veya günceller
  Future<void> _odaTipiKaydet({
    required BuildContext ctx,
    required DocumentSnapshot? mevcutDoc,
    required TextEditingController tipCtrl,
    required TextEditingController fiyatCtrl,
    required TextEditingController odaSayisiCtrl,
    required int cift,
    required int tek,
  }) async {
    // Zorunlu alan kontrolü
    if (tipCtrl.text.trim().isEmpty || fiyatCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Oda tipi adı ve fiyat zorunludur.'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    // En az bir yatak seçilmeli
    if (cift == 0 && tek == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('En az bir yatak sayısı seçmelisiniz.'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    // Oda sayısını controller'dan oku (metin → int)
    final odaSayisi = int.tryParse(odaSayisiCtrl.text.trim()) ?? 1;

    // ScaffoldMessenger'ı async öncesinde yakala
    final messengerRef = ScaffoldMessenger.of(context);

    // odaDurumlari map'ini oluştur: her oda numarası için müsaitlik değeri
    // Yeni eklemede hepsi true (müsait), güncellemede mevcut durumlar korunur
    final yeniDurumlari = <String, bool>{};
    if (mevcutDoc != null) {
      final mevcutData = mevcutDoc.data() as Map<String, dynamic>;
      final mevcutDurumlari =
          Map<String, dynamic>.from(mevcutData['odaDurumlari'] ?? {});
      for (int i = 1; i <= odaSayisi; i++) {
        yeniDurumlari['$i'] = mevcutDurumlari['$i'] as bool? ?? true;
      }
    } else {
      for (int i = 1; i <= odaSayisi; i++) {
        yeniDurumlari['$i'] = true;
      }
    }

    // Kaydedilecek veri
    final odaData = {
      'yoneticiUid': _uid,
      'tesisAdi': _tesisAdi,
      'odaTipiAdi': tipCtrl.text.trim(),
      'ciftKisilikYatak': cift,
      'tekKisilikYatak': tek,
      'fiyat': double.tryParse(fiyatCtrl.text.trim()) ?? 0.0,
      'odaSayisi': odaSayisi,
      'odaDurumlari': yeniDurumlari,
      'guncellemeTarihi': FieldValue.serverTimestamp(),
    };

    if (mevcutDoc == null) {
      // Yeni oda tipi → Firestore'a ekle
      odaData['olusturmaTarihi'] = FieldValue.serverTimestamp();
      await _firestore.collection('odalar').add(odaData);

      // Log: yeni oda tipi eklendi
      await _firestore.collection('logs').add({
        'uid': _uid,
        'action': 'oda_eklendi',
        'odaTipiAdi': tipCtrl.text.trim(),
        'tesisAdi': _tesisAdi,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      // Mevcut oda tipi → Firestore'da güncelle
      await _firestore.collection('odalar').doc(mevcutDoc.id).update(odaData);

      // Log: oda tipi güncellendi
      await _firestore.collection('logs').add({
        'uid': _uid,
        'action': 'oda_guncellendi',
        'odaTipiAdi': tipCtrl.text.trim(),
        'tesisAdi': _tesisAdi,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    if (!ctx.mounted) return;
    Navigator.pop(ctx); // Bottom sheet'i kapat

    // Başarı bildirimi
    messengerRef.showSnackBar(SnackBar(
      content: Text(
        mevcutDoc == null ? 'Oda tipi başarıyla eklendi.' : 'Oda tipi güncellendi.',
      ),
      backgroundColor: AppColors.teal,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── ODA LİSTESİ BOTTOM SHEET ──────────────────────────────────
  // Oda tipine tıklanınca o tipe ait tüm odaları listeler
  // StreamBuilder kullandığı için müsaitlik değişimlerini anlık yansıtır
  void _odaListesiGoster(String docId, String tipAdi, int odaSayisi) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgTop,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SizedBox(
        // Ekran yüksekliğinin %70'i kadar alan kapla
        height: MediaQuery.of(ctx).size.height * 0.7,
        child: Column(
          children: [
            // ── Başlık çubuğu ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 8, 12),
              child: Row(
                children: [
                  const Icon(Icons.meeting_room_outlined,
                      color: AppColors.teal, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tipAdi,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$odaSayisi oda',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),

            // ── Sütun başlıkları ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: const [
                  Expanded(
                    child: Text('Oda',
                        style: TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                  Text('Durum',
                      style: TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),

            // ── Oda listesi (StreamBuilder ile gerçek zamanlı) ──
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                // Bu oda tipinin Firestore belgesini dinle
                stream: _firestore.collection('odalar').doc(docId).snapshots(),
                builder: (ctx, snap) {
                  if (!snap.hasData) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.teal));
                  }

                  final data = snap.data!.data() as Map<String, dynamic>;
                  // odaDurumlari: {"1": true, "2": false, ...}
                  final durumlari = Map<String, dynamic>.from(
                      data['odaDurumlari'] ?? {});

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: odaSayisi,
                    separatorBuilder: (context, index) =>
                        const Divider(color: Colors.white10, height: 1),
                    itemBuilder: (ctx, i) {
                      final odaNo = '${i + 1}';
                      // Firestore'da kayıt yoksa varsayılan olarak müsait
                      final musait = durumlari[odaNo] as bool? ?? true;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            // Oda numarası
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.teal.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  odaNo,
                                  style: const TextStyle(
                                    color: AppColors.teal,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Oda adı
                            Expanded(
                              child: Text(
                                '$odaNo Nolu Oda',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14),
                              ),
                            ),
                            // Sadece müsait odalarda "Rezerve Et" butonu göster
                            if (musait) ...[
                              GestureDetector(
                                onTap: () => _odayiRezerveEt(
                                    ctx, docId, odaNo, tipAdi, durumlari),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.teal.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.teal.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: const Text(
                                    'Rezerve Et',
                                    style: TextStyle(
                                      color: AppColors.teal,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            // Müsaitlik durumu - tıklanınca değişir
                            GestureDetector(
                              onTap: () => _odaMusaitlikDegistir(
                                docId, odaNo, !musait, durumlari),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: musait
                                      ? Colors.green.withValues(alpha: 0.15)
                                      : Colors.redAccent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: musait
                                        ? Colors.green.withValues(alpha: 0.4)
                                        : Colors.redAccent.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  musait ? 'Müsait' : 'Dolu',
                                  style: TextStyle(
                                    color: musait
                                        ? Colors.green
                                        : Colors.redAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Yönetici panelinden manuel rezervasyon yapar
  // Odayı "dolu" olarak işaretler ve rezervasyonlar koleksiyonuna kayıt ekler
  Future<void> _odayiRezerveEt(
    BuildContext ctx,
    String docId,
    String odaNo,
    String tipAdi,
    Map<String, dynamic> mevcutDurumlari,
  ) async {
    // Onay dialogu - yanlışlıkla tıklamayı önler
    final onay = await showDialog<bool>(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '$odaNo Nolu Odayı Rezerve Et',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        content: const Text(
          'Bu oda dolu olarak işaretlenecek ve rezervasyon kaydı oluşturulacak.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: const Text('İptal',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dCtx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Rezerve Et'),
          ),
        ],
      ),
    );

    if (onay != true) return;

    // Odayı dolu olarak işaretle
    final yeniDurumlari = Map<String, dynamic>.from(mevcutDurumlari);
    yeniDurumlari[odaNo] = false; // false = dolu
    await _firestore
        .collection('odalar')
        .doc(docId)
        .update({'odaDurumlari': yeniDurumlari});

    // Rezervasyon kaydını oluştur
    await _firestore.collection('rezervasyonlar').add({
      'odaId': docId,
      'odaNo': odaNo,
      'odaTip': tipAdi,
      'yoneticiUid': _uid,
      'tesisAdi': _tesisAdi,
      'misafirUid': 'manuel',        // Yönetici tarafından manuel eklendi
      'misafirEmail': '-',
      'misafirAdi': 'Manuel Rezervasyon',
      'durum': 'onaylandi',          // Manuel rezervasyon direkt onaylı sayılır
      'olusturmaTarihi': FieldValue.serverTimestamp(),
    });

    // Log kaydı
    await _firestore.collection('logs').add({
      'uid': _uid,
      'action': 'manuel_rezervasyon',
      'odaNo': odaNo,
      'odaTipiAdi': tipAdi,
      'tesisAdi': _tesisAdi,
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$odaNo nolu oda rezerve edildi.'),
      backgroundColor: AppColors.teal,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // Tek bir odanın müsaitlik durumunu Firestore'da günceller
  // odaDurumlari map'indeki ilgili anahtarı değiştirir
  Future<void> _odaMusaitlikDegistir(
    String docId,
    String odaNo,
    bool yeniDurum,
    Map<String, dynamic> mevcutDurumlari,
  ) async {
    // Mevcut map'i kopyalayıp sadece bu odanın değerini değiştir
    final yeniDurumlari = Map<String, dynamic>.from(mevcutDurumlari);
    yeniDurumlari[odaNo] = yeniDurum;
    await _firestore
        .collection('odalar')
        .doc(docId)
        .update({'odaDurumlari': yeniDurumlari});
  }

  // Oda tipini silme işlemi (onay dialogu ile)
  Future<void> _odaTipiSil(String docId, String tipAdi) async {
    // Onay dialogu göster
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Oda Tipini Sil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          '"$tipAdi" tipi silinecek.\nBu işlem geri alınamaz.',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (onay != true) return;

    // Firestore'dan sil
    await _firestore.collection('odalar').doc(docId).delete();

    // Log: oda tipi silindi
    await _firestore.collection('logs').add({
      'uid': _uid,
      'action': 'oda_silindi',
      'odaTipiAdi': tipAdi,
      'tesisAdi': _tesisAdi,
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('"$tipAdi" silindi.'),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── FORM ALANI YARDIMCI WİDGET'I ──────────────────────────────
  // Bottom sheet içindeki text alanlarının ortak tasarımı
  Widget _modalField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? inputType,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: inputType,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      ),
    );
  }
}
