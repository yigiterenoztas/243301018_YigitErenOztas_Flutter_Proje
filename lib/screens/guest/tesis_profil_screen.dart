import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants.dart';
import 'reservation_screen.dart';

class TesisProfilScreen extends StatefulWidget {
  final Map<String, dynamic> otel;

  const TesisProfilScreen({super.key, required this.otel});

  @override
  State<TesisProfilScreen> createState() => _TesisProfilScreenState();
}

class _TesisProfilScreenState extends State<TesisProfilScreen> {
  final _firestore = FirebaseFirestore.instance;

  // Tarih & kişi (bottom sheet ile paylaşılır)
  DateTime? _girisTarihi;
  DateTime? _cikisTarihi;
  int _erkek = 1;
  int _kadin = 0;
  int _cocuk = 0;

  int get _geceSayisi {
    if (_girisTarihi == null || _cikisTarihi == null) return 0;
    return _cikisTarihi!.difference(_girisTarihi!).inDays;
  }

  String _tarihFormat(DateTime? t) {
    if (t == null) return 'Seçilmedi';
    return '${t.day.toString().padLeft(2, '0')}.'
        '${t.month.toString().padLeft(2, '0')}.'
        '${t.year}';
  }

  // "dd.MM.yyyy" formatındaki string'i DateTime'a çevirir
  DateTime? _tarihParse(dynamic s) {
    if (s == null || s is! String || s.isEmpty) return null;
    final parcalar = s.split('.');
    if (parcalar.length != 3) return null;
    try {
      return DateTime(
        int.parse(parcalar[2]), // yıl
        int.parse(parcalar[1]), // ay
        int.parse(parcalar[0]), // gün
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _tarihSec(bool giris, StateSetter modalSet) async {
    final simdi = DateTime.now();
    final secilen = await showDatePicker(
      context: context,
      initialDate: giris
          ? (_girisTarihi ?? simdi)
          : (_cikisTarihi ?? simdi.add(const Duration(days: 1))),
      firstDate: simdi,
      lastDate: simdi.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
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
          if (_cikisTarihi != null &&
              !_cikisTarihi!.isAfter(secilen)) {
            _cikisTarihi = null;
          }
        } else {
          _cikisTarihi = secilen;
        }
      });
      modalSet(() {});
    }
  }

  // Kapasite: çift kişilik * 2 + tek kişilik * 1
  int _maxKapasite(Map<String, dynamic> oda) {
    final int cift = oda['ciftKisilikYatak'] ?? 0;
    final int tek = oda['tekKisilikYatak'] ?? 0;
    return cift * 2 + tek;
  }

  void _kisiDegistir(String tip, bool artir, StateSetter modalSet,
      int maxKap) {
    final toplam = _erkek + _kadin + _cocuk;
    setState(() {
      if (artir && toplam >= maxKap) return; // kapasiteyi aşma
      if (tip == 'erkek') {
        if (artir) {
          _erkek++;
        } else if (_erkek > 0) {
          _erkek--;
        }
      } else if (tip == 'kadin') {
        if (artir) {
          _kadin++;
        } else if (_kadin > 0) {
          _kadin--;
        }
      } else {
        if (artir) {
          _cocuk++;
        } else if (_cocuk > 0) {
          _cocuk--;
        }
      }
    });
    modalSet(() {});
  }

