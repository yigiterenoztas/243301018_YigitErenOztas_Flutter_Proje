import 'package:flutter/material.dart';
import '../../constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Rezervasyon onay ekranı - misafirin seçtiği odayı rezerve ettiği ekran
// room_detail_screen.dart'tan tüm bilgiler parametre olarak gelir
class ReservationScreen extends StatefulWidget {
  final String odaId;          // Firestore'daki oda belge ID'si
  final String odaNo;          // Oda numarası (gösterim için)
  final String odaTip;         // Oda tipi (Standart, Delüks vb.)
  final String yoneticiUid;    // Tesis yöneticisinin UID'si
  final String tesisAdi;       // Tesis adı
  final DateTime girisTarihi;  // Seçilen giriş tarihi
  final DateTime cikisTarihi;  // Seçilen çıkış tarihi
  final int erkekSayisi;       // Kişi sayıları
  final int kadinSayisi;
  final int cocukSayisi;
  final double gecelikFiyat;   // Odanın gecelik ücreti
  final int geceSayisi;        // Toplam kaç gece

  const ReservationScreen({
    super.key,
    required this.odaId,
    required this.odaNo,
    required this.odaTip,
    required this.yoneticiUid,
    required this.tesisAdi,
    required this.girisTarihi,
    required this.cikisTarihi,
    required this.erkekSayisi,
    required this.kadinSayisi,
    required this.cocukSayisi,
    required this.gecelikFiyat,
    required this.geceSayisi,
  });

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  // Renk sabitleri

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Rezervasyon gönderilirken true olur (butonu devre dışı bırakmak için)
  bool _isLoading = false;

  // Toplam tutar hesaplama: gecelik fiyat × gece sayısı
  double get _toplamTutar => widget.gecelikFiyat * widget.geceSayisi;

  // Tarihi gün.ay.yıl formatında döndürür
  String _tarihFormat(DateTime tarih) =>
      '${tarih.day.toString().padLeft(2, '0')}.${tarih.month.toString().padLeft(2, '0')}.${tarih.year}';

