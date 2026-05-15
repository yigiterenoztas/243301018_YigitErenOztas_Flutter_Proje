import 'package:flutter/material.dart';
import '../../constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'room_detail_screen.dart';

// Seçilen oda tipine sahip tüm tesisleri listeler
class OdaTipiAramaScreen extends StatelessWidget {
  final String odaTipiAdi;
  final DateTime girisTarihi;
  final DateTime cikisTarihi;
  final int erkekSayisi;
  final int kadinSayisi;
  final int cocukSayisi;

  const OdaTipiAramaScreen({
    super.key,
    required this.odaTipiAdi,
    required this.girisTarihi,
    required this.cikisTarihi,
    required this.erkekSayisi,
    required this.kadinSayisi,
    required this.cocukSayisi,
  });

  int get _geceSayisi => cikisTarihi.difference(girisTarihi).inDays;

  String _tarihFormat(DateTime tarih) =>
      '${tarih.day.toString().padLeft(2, '0')}.'
      '${tarih.month.toString().padLeft(2, '0')}.'
      '${tarih.year}';

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
                child: FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('odalar')
                      .where('odaTipiAdi', isEqualTo: odaTipiAdi)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.teal, strokeWidth: 2),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Hata: ${snapshot.error}',
                            style:
                                const TextStyle(color: Colors.white38)),
                      );
                    }
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.search_off,
                                color: Colors.white24, size: 64),
                            const SizedBox(height: 16),
                            Text(
                              '"$odaTipiAdi" tipinde oda bulunamadı.',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 15),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Başka bir oda tipi deneyin.',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data =
                            docs[index].data() as Map<String, dynamic>;
                        return _buildTesisKart(context, data);
                      },
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

  // ── ÜST BAŞLIK ──────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white70, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  odaTipiAdi,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  'Uygun tesisler',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── ARAMA ÖZETİ ÇUBUĞU ──────────────────────────────────────────
  Widget _buildAramaBilgisi() {
    final toplamKisi = erkekSayisi + kadinSayisi;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Satır 1: tarih aralığı + gece sayısı
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  color: AppColors.teal, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${_tarihFormat(girisTarihi)} → ${_tarihFormat(cikisTarihi)}',
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.nights_stay_outlined,
                  color: AppColors.teal, size: 14),
              const SizedBox(width: 4),
              Text(
                '$_geceSayisi gece',
                style: const TextStyle(
                    color: AppColors.teal,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Satır 2: kişi sayısı
          Row(
            children: [
              const Icon(Icons.people_outline,
                  color: AppColors.teal, size: 14),
              const SizedBox(width: 6),
              Text(
                '$toplamKisi yetişkin'
                '${cocukSayisi > 0 ? ' · $cocukSayisi çocuk' : ''}',
                style:
                    const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── TESİS KARTI ─────────────────────────────────────────────────
  Widget _buildTesisKart(BuildContext context, Map<String, dynamic> data) {
    final tesisAdi = data['tesisAdi'] ?? 'İsimsiz Tesis';
    final yoneticiUid = data['yoneticiUid'] ?? '';
    final cift = (data['ciftKisilikYatak'] ?? 0) as int;
    final tek = (data['tekKisilikYatak'] ?? 0) as int;
    final fiyat = (data['fiyat'] ?? 0).toDouble();
    final odaSayisi = (data['odaSayisi'] ?? 0) as int;
    final odaDurumlari =
        Map<String, dynamic>.from(data['odaDurumlari'] ?? {});
    final musaitSayisi =
        odaDurumlari.values.where((v) => v == true).length;

    return GestureDetector(
      onTap: () => _tesiseGit(context, yoneticiUid, tesisAdi),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst: tesis adı + fiyat
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.hotel,
                        color: AppColors.teal, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tesisAdi,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          odaTipiAdi,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₺${fiyat.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppColors.teal,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        '/ gece',
                        style:
                            TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bilgi çipleri
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (cift > 0)
                    _bilgiCip(Icons.king_bed_outlined,
                        '$cift Çift Kişilik', Colors.blue.shade300),
                  if (tek > 0)
                    _bilgiCip(Icons.single_bed_outlined,
                        '$tek Tek Kişilik', Colors.purple.shade300),
                  _bilgiCip(
                      Icons.door_front_door_outlined,
                      '$odaSayisi Oda',
                      Colors.orange.shade300),
                  _bilgiCip(
                    musaitSayisi > 0
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                    musaitSayisi > 0
                        ? '$musaitSayisi Müsait'
                        : 'Dolu',
                    musaitSayisi > 0
                        ? Colors.green.shade400
                        : Colors.red.shade400,
                  ),
                ],
              ),
            ),

            // Alt buton
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: musaitSayisi > 0
                      ? () => _tesiseGit(context, yoneticiUid, tesisAdi)
                      : null,
                  icon: Icon(
                    musaitSayisi > 0
                        ? Icons.arrow_forward_ios
                        : Icons.block,
                    size: 15,
                  ),
                  label: Text(
                    musaitSayisi > 0 ? 'Odaları Gör' : 'Müsait Oda Yok',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: musaitSayisi > 0
                        ? AppColors.teal
                        : Colors.white.withValues(alpha: 0.06),
                    foregroundColor: musaitSayisi > 0
                        ? Colors.white
                        : Colors.white38,
                    disabledBackgroundColor:
                        Colors.white.withValues(alpha: 0.06),
                    disabledForegroundColor: Colors.white38,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _tesiseGit(BuildContext context, String yoneticiUid, String tesisAdi) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoomDetailScreen(
          yoneticiUid: yoneticiUid,
          tesisAdi: tesisAdi,
          girisTarihi: girisTarihi,
          cikisTarihi: cikisTarihi,
          erkekSayisi: erkekSayisi,
          kadinSayisi: kadinSayisi,
          cocukSayisi: cocukSayisi,
        ),
      ),
    );
  }

  Widget _bilgiCip(IconData ikon, String metin, Color renk) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: renk.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, color: renk, size: 13),
          const SizedBox(width: 5),
          Text(metin,
              style: TextStyle(
                  color: renk,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
