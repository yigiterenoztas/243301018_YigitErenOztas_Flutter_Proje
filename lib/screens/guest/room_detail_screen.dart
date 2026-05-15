import 'package:flutter/material.dart';
import '../../constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'reservation_screen.dart';

class RoomDetailScreen extends StatefulWidget {
  final String yoneticiUid;
  final String tesisAdi;
  final DateTime girisTarihi;
  final DateTime cikisTarihi;
  final int erkekSayisi;
  final int kadinSayisi;
  final int cocukSayisi;

  const RoomDetailScreen({
    super.key,
    required this.yoneticiUid,
    required this.tesisAdi,
    required this.girisTarihi,
    required this.cikisTarihi,
    required this.erkekSayisi,
    required this.kadinSayisi,
    required this.cocukSayisi,
  });

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {

  final _firestore = FirebaseFirestore.instance;

  int get _geceSayisi =>
      widget.cikisTarihi.difference(widget.girisTarihi).inDays;

  int get _toplamKisi =>
      widget.erkekSayisi + widget.kadinSayisi + widget.cocukSayisi;

  String _tarihFormat(DateTime tarih) =>
      '${tarih.day.toString().padLeft(2, '0')}.${tarih.month.toString().padLeft(2, '0')}.${tarih.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          _buildHeader(),
          _buildAramaBilgi(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('odalar')
                  .where('yoneticiUid', isEqualTo: widget.yoneticiUid)
                  .where('musait', isEqualTo: true)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: AppColors.teal));
                }

                // Kapasite filtresi
                final tumOdalar = snap.data!.docs;
                final uygunOdalar = tumOdalar.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final kapasite = data['kapasite'] ?? 0;
                  return kapasite >= _toplamKisi;
                }).toList();

                if (uygunOdalar.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bed_outlined,
                            color: Colors.black26, size: 56),
                        const SizedBox(height: 12),
                        const Text(
                          'Uygun oda bulunamadı.',
                          style:
                              TextStyle(color: Colors.black38, fontSize: 15),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Farklı tarih veya kişi sayısı deneyin.',
                          style: TextStyle(
                              color: Colors.black26, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: uygunOdalar.length,
                  itemBuilder: (ctx, i) {
                    final doc = uygunOdalar[i];
                    final data = doc.data() as Map<String, dynamic>;
                    return _odaKarti(doc.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.tesisAdi,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                const Text('Müsait Odalar',
                    style:
                        TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAramaBilgi() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          _bilgiChip(Icons.calendar_today,
              '${_tarihFormat(widget.girisTarihi)} - ${_tarihFormat(widget.cikisTarihi)}'),
          const SizedBox(width: 12),
          _bilgiChip(Icons.nights_stay_outlined, '$_geceSayisi gece'),
          const SizedBox(width: 12),
          _bilgiChip(Icons.people_outline, '$_toplamKisi kişi'),
        ],
      ),
    );
  }

  Widget _bilgiChip(IconData ikon, String deger) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(ikon, color: AppColors.teal, size: 13),
        const SizedBox(width: 4),
        Text(deger,
            style: const TextStyle(
                color: Colors.black54, fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _odaKarti(String odaId, Map<String, dynamic> data) {
    final odaNo = data['odaNo'] ?? '-';
    final tip = data['tip'] ?? 'Standart';
    final kapasite = data['kapasite'] ?? 2;
    final fiyat = (data['fiyat'] ?? 0).toDouble();
    final aciklama = data['aciklama'] ?? '';
    final toplamFiyat = fiyat * _geceSayisi;

    final tipRenk = _tipRenk(tip);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          // Oda tipi banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  tipRenk.withValues(alpha: 0.15),
                  tipRenk.withValues(alpha: 0.05)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: tipRenk.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(tip,
                      style: TextStyle(
                          color: tipRenk,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
                const Spacer(),
                Icon(Icons.bed, color: tipRenk, size: 20),
                const SizedBox(width: 6),
                Text('Oda $odaNo',
                    style: TextStyle(
                        color: tipRenk,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ],
            ),
          ),
          // Detaylar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    _ozellik(Icons.people_outline,
                        '$kapasite kişiye kadar'),
                    const SizedBox(width: 16),
                    _ozellik(Icons.check_circle_outline, 'Müsait'),
                  ],
                ),
                if (aciklama.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(aciklama,
                      style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '₺${fiyat.toStringAsFixed(0)} / gece',
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 12),
                        ),
                        Text(
                          '₺${toplamFiyat.toStringAsFixed(0)} toplam',
                          style: TextStyle(
                              color: AppColors.bgTop,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () => _rezervasyonYap(odaId, data, fiyat),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.bgTop,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Rezerve Et',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ozellik(IconData ikon, String deger) {
    return Row(
      children: [
        Icon(ikon, color: AppColors.teal, size: 16),
        const SizedBox(width: 5),
        Text(deger,
            style: const TextStyle(color: Colors.black54, fontSize: 12)),
      ],
    );
  }

  Color _tipRenk(String tip) {
    switch (tip) {
      case 'Delüks':
        return Colors.purple;
      case 'Süit':
        return Colors.orange;
      case 'Aile':
        return Colors.blue;
      case 'Apart':
        return Colors.green;
      default:
        return const Color(0xFF2DD4C0);
    }
  }

  void _rezervasyonYap(
      String odaId, Map<String, dynamic> odaData, double gecelikFiyat) {
    final kullanici = FirebaseAuth.instance.currentUser;
    if (kullanici == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReservationScreen(
          odaId: odaId,
          odaNo: odaData['odaNo'] ?? '-',
          odaTip: odaData['tip'] ?? 'Standart',
          yoneticiUid: widget.yoneticiUid,
          tesisAdi: widget.tesisAdi,
          girisTarihi: widget.girisTarihi,
          cikisTarihi: widget.cikisTarihi,
          erkekSayisi: widget.erkekSayisi,
          kadinSayisi: widget.kadinSayisi,
          cocukSayisi: widget.cocukSayisi,
          gecelikFiyat: gecelikFiyat,
          geceSayisi: _geceSayisi,
        ),
      ),
    );
  }
}
