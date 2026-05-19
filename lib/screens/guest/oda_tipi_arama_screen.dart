import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants.dart';
import 'reservation_screen.dart';

class OdaTipiAramaScreen extends StatefulWidget {
  // 0 = filtre yok, 1+ = en az bu kadar yatak
  final int minCift;
  final int minTek;
  final DateTime girisTarihi;
  final DateTime cikisTarihi;
  final int erkekSayisi;
  final int kadinSayisi;
  final int cocukSayisi;

  const OdaTipiAramaScreen({
    super.key,
    required this.minCift,
    required this.minTek,
    required this.girisTarihi,
    required this.cikisTarihi,
    required this.erkekSayisi,
    required this.kadinSayisi,
    required this.cocukSayisi,
  });

  @override
  State<OdaTipiAramaScreen> createState() =>
      _OdaTipiAramaScreenState();
}

class _OdaSonuc {
  final String odaId;
  final Map<String, dynamic> odaData;
  final List<String> musaitOdaNoLari;
  final int yildiz;

  const _OdaSonuc({
    required this.odaId,
    required this.odaData,
    required this.musaitOdaNoLari,
    this.yildiz = 0,
  });
}

class _OdaTipiAramaScreenState extends State<OdaTipiAramaScreen> {
  final _firestore = FirebaseFirestore.instance;
  late Future<List<_OdaSonuc>> _aramaFuture;

  @override
  void initState() {
    super.initState();
    _aramaFuture = _odaAra();
  }

  int get _geceSayisi =>
      widget.cikisTarihi.difference(widget.girisTarihi).inDays;

  String _tarihFormat(DateTime t) =>
      '${t.day.toString().padLeft(2, '0')}.'
      '${t.month.toString().padLeft(2, '0')}.'
      '${t.year}';

  DateTime? _tarihParse(dynamic s) {
    if (s == null || s is! String || s.isEmpty) return null;
    final p = s.split('.');
    if (p.length != 3) return null;
    try {
      return DateTime(
          int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
    } catch (_) {
      return null;
    }
  }

  // 0 seçiliyse filtre yok; değer > 0 ise odanın yatak sayısı >= minCift/minTek olmalı
  bool _ciftEslesir(int cift) =>
      widget.minCift == 0 || cift >= widget.minCift;

  bool _tekEslesir(int tek) =>
      widget.minTek == 0 || tek >= widget.minTek;

  Future<List<_OdaSonuc>> _odaAra() async {
    final odalarSnap = await _firestore.collection('odalar').get();
    final sonuclar = <_OdaSonuc>[];

    // Tüm yönetici uid'lerini topla ve yıldız bilgisini tek seferde çek
    final yoneticiUidler = odalarSnap.docs
        .map((d) => (d.data()['yoneticiUid'] ?? '') as String)
        .where((u) => u.isNotEmpty)
        .toSet();

    final Map<String, int> yildizMap = {};
    for (final uid in yoneticiUidler) {
      final userDoc =
          await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        yildizMap[uid] =
            ((userDoc.data()?['yildiz'] ?? 0) as num).toInt();
      }
    }

    for (final doc in odalarSnap.docs) {
      final data = doc.data();
      final int cift = (data['ciftKisilikYatak'] ?? 0) as int;
      final int tek = (data['tekKisilikYatak'] ?? 0) as int;
      final int odaSayisi = (data['odaSayisi'] ?? 0) as int;

      if (!_ciftEslesir(cift) || !_tekEslesir(tek)) continue;
      if (odaSayisi == 0) continue;

      final rezSnap = await _firestore
          .collection('rezervasyonlar')
          .where('odaId', isEqualTo: doc.id)
          .get();

      final doluOdalar = <String>{};
      for (final rez in rezSnap.docs) {
        final rd = rez.data();
        final durum = rd['durum'] ?? '';
        if (durum != 'onaylandi' && durum != 'beklemede') continue;
        final rGiris = _tarihParse(rd['girisTarihi']);
        final rCikis = _tarihParse(rd['cikisTarihi']);
        if (rGiris == null || rCikis == null) continue;
        if (rGiris.isBefore(widget.cikisTarihi) &&
            rCikis.isAfter(widget.girisTarihi)) {
          doluOdalar.add('${rd['odaNo']}');
        }
      }

      final musait = <String>[];
      for (int i = 1; i <= odaSayisi; i++) {
        if (!doluOdalar.contains('$i')) musait.add('$i');
      }

      if (musait.isNotEmpty) {
        final uid = (data['yoneticiUid'] ?? '') as String;
        sonuclar.add(_OdaSonuc(
          odaId: doc.id,
          odaData: data,
          musaitOdaNoLari: musait,
          yildiz: yildizMap[uid] ?? 0,
        ));
      }
    }

    sonuclar.sort((a, b) {
      final fa = (a.odaData['fiyat'] ?? 0.0) as num;
      final fb = (b.odaData['fiyat'] ?? 0.0) as num;
      return fa.compareTo(fb);
    });

    return sonuclar;
  }