  void _mesajGoster(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m),
      backgroundColor: AppColors.card,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
    ));
  }

  // Oda tipine tıklayınca açılan detay bottom sheet
  void _odaTipiDetayAc(String docId, Map<String, dynamic> oda) {
    final String tip = oda['odaTipiAdi'] ?? 'Oda';
    final int cift = oda['ciftKisilikYatak'] ?? 0;
    final int tek = oda['tekKisilikYatak'] ?? 0;
    final double fiyat = (oda['fiyat'] ?? 0.0).toDouble();
    final int odaSayisi = oda['odaSayisi'] ?? 0;
    final int maxKap = _maxKapasite(oda);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          final int toplam = _erkek + _kadin + _cocuk;

          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (ctx, scrollCtrl) => Container(
              decoration: const BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Tutamaç
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius:
                              BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(
                          20, 12, 20, 24),
                      children: [
                        // ── ODA TİPİ BAŞLIĞI ──────────────
                        Row(
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.teal
                                    .withValues(alpha: 0.15),
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.bed,
                                  color: AppColors.teal,
                                  size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tip,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '$odaSayisi oda  •  Max $maxKap kişi',
                                    style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Yatak & fiyat chip'leri
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            if (cift > 0)
                              _bilgiCip(
                                  Icons.king_bed_outlined,
                                  '$cift Çift Kişilik',
                                  Colors.blue),
                            if (tek > 0)
                              _bilgiCip(
                                  Icons.single_bed_outlined,
                                  '$tek Tek Kişilik',
                                  Colors.purple),
                            if (fiyat > 0)
                              _bilgiCip(
                                  Icons.attach_money,
                                  '₺${fiyat.toStringAsFixed(0)} / gece',
                                  AppColors.teal),
                          ],
                        ),

                        const SizedBox(height: 20),
                        _ayrac('Tarih Seçin',
                            Icons.calendar_today_outlined),
                        const SizedBox(height: 10),

                        // ── TARİH SEÇİMİ ──────────────────
                        Row(children: [
                          Expanded(
                              child: _tarihButon(
                                  'Giriş',
                                  _girisTarihi,
                                  () => _tarihSec(
                                      true, setModal))),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _tarihButon(
                                  'Çıkış',
                                  _cikisTarihi,
                                  () => _tarihSec(
                                      false, setModal))),
                        ]),

                        if (_geceSayisi > 0) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.teal
                                  .withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(8),
                              border: Border.all(
                                  color: AppColors.teal
                                      .withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                const Icon(
                                    Icons.nights_stay_outlined,
                                    color: AppColors.teal,
                                    size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  '$_geceSayisi gece'
                                  '${fiyat > 0 ? '  •  ₺${(fiyat * _geceSayisi).toStringAsFixed(0)} toplam' : ''}',
                                  style: const TextStyle(
                                      color: AppColors.teal,
                                      fontSize: 12,
                                      fontWeight:
                                          FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),
                        _ayrac('Kişi Sayısı',
                            Icons.people_outline),

                        // Kapasite uyarısı
                        if (maxKap > 0) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                toplam >= maxKap
                                    ? Icons.info_outline
                                    : Icons.check_circle_outline,
                                color: toplam >= maxKap
                                    ? Colors.orange
                                    : Colors.white24,
                                size: 14,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                toplam >= maxKap
                                    ? 'Maksimum kapasite doldu ($maxKap kişi)'
                                    : 'Bu oda en fazla $maxKap kişi alabilir',
                                style: TextStyle(
                                  color: toplam >= maxKap
                                      ? Colors.orange
                                      : Colors.white24,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 10),

                        // ── KİŞİ SAYISI ───────────────────
                        _kisiSatiri(
                            'Yetişkin (Erkek)',
                            Icons.man,
                            _erkek,
                            'erkek',
                            setModal,
                            toplam,
                            maxKap),
                        Divider(
                            height: 18,
                            color: Colors.white
                                .withValues(alpha: 0.08)),
                        _kisiSatiri(
                            'Yetişkin (Kadın)',
                            Icons.woman,
                            _kadin,
                            'kadin',
                            setModal,
                            toplam,
                            maxKap),
                        Divider(
                            height: 18,
                            color: Colors.white
                                .withValues(alpha: 0.08)),
                        _kisiSatiri(
                            'Çocuk',
                            Icons.child_care,
                            _cocuk,
                            'cocuk',
                            setModal,
                            toplam,
                            maxKap),

                        const SizedBox(height: 20),
                        _ayrac('Oda Seçin',
                            Icons.meeting_room_outlined),
                        const SizedBox(height: 2),

                        // Tarih seçilmemişse uyarı
                        if (_girisTarihi == null ||
                            _cikisTarihi == null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.orange
                                  .withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.orange
                                      .withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.orange,
                                    size: 16),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Oda seçmek için önce giriş ve çıkış tarihi seçin.',
                                    style: TextStyle(
                                        color: Colors.orange,
                                        fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          // ── ODA LİSTESİ (tarih bazlı müsaitlik) ──
                          const SizedBox(height: 8),
                          // Seçilen tarihlerle çakışan rezervasyonları çek
                          FutureBuilder<QuerySnapshot>(
                            // Tarihler değişince yeniden sorgula
                            key: ValueKey(
                                '${_girisTarihi}_$_cikisTarihi'),
                            future: _firestore
                                .collection('rezervasyonlar')
                                .where('odaId', isEqualTo: docId)
                                .get(),
                            builder: (ctx, rezSnap) {
                              if (rezSnap.connectionState ==
                                  ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Center(
                                    child:
                                        CircularProgressIndicator(
                                      color: AppColors.teal,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              }

                              // Seçilen tarihlerle çakışan oda numaraları
                              final Set<String> doluOdalar = {};
                              if (rezSnap.hasData) {
                                for (final rezDoc
                                    in rezSnap.data!.docs) {
                                  final r = rezDoc.data()
                                      as Map<String, dynamic>;
                                  final durum =
                                      r['durum'] ?? '';
                                  // Sadece aktif (onaylı veya bekleyen) rezervasyonlar
                                  if (durum != 'onaylandi' &&
                                      durum != 'beklemede') {
                                    continue;
                                  }
                                  final rezGiris =
                                      _tarihParse(r['girisTarihi']);
                                  final rezCikis =
                                      _tarihParse(r['cikisTarihi']);
                                  if (rezGiris == null ||
                                      rezCikis == null) {
                                    continue;
                                  }

                                  // Çakışma kontrolü:
                                  // mevcut rezervasyon başlamadan bizim çıkış olmuşsa → çakışmaz
                                  // bizim girişten önce mevcut rezervasyon bitmişse → çakışmaz
                                  final cakisiyor =
                                      rezGiris.isBefore(
                                              _cikisTarihi!) &&
                                          rezCikis.isAfter(
                                              _girisTarihi!);
                                  if (cakisiyor) {
                                    doluOdalar.add(
                                        '${r['odaNo']}');
                                  }
                                }
                              }

                              return Column(
                                children:
                                    List.generate(odaSayisi, (i) {
                                  final odaNo = '${i + 1}';
                                  final musait = !doluOdalar
                                      .contains(odaNo);
                                  return _odaSatiri(
                                    ctx: ctx,
                                    odaNo: odaNo,
                                    musait: musait,
                                    docId: docId,
                                    tip: tip,
                                    fiyat: fiyat,
                                  );
                                }),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final int yildiz = (widget.otel['yildiz'] ?? 0) as int;
    final String il = widget.otel['il'] ?? '';
    final String ilce = widget.otel['ilce'] ?? '';
    final String adres =
        [if (ilce.isNotEmpty) ilce, if (il.isNotEmpty) il]
            .join(' / ');

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
                    const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.otel['tesisAdi'],
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Text('Tesis Profili',
                              style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── TESİS BİLGİ KARTI ───────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    16, 14, 16, 6),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.white
                            .withValues(alpha: 0.07)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.teal
                              .withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.hotel,
                            color: AppColors.teal,
                            size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.otel['tesisAdi'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (yildiz > 0) ...[
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  ...List.generate(
                                    5,
                                    (i) => Icon(
                                      i < yildiz
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: i < yildiz
                                          ? Colors.amber
                                          : Colors.white24,
                                      size: 15,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '$yildiz Yıldızlı',
                                    style: const TextStyle(
                                        color: Colors.amber,
                                        fontSize: 11,
                                        fontWeight:
                                            FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                            if (adres.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Icon(
                                      Icons
                                          .location_on_outlined,
                                      color: Colors.white38,
                                      size: 13),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      adres,
                                      style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 12),
                                      overflow:
                                          TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── ODA TİPLERİ LİSTESİ ─────────────────────────
              Expanded(
                child: FutureBuilder<QuerySnapshot>(
                  future: _firestore
                      .collection('odalar')
                      .where('yoneticiUid',
                          isEqualTo: widget.otel['uid'])
                      .get(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.teal,
                              strokeWidth: 2));
                    }

                    final docs = snap.data!.docs;

                    if (docs.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bed_outlined,
                                color: Colors.white24,
                                size: 52),
                            SizedBox(height: 12),
                            Text(
                              'Bu tesise ait oda bulunamadı.',
                              style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(
                          16, 10, 16, 24),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              bottom: 10),
                          child: Row(
                            children: [
                              const Icon(Icons.bed_outlined,
                                  color: AppColors.teal,
                                  size: 16),
                              const SizedBox(width: 6),
                              const Text(
                                'Oda Tipleri',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight:
                                        FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.teal
                                      .withValues(alpha: 0.15),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${docs.length} tip',
                                  style: const TextStyle(
                                      color: AppColors.teal,
                                      fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...docs.map((doc) {
                          final data = doc.data()
                              as Map<String, dynamic>;
                          return _odaTipiKarti(doc.id, data);
                        }),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Yönetici panelindeki aynı kart tasarımı
  Widget _odaTipiKarti(String docId, Map<String, dynamic> data) {
    final String tip = data['odaTipiAdi'] ?? 'Oda';
    final int cift = data['ciftKisilikYatak'] ?? 0;
    final int tek = data['tekKisilikYatak'] ?? 0;
    final double fiyat = (data['fiyat'] ?? 0.0).toDouble();
    final int odaSayisi = data['odaSayisi'] ?? 0;

    // Müsait oda sayısını hesapla
    final durumlari =
        Map<String, dynamic>.from(data['odaDurumlari'] ?? {});
    int musaitSayisi = 0;
    for (int i = 1; i <= odaSayisi; i++) {
      if (durumlari['$i'] as bool? ?? true) musaitSayisi++;
    }

    return GestureDetector(
      onTap: () => _odaTipiDetayAc(docId, data),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst satır
            Row(
              children: [
                const Icon(Icons.bed,
                    color: AppColors.teal, size: 20),
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
                // Müsait / toplam
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: musaitSayisi > 0
                        ? AppColors.teal.withValues(alpha: 0.15)
                        : Colors.redAccent
                            .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    musaitSayisi > 0
                        ? '$musaitSayisi/$odaSayisi Müsait'
                        : 'Dolu',
                    style: TextStyle(
                      color: musaitSayisi > 0
                          ? AppColors.teal
                          : Colors.redAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right,
                    color: Colors.white24, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            // Chip'ler
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (cift > 0)
                  _bilgiCip(Icons.king_bed_outlined,
                      '$cift Çift Kişilik', Colors.blue),
                if (tek > 0)
                  _bilgiCip(Icons.single_bed_outlined,
                      '$tek Tek Kişilik', Colors.purple),
                _bilgiCip(
                    Icons.attach_money,
                    '₺${fiyat.toStringAsFixed(0)} / gece',
                    AppColors.teal),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Bottom sheet içindeki oda satırı (dolu/boş gösterir)
  Widget _odaSatiri({
    required BuildContext ctx,
    required String odaNo,
    required bool musait,
    required String docId,
    required String tip,
    required double fiyat,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: musait
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: musait
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          // Oda no kutusu
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: musait
                  ? AppColors.teal.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                odaNo,
                style: TextStyle(
                  color: musait ? AppColors.teal : Colors.white24,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$odaNo Nolu Oda',
              style: TextStyle(
                color: musait ? Colors.white : Colors.white38,
                fontSize: 14,
              ),
            ),
          ),
          // Durum badge
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: musait
                  ? Colors.green.withValues(alpha: 0.15)
                  : Colors.redAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: musait
                    ? Colors.green.withValues(alpha: 0.4)
                    : Colors.redAccent.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              musait ? 'Müsait' : 'Dolu',
              style: TextStyle(
                color:
                    musait ? Colors.green : Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Seç butonu (sadece müsait odada)
          if (musait) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                if (_erkek + _kadin + _cocuk == 0) {
                  _mesajGoster('En az 1 kişi seçmelisiniz.');
                  return;
                }
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReservationScreen(
                      odaId: docId,
                      odaNo: odaNo,
                      odaTip: tip,
                      yoneticiUid: widget.otel['uid'],
                      tesisAdi: widget.otel['tesisAdi'],
                      girisTarihi: _girisTarihi!,
                      cikisTarihi: _cikisTarihi!,
                      erkekSayisi: _erkek,
                      kadinSayisi: _kadin,
                      cocukSayisi: _cocuk,
                      gecelikFiyat: fiyat,
                      geceSayisi: _geceSayisi,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color:
                          AppColors.teal.withValues(alpha: 0.4)),
                ),
                child: const Text(
                  'Seç',
                  style: TextStyle(
                    color: AppColors.teal,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── YARDIMCI WİDGET'LAR ───────────────────────────────────

  Widget _ayrac(String baslik, IconData ikon) {
    return Row(
      children: [
        Icon(ikon, color: AppColors.teal, size: 15),
        const SizedBox(width: 6),
        Text(
          baslik,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        Expanded(
            child: Divider(
                color: Colors.white.withValues(alpha: 0.08))),
      ],
    );
  }

  Widget _bilgiCip(IconData ikon, String yazi, Color renk) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, color: renk, size: 14),
          const SizedBox(width: 4),
          Text(yazi,
              style: TextStyle(
                  color: renk,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _tarihButon(
      String label, DateTime? tarih, VoidCallback onTap) {
    final secildi = tarih != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
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
                    color: secildi
                        ? AppColors.teal
                        : Colors.white38,
                    size: 14),
                const SizedBox(width: 5),
                Text(
                  _tarihFormat(tarih),
                  style: TextStyle(
                    color: secildi
                        ? Colors.white
                        : Colors.white38,
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

  Widget _kisiSatiri(
    String label,
    IconData ikon,
    int sayi,
    String tip,
    StateSetter setModal,
    int toplam,
    int maxKap,
  ) {
    final artirAktif = maxKap == 0 || toplam < maxKap;
    return Row(
      children: [
        Icon(ikon, color: AppColors.teal, size: 20),
        const SizedBox(width: 10),
        Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 14))),
        _sayacButon(
          Icons.remove,
          sayi > 0
              ? () => _kisiDegistir(tip, false, setModal, maxKap)
              : null,
        ),
        SizedBox(
          width: 36,
          child: Text('$sayi',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
        ),
        _sayacButon(
          Icons.add,
          artirAktif
              ? () => _kisiDegistir(tip, true, setModal, maxKap)
              : null,
        ),
      ],
    );
  }

  Widget _sayacButon(IconData ikon, VoidCallback? onTap) {
    final aktif = onTap != null;
    final artir = ikon == Icons.add;
    return GestureDetector(
      onTap: onTap,
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
