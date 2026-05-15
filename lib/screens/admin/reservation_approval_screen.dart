import 'package:flutter/material.dart';
import '../../constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReservationApprovalScreen extends StatefulWidget {
  final String yoneticiUid;
  final String tesisAdi;

  const ReservationApprovalScreen({
    super.key,
    required this.yoneticiUid,
    required this.tesisAdi,
  });

  @override
  State<ReservationApprovalScreen> createState() =>
      _ReservationApprovalScreenState();
}

class _ReservationApprovalScreenState
    extends State<ReservationApprovalScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabCtrl;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _durumGuncelle(
      String docId, String yeniDurum, String misafirAdi) async {
    await _firestore.collection('rezervasyonlar').doc(docId).update({
      'durum': yeniDurum,
      'guncellemeTarihi': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    final renk = yeniDurum == 'onaylandi' ? AppColors.teal : Colors.redAccent;
    final mesaj = yeniDurum == 'onaylandi'
        ? '$misafirAdi rezervasyonu onaylandı.'
        : '$misafirAdi rezervasyonu reddedildi.';

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mesaj),
      backgroundColor: renk,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Rezervasyonlar',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabCtrl,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: AppColors.teal,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white38,
                  labelStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: const TextStyle(fontSize: 12),
                  tabs: const [
                    Tab(text: 'Bekleyen'),
                    Tab(text: 'Onaylı'),
                    Tab(text: 'Reddedilen'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _buildRezervasyonListesi('beklemede'),
              _buildRezervasyonListesi('onaylandi'),
              _buildRezervasyonListesi('reddedildi'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRezervasyonListesi(String durum) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('rezervasyonlar')
          .where('yoneticiUid', isEqualTo: widget.yoneticiUid)
          .where('durum', isEqualTo: durum)
          .orderBy('olusturmaTarihi', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.teal));
        }

        final liste = snap.data!.docs;

        if (liste.isEmpty) {
          IconData ikon;
          String mesaj;
          switch (durum) {
            case 'beklemede':
              ikon = Icons.pending_outlined;
              mesaj = 'Bekleyen rezervasyon yok.';
              break;
            case 'onaylandi':
              ikon = Icons.check_circle_outline;
              mesaj = 'Onaylı rezervasyon yok.';
              break;
            default:
              ikon = Icons.cancel_outlined;
              mesaj = 'Reddedilen rezervasyon yok.';
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(ikon, color: Colors.white24, size: 52),
                const SizedBox(height: 12),
                Text(mesaj,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 14)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          itemCount: liste.length,
          itemBuilder: (ctx, i) {
            final doc = liste[i];
            final data = doc.data() as Map<String, dynamic>;
            return _rezervasyonKarti(doc.id, data, durum);
          },
        );
      },
    );
  }

  Widget _rezervasyonKarti(
      String docId, Map<String, dynamic> data, String durum) {
    final misafirAdi = data['misafirAdi'] ?? 'Bilinmiyor';
    final misafirEmail = data['misafirEmail'] ?? '';
    final odaNo = data['odaNo'] ?? '-';
    final odaTip = data['odaTip'] ?? '';
    final giris = data['girisTarihi'] ?? '-';
    final cikis = data['cikisTarihi'] ?? '-';
    final erkek = data['erkekSayisi'] ?? 0;
    final kadin = data['kadinSayisi'] ?? 0;
    final cocuk = data['cocukSayisi'] ?? 0;
    final toplamTutar = data['toplamTutar'] ?? 0;
    final geceSayisi = data['geceSayisi'] ?? 0;

    Color durumRenk;
    switch (durum) {
      case 'onaylandi':
        durumRenk = Colors.green;
        break;
      case 'reddedildi':
        durumRenk = Colors.redAccent;
        break;
      default:
        durumRenk = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: durumRenk.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          // Üst bilgi
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: durumRenk.withValues(alpha: 0.15),
                  child: Text(
                    misafirAdi.isNotEmpty ? misafirAdi[0].toUpperCase() : 'M',
                    style: TextStyle(
                        color: durumRenk, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(misafirAdi,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                      Text(misafirEmail,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: durumRenk.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    durum == 'beklemede'
                        ? 'Beklemede'
                        : durum == 'onaylandi'
                            ? 'Onaylı'
                            : 'Reddedildi',
                    style: TextStyle(
                        color: durumRenk,
                        fontSize: 10,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          // Detay bilgiler
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _detayRow(Icons.bed_outlined, 'Oda',
                    'No: $odaNo${odaTip.isNotEmpty ? '  •  $odaTip' : ''}'),
                const SizedBox(height: 6),
                _detayRow(Icons.calendar_today_outlined, 'Tarih',
                    '$giris → $cikis${geceSayisi > 0 ? '  ($geceSayisi gece)' : ''}'),
                const SizedBox(height: 6),
                _detayRow(Icons.people_outline, 'Kişi Sayısı',
                    '${erkek > 0 ? '$erkek Erkek  ' : ''}${kadin > 0 ? '$kadin Kadın  ' : ''}${cocuk > 0 ? '$cocuk Çocuk' : ''}'),
                if (toplamTutar > 0) ...[
                  const SizedBox(height: 6),
                  _detayRow(Icons.attach_money, 'Toplam Tutar',
                      '₺${toplamTutar.toStringAsFixed(0)}'),
                ],
              ],
            ),
          ),
          // Butonlar (sadece beklemedeyse)
          if (durum == 'beklemede')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          _durumGuncelle(docId, 'reddedildi', misafirAdi),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('Reddet',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          _durumGuncelle(docId, 'onaylandi', misafirAdi),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('Onayla',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _detayRow(IconData ikon, String baslik, String deger) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(ikon, color: Colors.white38, size: 14),
        const SizedBox(width: 8),
        Text('$baslik: ',
            style: const TextStyle(color: Colors.white38, fontSize: 11)),
        Expanded(
          child: Text(deger,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ),
      ],
    );
  }
}
