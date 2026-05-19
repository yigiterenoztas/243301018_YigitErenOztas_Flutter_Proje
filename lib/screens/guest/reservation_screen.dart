import 'package:flutter/material.dart';
import '../../constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReservationScreen extends StatefulWidget {
  final String odaId;
  final String odaNo;
  final String odaTip;
  final String yoneticiUid;
  final String tesisAdi;
  final DateTime girisTarihi;
  final DateTime cikisTarihi;
  final int erkekSayisi;
  final int kadinSayisi;
  final int cocukSayisi;
  final double gecelikFiyat;
  final int geceSayisi;

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
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  bool _isLoading = false;

  double get _toplamTutar =>
      widget.gecelikFiyat * widget.geceSayisi;

  String _tarihFormat(DateTime t) =>
      '${t.day.toString().padLeft(2, '0')}.'
      '${t.month.toString().padLeft(2, '0')}.'
      '${t.year}';

  Future<void> _rezervasyonGonder() async {
    setState(() => _isLoading = true);

    final kullanici = _auth.currentUser;
    if (kullanici == null) return;

    final userDoc = await _firestore
        .collection('users')
        .doc(kullanici.uid)
        .get();
    final ad = userDoc.data()?['ad'] ?? '';
    final soyad = userDoc.data()?['soyad'] ?? '';

    final rezRef = await _firestore.collection('rezervasyonlar').add({
      'odaId': widget.odaId,
      'odaNo': widget.odaNo,
      'odaTip': widget.odaTip,
      'yoneticiUid': widget.yoneticiUid,
      'tesisAdi': widget.tesisAdi,
      'misafirUid': kullanici.uid,
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
      'durum': 'beklemede',
      'olusturmaTarihi': FieldValue.serverTimestamp(),
    });

    // Log: misafir rezervasyon talebi oluşturdu
    await _firestore.collection('logs').add({
      'action': 'rezervasyon_olusturuldu',
      'rezervasyonId': rezRef.id,
      'misafirUid': kullanici.uid,
      'misafirAdi': '$ad $soyad',
      'tesisAdi': widget.tesisAdi,
      'odaNo': widget.odaNo,
      'odaTip': widget.odaTip,
      'girisTarihi': _tarihFormat(widget.girisTarihi),
      'cikisTarihi': _tarihFormat(widget.cikisTarihi),
      'toplamTutar': _toplamTutar,
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    setState(() => _isLoading = false);
    _basariDialogGoster();
  }

  void _basariDialogGoster() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color:
                          AppColors.teal.withValues(alpha: 0.3),
                      width: 2),
                ),
                child: const Icon(Icons.check_rounded,
                    color: AppColors.teal, size: 44),
              ),
              const SizedBox(height: 20),
              const Text(
                'Rezervasyon Alındı!',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Talebiniz tesis yöneticisine iletildi.\nOnay bekleniyor.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white54, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context)
                        .popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Tamam',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
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
              // ── ÜST BAŞLIK ──────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                        child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 18),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rezervasyon Özeti',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Bilgileri kontrol edip onaylayın',
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── İÇERİK ──────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                      16, 8, 16, 20),
                  child: Column(
                    children: [
                      // Tesis & oda bilgileri
                      _bilgiKarti(
                        baslik: 'Oda Bilgileri',
                        ikon: Icons.bed_outlined,
                        ikonRenk: AppColors.teal,
                        satirlar: [
                          _Satir('Tesis', widget.tesisAdi),
                          _Satir('Oda No',
                              '${widget.odaNo} Nolu Oda'),
                          _Satir('Oda Tipi', widget.odaTip),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Tarih bilgileri
                      _bilgiKarti(
                        baslik: 'Tarih Bilgileri',
                        ikon: Icons.calendar_today_outlined,
                        ikonRenk: Colors.blue,
                        satirlar: [
                          _Satir('Giriş Tarihi',
                              _tarihFormat(widget.girisTarihi)),
                          _Satir('Çıkış Tarihi',
                              _tarihFormat(widget.cikisTarihi)),
                          _Satir('Konaklama',
                              '${widget.geceSayisi} gece'),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Kişi bilgileri
                      _bilgiKarti(
                        baslik: 'Kişi Bilgileri',
                        ikon: Icons.people_outline,
                        ikonRenk: Colors.purple,
                        satirlar: [
                          if (widget.erkekSayisi > 0)
                            _Satir('Erkek',
                                '${widget.erkekSayisi} kişi'),
                          if (widget.kadinSayisi > 0)
                            _Satir('Kadın',
                                '${widget.kadinSayisi} kişi'),
                          if (widget.cocukSayisi > 0)
                            _Satir('Çocuk',
                                '${widget.cocukSayisi} kişi'),
                          _Satir(
                            'Toplam',
                            '${widget.erkekSayisi + widget.kadinSayisi + widget.cocukSayisi} kişi',
                            kalin: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Fiyat özeti
                      _fiyatKarti(),
                      const SizedBox(height: 28),

                      // Gönder butonu
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : _rezervasyonGonder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.teal,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppColors
                                .teal
                                .withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child:
                                      CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5),
                                )
                              : const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons
                                        .bookmark_add_outlined),
                                    SizedBox(width: 8),
                                    Text(
                                      'Rezervasyon Talebi Gönder',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight:
                                              FontWeight.w700),
                                    ),
                                  ],
                                ),
                        ),
                      ),
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

  // ── BİLGİ KARTI ───────────────────────────────────────────
  Widget _bilgiKarti({
    required String baslik,
    required IconData ikon,
    required Color ikonRenk,
    required List<_Satir> satirlar,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kart başlığı
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: ikonRenk.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    Icon(ikon, color: ikonRenk, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                baslik,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(
              height: 1,
              color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 12),
          // Satırlar
          ...satirlar.map((s) => _satirWidget(s)),
        ],
      ),
    );
  }

  Widget _satirWidget(_Satir s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            s.etiket,
            style: const TextStyle(
                color: Colors.white38, fontSize: 13),
          ),
          Text(
            s.deger,
            style: TextStyle(
              color: s.kalin ? Colors.white : Colors.white70,
              fontSize: 13,
              fontWeight: s.kalin
                  ? FontWeight.bold
                  : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── FİYAT KARTI ───────────────────────────────────────────
  Widget _fiyatKarti() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.teal.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.payments_outlined,
                    color: Colors.green, size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                'Fiyat Özeti',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(
              height: 1,
              color: Colors.white.withValues(alpha: 0.06)),
          const SizedBox(height: 12),
          _satirWidget(_Satir('Gecelik Fiyat',
              '₺${widget.gecelikFiyat.toStringAsFixed(0)}')),
          _satirWidget(
              _Satir('Gece Sayısı', '${widget.geceSayisi} gece')),
          Divider(
              height: 20,
              color: Colors.white.withValues(alpha: 0.08)),
          // Toplam tutar - vurgulu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Toplam Tutar',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color:
                          AppColors.teal.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '₺${_toplamTutar.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: AppColors.teal,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Satır verisi için yardımcı sınıf
class _Satir {
  final String etiket;
  final String deger;
  final bool kalin;

  const _Satir(this.etiket, this.deger, {this.kalin = false});
}
