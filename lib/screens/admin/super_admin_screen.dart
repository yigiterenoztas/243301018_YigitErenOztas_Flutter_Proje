import 'package:flutter/material.dart';
import '../../constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

// Süper Admin ekranı - uygulamanın en yetkili kullanıcısının paneli
class SuperAdminScreen extends StatefulWidget {
  const SuperAdminScreen({super.key});

  @override
  State<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends State<SuperAdminScreen> {
  // Renk sabitleri - uygulamanın genel renk teması

  // Firestore veritabanına erişim nesnesi
  final _firestore = FirebaseFirestore.instance;

  // Hangi sekmenin seçili olduğunu tutan değişken (0 = Ana Sayfa, 1 = Talepler)
  int _secilenSekme = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgTop,
      body: Container(
        // Arka plana gradient (renk geçişi) ekliyoruz
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bgTop, AppColors.bgBottom],
          ),
        ),
        child: SafeArea(
          // IndexedStack: her iki sekmeyi de arka planda hayatta tutar StreamBuilder yerine kullanıldı
          // Sekme değişiminde widget yeniden oluşturulmaz, sadece hangisinin
          // görünür olduğu değişir → StreamBuilder bağlantısı hiç kopmaz,
          // Firestore önbelleğinden eski veri flaşı olmaz
          child: IndexedStack(
            index: _secilenSekme,
            children: [_buildAnasayfa(), _buildTalepler()],
          ),
        ),
      ),
      // Alt navigasyon çubuğu
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // Alt navigasyon çubuğunu oluşturan metot
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        // Üst kenara ince bir çizgi çekiyoruz
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          // Ana Sayfa ve Talepler butonları
          _navItem(0, Icons.home_outlined, Icons.home, 'Ana Sayfa'),
          _navItem(
            1,
            Icons.pending_actions_outlined,
            Icons.pending_actions,
            'Talepler',
          ),
        ],
      ),
    );
  }

  // Her bir nav butonunu oluşturan yardımcı metot
  // index: hangi sekme, ikon: pasif ikon, aktifIkon: seçiliyken ikon, label: yazı
  Widget _navItem(int index, IconData ikon, IconData aktifIkon, String label) {
    final secili = _secilenSekme == index; // Bu buton seçili mi?
    return Expanded(
      child: GestureDetector(
        // Butona tıklanınca seçili sekmeyi güncelle
        onTap: () => setState(() => _secilenSekme = index),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Seçiliyse dolu ikon, değilse outline ikon göster
              Icon(
                secili ? aktifIkon : ikon,
                color: secili ? AppColors.teal : Colors.white38,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: secili ? AppColors.teal : Colors.white38,
                  fontSize: 11,
                  fontWeight: secili ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── ANA SAYFA SEKMESİ ─────────────────────────────────────────
  // Onaylı tesis yöneticilerini listeler
  Widget _buildAnasayfa() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Başlık ve çıkış butonu
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
          child: Row(
            children: [
              const Text(
                'Tesis Yöneticileri',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white54),
                onPressed: () async {
                  // Navigator'ı async öncesinde yakala
                  // Async boşluktan sonra context kullanımını engellemek için
                  final nav = Navigator.of(context);
                  await AuthService().logout();
                  nav.pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
            ],
          ),
        ),
        // Onaylı yöneticilerin listesi
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('users')
                .where('role', isEqualTo: 'yonetici')
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.teal),
                );
              }
              final liste = snap.data!.docs;

              // Yönetici yoksa bilgi mesajı
              if (liste.isEmpty) {
                return const Center(
                  child: Text(
                    'Henüz onaylı yönetici yok.',
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                );
              }

              // Yöneticileri alt alta listele
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: liste.length,
                itemBuilder: (ctx, i) {
                  final data = liste[i].data() as Map<String, dynamic>;
                  final ad = data['ad'] ?? '';
                  final soyad = data['soyad'] ?? '';
                  final email = data['email'] ?? '';
                  final tesisAdi = data['tesisAdi'] ?? '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.07),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Baş harfi gösteren avatar
                        CircleAvatar(
                          backgroundColor: Colors.green.withValues(alpha: 0.15),
                          child: Text(
                            ad.isNotEmpty ? ad[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Yönetici bilgileri - Expanded ile kalan alanı kaplar
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$ad $soyad',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                tesisAdi,
                                style: const TextStyle(
                                  color: AppColors.teal,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                email,
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Silme butonu - kartın sağ köşesinde çarpı ikonu
                        GestureDetector(
                          onTap: () => _yoneticiSil(
                            liste[i].id,
                            '$ad $soyad',
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              // Kırmızı arka plan - silme işlemini simgeler
                              color: Colors.redAccent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.redAccent,
                              size: 16,
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
    );
  }

  // ── TALEPLER SEKMESİ ─────────────────────────────────────────
  Widget _buildTalepler() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Text(
            'Yönetici Talepleri',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            // Sadece 'pending_yonetici' rolündeki kullanıcıları dinle
            stream: _firestore
                .collection('users')
                .where('role', isEqualTo: 'pending_yonetici')
                .snapshots(),
            builder: (context, snap) {
              // Veri henüz gelmediyse yükleniyor göstergesi
              if (!snap.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.teal),
                );
              }

              final liste = snap.data!.docs;

              // Bekleyen talep yoksa boş durum mesajı göster
              if (liste.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: AppColors.teal,
                        size: 48,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Bekleyen talep yok.',
                        style: TextStyle(color: Colors.white54, fontSize: 15),
                      ),
                    ],
                  ),
                );
              }

              // Talepler listesini göster
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: liste.length,
                itemBuilder: (ctx, i) {
                  final data = liste[i].data() as Map<String, dynamic>;
                  // Her talep için kart oluştur
                  return _talepKarti(liste[i].id, data);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Tek bir talep kartını oluşturan metot
  // uid: Firestore'daki kullanıcı ID'si, data: kullanıcı bilgileri
  Widget _talepKarti(String uid, Map<String, dynamic> data) {
    // Firestore'dan gelen verileri değişkenlere aktar
    // ?? operatörü: değer null ise sağdaki default değeri kullan
    final ad = data['ad'] ?? '';
    final soyad = data['soyad'] ?? '';
    final email = data['email'] ?? '';
    final tesisAdi = data['tesisAdi'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        // Turuncu kenarlık - "beklemede" durumunu simgeler
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kullanıcı adı ve soyadı
          Text(
            '$ad $soyad',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            email,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 2),
          // Tesis adını teal rengiyle vurgula
          Text(
            'Tesis: $tesisAdi',
            style: const TextStyle(color: AppColors.teal, fontSize: 13),
          ),
          const SizedBox(height: 14),
          // Onayla / Reddet butonları yan yana
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _reddet(uid, '$ad $soyad'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Reddet'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _onayla(uid, '$ad $soyad'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Onayla'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── YÖNETİCİ SİL ─────────────────────────────────────────────
  // Onaylı bir tesis yöneticisini sistemden kaldırır
  // Firestore'daki kullanıcı belgesi silinir → giriş yapsa bile rol bulunamaz
  Future<void> _yoneticiSil(String uid, String isim) async {
    // Silmeden önce onay dialogu göster - yanlışlıkla silmeyi önler
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Yöneticiyi Sil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          '$isim adlı yönetici sistemden silinecek.\nBu işlem geri alınamaz.',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          // İptal butonu - işlemi durdurur
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal', style: TextStyle(color: Colors.white54)),
          ),
          // Sil butonu - işlemi onaylar
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

    // Kullanıcı iptal ettiyse işlem yapma
    if (onay != true) return;

    // Firestore'dan kullanıcı belgesini sil
    await _firestore.collection('users').doc(uid).delete();

    if (!mounted) return;
    // Başarı bildirimi
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$isim sistemden silindi.'),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // Yönetici talebini onaylayan metot
  // Firestore'da kullanıcının rolünü 'pending_yonetici' → 'yonetici' yapar
  Future<void> _onayla(String uid, String isim) async {
    await _firestore.collection('users').doc(uid).update({'role': 'yonetici'});
    if (!mounted) return;
    // Başarı mesajı göster
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$isim onaylandı.'),
        backgroundColor: AppColors.teal,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Yönetici talebini reddeden metot
  // Firestore'da kullanıcının rolünü 'pending_yonetici' → 'rejected' yapar
  Future<void> _reddet(String uid, String isim) async {
    await _firestore.collection('users').doc(uid).update({'role': 'rejected'});
    if (!mounted) return;
    // Hata/red mesajı göster
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$isim reddedildi.'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