  // Karta tıklanınca oda numaralarını gösteren bottom sheet
  void _odaDetayAc(BuildContext context, _OdaSonuc sonuc) {
    final data = sonuc.odaData;
    final tip = data['odaTipiAdi'] ?? 'Oda';
    final tesisAdi = data['tesisAdi'] ?? '';
    final yoneticiUid = data['yoneticiUid'] ?? '';
    final int cift = (data['ciftKisilikYatak'] ?? 0) as int;
    final int tek = (data['tekKisilikYatak'] ?? 0) as int;
    final double fiyat = (data['fiyat'] ?? 0.0).toDouble();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (ctx, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Tutamaç
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              // Başlık
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 10, 16, 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.teal
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.bed,
                          color: AppColors.teal, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(tip,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          Text(tesisAdi,
                              style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color:
                            AppColors.teal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.teal
                                .withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '₺${fiyat.toStringAsFixed(0)}/gece',
                        style: const TextStyle(
                            color: AppColors.teal,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              // Chip'ler
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Wrap(
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
                      Icons.check_circle_outline,
                      '${sonuc.musaitOdaNoLari.length} Müsait',
                      Colors.green,
                    ),
                  ],
                ),
              ),
              Divider(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.08)),
              // Oda listesi
              Expanded(
                child: ListView.separated(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(
                      20, 14, 20, 24),
                  itemCount: sonuc.musaitOdaNoLari.length,
                  separatorBuilder: (_, i) => Divider(
                      height: 1,
                      color:
                          Colors.white.withValues(alpha: 0.06)),
                  itemBuilder: (ctx, i) {
                    final odaNo = sonuc.musaitOdaNoLari[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.teal
                                  .withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(odaNo,
                                  style: const TextStyle(
                                      color: AppColors.teal,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text('$odaNo Nolu Oda',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14)),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(ctx);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ReservationScreen(
                                    odaId: sonuc.odaId,
                                    odaNo: odaNo,
                                    odaTip: tip,
                                    yoneticiUid: yoneticiUid,
                                    tesisAdi: tesisAdi,
                                    girisTarihi:
                                        widget.girisTarihi,
                                    cikisTarihi:
                                        widget.cikisTarihi,
                                    erkekSayisi:
                                        widget.erkekSayisi,
                                    kadinSayisi:
                                        widget.kadinSayisi,
                                    cocukSayisi:
                                        widget.cocukSayisi,
                                    gecelikFiyat: fiyat,
                                    geceSayisi: _geceSayisi,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.teal
                                    .withValues(alpha: 0.15),
                                borderRadius:
                                    BorderRadius.circular(20),
                                border: Border.all(
                                    color: AppColors.teal
                                        .withValues(alpha: 0.4)),
                              ),
                              child: const Text('Seç',
                                  style: TextStyle(
                                      color: AppColors.teal,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                            ),
                          ),
                        ],
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgTop,
      body: Container(
        decoration: const BoxDecoration(gradient: appGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildAramaBilgisi(),
              Expanded(
                child: FutureBuilder<List<_OdaSonuc>>(
                  future: _aramaFuture,
                  builder: (context, snap) {
                    if (snap.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                                color: AppColors.teal,
                                strokeWidth: 2),
                            SizedBox(height: 14),
                            Text('Müsait odalar aranıyor...',
                                style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 13)),
                          ],
                        ),
                      );
                    }
                    if (snap.hasError) {
                      return Center(
                        child: Text('Hata: ${snap.error}',
                            style: const TextStyle(
                                color: Colors.white38)),
                      );
                    }
                    final sonuclar = snap.data ?? [];
                    if (sonuclar.isEmpty) {
                      return _buildBosEkran();
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                          16, 6, 16, 24),
                      itemCount: sonuclar.length,
                      itemBuilder: (context, i) =>
                          _buildKucukKart(
                              context, sonuclar[i]),
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

  // ── ÜST BAŞLIK ──────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 20, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white70, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Müsait Odalar',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text(_filterOzeti(),
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _filterOzeti() {
    final p = <String>[];
    if (widget.minCift > 0) p.add('En az ${widget.minCift} çift kişilik');
    if (widget.minTek > 0)  p.add('En az ${widget.minTek} tek kişilik');
    return p.isEmpty ? 'Tüm yatak tipleri' : p.join('  ·  ');
  }

  // ── ÖZET ÇUBUK ──────────────────────────────────────────────
  Widget _buildAramaBilgisi() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_outlined,
              color: AppColors.teal, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${_tarihFormat(widget.girisTarihi)} → ${_tarihFormat(widget.cikisTarihi)}',
              style: const TextStyle(
                  color: Colors.white70, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.nights_stay_outlined,
              color: AppColors.teal, size: 14),
          const SizedBox(width: 4),
          Text('$_geceSayisi gece',
              style: const TextStyle(
                  color: AppColors.teal,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          const Icon(Icons.people_outline,
              color: Colors.white38, size: 14),
          const SizedBox(width: 4),
          Text(
            '${widget.erkekSayisi + widget.kadinSayisi} kişi'
            '${widget.cocukSayisi > 0 ? ' · ${widget.cocukSayisi} çocuk' : ''}',
            style: const TextStyle(
                color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── KÜÇÜK KART ──────────────────────────────────────────────
  Widget _buildKucukKart(
      BuildContext context, _OdaSonuc sonuc) {
    final data = sonuc.odaData;
    final tip = data['odaTipiAdi'] ?? 'Oda';
    final tesisAdi = data['tesisAdi'] ?? '';
    final int cift = (data['ciftKisilikYatak'] ?? 0) as int;
    final int tek = (data['tekKisilikYatak'] ?? 0) as int;
    final double fiyat = (data['fiyat'] ?? 0.0).toDouble();
    final musaitSayisi = sonuc.musaitOdaNoLari.length;
    final yildiz = sonuc.yildiz;

    return GestureDetector(
      onTap: () => _odaDetayAc(context, sonuc),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(
          children: [
            // Sol: otel ikonu
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.hotel,
                  color: AppColors.teal, size: 18),
            ),
            const SizedBox(width: 12),
            // Orta: tesis adı üstte, oda tipi altta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tesis adı — büyük, kalın
                  Text(
                    tesisAdi,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Yıldızlar
                  if (yildiz > 0) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < yildiz
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: i < yildiz
                              ? Colors.amber
                              : Colors.white24,
                          size: 12,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 3),
                  // Oda tipi — küçük, soluk
                  Text(
                    tip,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Chip'ler
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (cift > 0)
                        _bilgiCip(Icons.king_bed_outlined,
                            '$cift Çift', Colors.blue),
                      if (tek > 0)
                        _bilgiCip(Icons.single_bed_outlined,
                            '$tek Tek', Colors.purple),
                      _bilgiCip(
                          Icons.check_circle_outline,
                          '$musaitSayisi Müsait',
                          Colors.green),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Sağ: fiyat + ok
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₺${fiyat.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: AppColors.teal,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                const Text('/gece',
                    style: TextStyle(
                        color: Colors.white38, fontSize: 10)),
                const SizedBox(height: 6),
                const Icon(Icons.chevron_right,
                    color: Colors.white24, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── BOŞ EKRAN ───────────────────────────────────────────────
  Widget _buildBosEkran() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off,
                  color: Colors.white24, size: 48),
            ),
            const SizedBox(height: 18),
            const Text('Müsait Oda Bulunamadı',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Seçtiğiniz tarihler ve yatak kriterleri için\nuygun oda bulunmuyor.\nFarklı tarih veya yatak seçeneği deneyin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white38,
                  fontSize: 13,
                  height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bilgiCip(IconData ikon, String metin, Color renk) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: renk.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, color: renk, size: 11),
          const SizedBox(width: 4),
          Text(metin,
              style: TextStyle(
                  color: renk,
                  fontSize: 10,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