  // Rezervasyon talebini Firestore'a gönderir
  Future<void> _rezervasyonGonder() async {
    setState(() => _isLoading = true);

    // Giriş yapan kullanıcının bilgilerini al
    final kullanici = _auth.currentUser;
    if (kullanici == null) return;

    // Kullanıcının adını Firestore'dan çek
    final userDoc = await _firestore.collection('users').doc(kullanici.uid).get();
    final ad = userDoc.data()?['ad'] ?? '';
    final soyad = userDoc.data()?['soyad'] ?? '';

    // 'rezervasyonlar' koleksiyonuna yeni belge ekle
    await _firestore.collection('rezervasyonlar').add({
      'odaId': widget.odaId,
      'odaNo': widget.odaNo,
      'odaTip': widget.odaTip,
      'yoneticiUid': widget.yoneticiUid,       // Hangi yöneticiye gideceği
      'tesisAdi': widget.tesisAdi,
      'misafirUid': kullanici.uid,              // Rezervasyonu yapan kullanıcı
      'misafirEmail': kullanici.email,
      'misafirAdi': '$ad $soyad',
      'girisTarihi': _tarihFormat(widget.girisTarihi),
      'cikisTarihi': _tarihFormat(widget.cikisTarihi),
      'erkekSayisi': widget.erkekSayisi,
      'kadinSayisi': widget.kadinSayisi,
      'cocukSayisi': widget.cocukSayisi,
      'geceSayisi': widget.geceSayisi,
      'gecelikFiyat': widget.gecelikFiyat,
      'toplamTutar': _toplamTutar,
      'durum': 'beklemede',                     // Yönetici onaylayana kadar beklemede
      'olusturmaTarihi': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    setState(() => _isLoading = false);

    // Başarı dialogu göster
    _basariDiaogGoster();
  }

  // Rezervasyon başarıyla oluşturulunca gösterilen dialog
  void _basariDiaogGoster() {
    showDialog(
      context: context,
      barrierDismissible: false, // Dışına tıklayınca kapanmasın
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: AppColors.teal, size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'Rezervasyon Alındı!',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Talebiniz tesis yöneticisine iletildi. Onay bekleniyor.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Dialogu kapat ve login ekranına kadar tüm ekranları kaldır
                  Navigator.of(ctx).pop();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Tamam',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          _buildHeader(), // Üst başlık
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildOdaBilgiKarti(),   // Oda detay kartı
                  const SizedBox(height: 16),
                  _buildTarihKarti(),      // Tarih ve gece bilgisi
                  const SizedBox(height: 16),
                  _buildKisiKarti(),       // Kişi sayıları
                  const SizedBox(height: 16),
                  _buildFiyatKarti(),      // Fiyat özeti
                  const SizedBox(height: 28),
                  _buildRezerveEtButon(),  // Rezervasyon gönder butonu
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Üst başlık çubuğu
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
      decoration: const BoxDecoration(
        color: AppColors.bgTop,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          // Geri butonu
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rezervasyon Özeti',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              Text('Bilgileri kontrol edip onaylayın',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  // Oda bilgileri kartı
  Widget _buildOdaBilgiKarti() {
    return _infoKart(
      baslik: 'Oda Bilgileri',
      ikon: Icons.bed_outlined,
      ikonRenk: AppColors.teal,
      icerik: Column(
        children: [
          _satirWidget('Tesis', widget.tesisAdi),
          _satirWidget('Oda No', widget.odaNo),
          _satirWidget('Oda Tipi', widget.odaTip),
        ],
      ),
    );
  }

  // Tarih ve gece sayısı kartı
  Widget _buildTarihKarti() {
    return _infoKart(
      baslik: 'Tarih Bilgileri',
      ikon: Icons.calendar_today_outlined,
      ikonRenk: Colors.blue,
      icerik: Column(
        children: [
          _satirWidget('Giriş Tarihi', _tarihFormat(widget.girisTarihi)),
          _satirWidget('Çıkış Tarihi', _tarihFormat(widget.cikisTarihi)),
          _satirWidget('Konaklama', '${widget.geceSayisi} gece'),
        ],
      ),
    );
  }

  // Kişi sayıları kartı
  Widget _buildKisiKarti() {
    return _infoKart(
      baslik: 'Kişi Bilgileri',
      ikon: Icons.people_outline,
      ikonRenk: Colors.purple,
      icerik: Column(
        children: [
          // Sadece 0'dan büyük olanları göster
          if (widget.erkekSayisi > 0)
            _satirWidget('Erkek', '${widget.erkekSayisi} kişi'),
          if (widget.kadinSayisi > 0)
            _satirWidget('Kadın', '${widget.kadinSayisi} kişi'),
          if (widget.cocukSayisi > 0)
            _satirWidget('Çocuk', '${widget.cocukSayisi} kişi'),
          _satirWidget(
            'Toplam',
            '${widget.erkekSayisi + widget.kadinSayisi + widget.cocukSayisi} kişi',
            kalin: true, // Toplam satırını kalın göster
          ),
        ],
      ),
    );
  }

  // Fiyat özeti kartı
  Widget _buildFiyatKarti() {
    return _infoKart(
      baslik: 'Fiyat Özeti',
      ikon: Icons.attach_money,
      ikonRenk: Colors.green,
      icerik: Column(
        children: [
          _satirWidget(
              'Gecelik Fiyat', '₺${widget.gecelikFiyat.toStringAsFixed(0)}'),
          _satirWidget('Gece Sayısı', '${widget.geceSayisi} gece'),
          const Divider(height: 20),
          // Toplam tutar büyük puntolarla gösterilir
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Toplam Tutar',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black87)),
              Text(
                '₺${_toplamTutar.toStringAsFixed(0)}',
                style: const TextStyle(
                    color: AppColors.bgTop,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Rezervasyon gönder butonu
  Widget _buildRezerveEtButon() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        // Yükleniyorken butonu devre dışı bırak
        onPressed: _isLoading ? null : _rezervasyonGonder,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.bgTop,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade400,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
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
                'Rezervasyon Talebi Gönder',
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }

  // Yeniden kullanılabilir bilgi kartı çerçevesi
  Widget _infoKart({
    required String baslik,
    required IconData ikon,
    required Color ikonRenk,
    required Widget icerik,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kart başlığı (ikon + yazı)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: ikonRenk.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(ikon, color: ikonRenk, size: 17),
              ),
              const SizedBox(width: 10),
              Text(baslik,
                  style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 14),
          icerik, // Kartın asıl içeriği
        ],
      ),
    );
  }

  // Etiket - değer çifti satırı
  // kalin: toplam gibi önemli satırları vurgulamak için
  Widget _satirWidget(String etiket, String deger, {bool kalin = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiket,
              style: const TextStyle(color: Colors.black45, fontSize: 13)),
          Text(deger,
              style: TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  fontWeight: kalin ? FontWeight.bold : FontWeight.w500)),
        ],
      ),
    );
  }
}
