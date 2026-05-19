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
  late final TabController _tabCtrl;
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

  // Onaylama → rezervasyon durumu + oda dolu işareti
  Future<void> _onayla(String docId, Map<String, dynamic> data) async {
    final misafirAdi = data['misafirAdi'] ?? 'Misafir';
    final String odaId = data['odaId'] ?? '';
    final String odaNo = data['odaNo'] ?? '';

    // 1) Rezervasyon durumunu güncelle
    await _firestore.collection('rezervasyonlar').doc(docId).update({
      'durum': 'onaylandi',
      'guncellemeTarihi': FieldValue.serverTimestamp(),
    });

    // 2) İlgili odayı "dolu" olarak işaretle (odaDurumlari[odaNo] = false)
    if (odaId.isNotEmpty && odaNo.isNotEmpty) {
      final odaDoc =
          await _firestore.collection('odalar').doc(odaId).get();
      if (odaDoc.exists) {
        final durumlari = Map<String, dynamic>.from(
            odaDoc.data()?['odaDurumlari'] ?? {});
        durumlari[odaNo] = false; // false = dolu
        await _firestore
            .collection('odalar')
            .doc(odaId)
            .update({'odaDurumlari': durumlari});
      }
    }

    // Log: yönetici rezervasyonu onayladı
    await _firestore.collection('logs').add({
      'action': 'rezervasyon_onaylandi',
      'rezervasyonId': docId,
      'yoneticiUid': widget.yoneticiUid,
      'tesisAdi': widget.tesisAdi,
      'misafirAdi': misafirAdi,
      'odaId': odaId,
      'odaNo': odaNo,
      'girisTarihi': data['girisTarihi'],
      'cikisTarihi': data['cikisTarihi'],
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$misafirAdi rezervasyonu onaylandı. Oda dolu işaretlendi.'),
      backgroundColor: AppColors.teal,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // Reddetme → sadece rezervasyon durumu
  Future<void> _reddet(String docId, String misafirAdi) async {
    await _firestore.collection('rezervasyonlar').doc(docId).update({
      'durum': 'reddedildi',
      'guncellemeTarihi': FieldValue.serverTimestamp(),
    });

    // Log: yönetici rezervasyonu reddetti
    await _firestore.collection('logs').add({
      'action': 'rezervasyon_reddedildi',
      'rezervasyonId': docId,
      'yoneticiUid': widget.yoneticiUid,
      'tesisAdi': widget.tesisAdi,
      'misafirAdi': misafirAdi,
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$misafirAdi rezervasyonu reddedildi.'),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── BAŞLIK ──────────────────────────────────────────
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 14),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Rezervasyonlar',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),

        // ── BAĞIMSIZ SEKME BUTONLARI ─────────────────────────
        AnimatedBuilder(
          animation: _tabCtrl,
          builder: (context, _) {
            final aktif = _tabCtrl.index;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _sekmeButon(
                    index: 0,
                    aktif: aktif,
                    ikon: Icons.hourglass_top_rounded,
                    label: 'Bekleyenler',
                    renk: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  _sekmeButon(
                    index: 1,
                    aktif: aktif,
                    ikon: Icons.check_circle_outline,
                    label: 'Onaylananlar',
                    renk: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _sekmeButon(
                    index: 2,
                    aktif: aktif,
                    ikon: Icons.cancel_outlined,
                    label: 'Reddedilenler',
                    renk: Colors.redAccent,
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        // ── TAB İÇERİKLERİ ──────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _RezervasyonListesi(
                yoneticiUid: widget.yoneticiUid,
                firestore: _firestore,
                durumlar: const ['beklemede'],
                bosIkon: Icons.hourglass_empty,
                bosMesaj: 'Bekleyen rezervasyon talebi yok.',
                onOnayla: _onayla,
                onReddet: _reddet,
              ),
              _RezervasyonListesi(
                yoneticiUid: widget.yoneticiUid,
                firestore: _firestore,
                durumlar: const ['onaylandi'],
                bosIkon: Icons.event_available_outlined,
                bosMesaj: 'Onaylanmış rezervasyon yok.',
              ),
              _RezervasyonListesi(
                yoneticiUid: widget.yoneticiUid,
                firestore: _firestore,
                durumlar: const ['reddedildi'],
                bosIkon: Icons.event_busy_outlined,
                bosMesaj: 'Reddedilen rezervasyon yok.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sekmeButon({
    required int index,
    required int aktif,
    required IconData ikon,
    required String label,
    required Color renk,
  }) {
    final secili = aktif == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _tabCtrl.animateTo(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: secili
                ? renk.withValues(alpha: 0.18)
                : AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: secili
                  ? renk.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.07),
              width: secili ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(ikon,
                  color: secili ? renk : Colors.white24,
                  size: 18),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: secili ? renk : Colors.white38,
                  fontSize: 11,
                  fontWeight: secili
                      ? FontWeight.w700
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── REZERVASYON LİSTESİ ────────────────────────────────────────
class _RezervasyonListesi extends StatelessWidget {
  final String yoneticiUid;
  final FirebaseFirestore firestore;
  final List<String> durumlar;
  final String bosMesaj;
  final IconData bosIkon;
  final Future<void> Function(String, Map<String, dynamic>)? onOnayla;
  final Future<void> Function(String, String)? onReddet;

  const _RezervasyonListesi({
    required this.yoneticiUid,
    required this.firestore,
    required this.durumlar,
    required this.bosMesaj,
    required this.bosIkon,
    this.onOnayla,
    this.onReddet,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('rezervasyonlar')
          .where('yoneticiUid', isEqualTo: yoneticiUid)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(
                  color: AppColors.teal, strokeWidth: 2));
        }

        // Client tarafında filtrele + sırala (composite index gerekmez)
        final docs = snap.data!.docs.where((d) {
          final durum =
              (d.data() as Map<String, dynamic>)['durum']
                  as String? ??
                  '';
          return durumlar.contains(durum);
        }).toList()
          ..sort((a, b) {
            final aT = (a.data()
                as Map<String, dynamic>)['olusturmaTarihi'];
            final bT = (b.data()
                as Map<String, dynamic>)['olusturmaTarihi'];
            if (aT == null || bT == null) return 0;
            return (bT as dynamic).compareTo(aT as dynamic);
          });

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white
                            .withValues(alpha: 0.07)),
                  ),
                  child: Icon(bosIkon,
                      color: Colors.white24, size: 40),
                ),
                const SizedBox(height: 16),
                Text(bosMesaj,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 14)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;
            return _RezervasyonKarti(
              docId: doc.id,
              data: data,
              onOnayla: onOnayla,
              onReddet: onReddet,
            );
          },
        );
      },
    );
  }
}

// ── REZERVASYON KARTI ──────────────────────────────────────────
class _RezervasyonKarti extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final Future<void> Function(String, Map<String, dynamic>)? onOnayla;
  final Future<void> Function(String, String)? onReddet;

  const _RezervasyonKarti({
    required this.docId,
    required this.data,
    this.onOnayla,
    this.onReddet,
  });

  @override
  Widget build(BuildContext context) {
    final String misafirAdi = data['misafirAdi'] ?? 'Bilinmiyor';
    final String misafirEmail = data['misafirEmail'] ?? '';
    final String odaNo = data['odaNo'] ?? '-';
    final String odaTip = data['odaTip'] ?? '';
    final String giris = data['girisTarihi'] ?? '-';
    final String cikis = data['cikisTarihi'] ?? '-';
    final int erkek = data['erkekSayisi'] ?? 0;
    final int kadin = data['kadinSayisi'] ?? 0;
    final int cocuk = data['cocukSayisi'] ?? 0;
    final double toplam =
        (data['toplamTutar'] ?? 0).toDouble();
    final int gece = data['geceSayisi'] ?? 0;
    final String durum = data['durum'] ?? 'beklemede';
    final int toplamKisi = erkek + kadin + cocuk;

    final Color durumRenk;
    final String durumEtiket;
    final IconData durumIkon;
    switch (durum) {
      case 'onaylandi':
        durumRenk = Colors.green;
        durumEtiket = 'Onaylandı';
        durumIkon = Icons.check_circle_outline;
        break;
      case 'reddedildi':
        durumRenk = Colors.redAccent;
        durumEtiket = 'Reddedildi';
        durumIkon = Icons.cancel_outlined;
        break;
      default:
        durumRenk = Colors.orange;
        durumEtiket = 'Beklemede';
        durumIkon = Icons.hourglass_top_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: durumRenk.withValues(alpha: 0.25),
            width: 1.2),
      ),
      child: Column(
        children: [
          // ── ÜST BANT ──────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: durumRenk.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                // Misafir avatarı
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      durumRenk.withValues(alpha: 0.2),
                  child: Text(
                    misafirAdi.isNotEmpty
                        ? misafirAdi[0].toUpperCase()
                        : 'M',
                    style: TextStyle(
                        color: durumRenk,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(misafirAdi,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                      Text(misafirEmail,
                          style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                // Durum badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color:
                        durumRenk.withValues(alpha: 0.18),
                    borderRadius:
                        BorderRadius.circular(20),
                    border: Border.all(
                        color: durumRenk
                            .withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(durumIkon,
                          color: durumRenk, size: 11),
                      const SizedBox(width: 4),
                      Text(durumEtiket,
                          style: TextStyle(
                              color: durumRenk,
                              fontSize: 11,
                              fontWeight:
                                  FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── DETAY BİLGİLER ────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _detayRow(
                    Icons.bed_outlined,
                    '$odaTip  •  $odaNo Nolu Oda',
                  ),
                  const SizedBox(height: 7),
                  _detayRow(
                    Icons.calendar_today_outlined,
                    '$giris → $cikis'
                    '${gece > 0 ? '  ($gece gece)' : ''}',
                  ),
                  const SizedBox(height: 7),
                  _detayRow(
                    Icons.people_outline,
                    _kisiMetni(
                        erkek, kadin, cocuk, toplamKisi),
                  ),
                  if (toplam > 0) ...[
                    const SizedBox(height: 7),
                    _detayRow(
                      Icons.payments_outlined,
                      '₺${toplam.toStringAsFixed(0)} toplam',
                      degerRenk: AppColors.teal,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── ONAYLA / REDDET BUTONLARI ─────────────────
          if (durum == 'beklemede' &&
              onOnayla != null &&
              onReddet != null)
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          onReddet!(docId, misafirAdi),
                      icon: const Icon(
                          Icons.close_rounded,
                          size: 16),
                      label: const Text('Reddet',
                          style: TextStyle(
                              fontWeight:
                                  FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: BorderSide(
                            color: Colors.redAccent
                                .withValues(alpha: 0.6)),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          onOnayla!(docId, data),
                      icon: const Icon(
                          Icons.check_rounded,
                          size: 16),
                      label: const Text('Onayla',
                          style: TextStyle(
                              fontWeight:
                                  FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(10)),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _detayRow(IconData ikon, String deger,
      {Color? degerRenk}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(ikon, color: Colors.white38, size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            deger,
            style: TextStyle(
                color: degerRenk ?? Colors.white70,
                fontSize: 12),
          ),
        ),
      ],
    );
  }

  String _kisiMetni(
      int erkek, int kadin, int cocuk, int toplam) {
    final p = <String>[];
    if (erkek > 0) p.add('$erkek erkek');
    if (kadin > 0) p.add('$kadin kadın');
    if (cocuk > 0) p.add('$cocuk çocuk');
    return p.isEmpty ? '$toplam kişi' : p.join(', ');
  }
}
