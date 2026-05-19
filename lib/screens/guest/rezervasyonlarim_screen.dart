import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants.dart';

class ReservasyonlarimScreen extends StatefulWidget {
  const ReservasyonlarimScreen({super.key});

  @override
  State<ReservasyonlarimScreen> createState() =>
      _ReservasyonlarimScreenState();
}

class _ReservasyonlarimScreenState
    extends State<ReservasyonlarimScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _firestore = FirebaseFirestore.instance;
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

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

  // Rezervasyonu iptal et (sadece beklemede olanlar)
  Future<void> _iptalEt(String docId) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cancel_outlined,
                    color: Colors.redAccent, size: 32),
              ),
              const SizedBox(height: 16),
              const Text('Talebi İptal Et',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'Bu rezervasyon talebini iptal etmek istediğinize emin misiniz?',
                style: TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () =>
                          Navigator.pop(ctx, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(10)),
                      ),
                      child: const Text('Vazgeç',
                          style: TextStyle(
                              color: Colors.white54)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text('İptal Et'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (onay != true) return;
    await _firestore
        .collection('rezervasyonlar')
        .doc(docId)
        .update({
      'durum': 'iptal edildi',
      'guncellemeTarihi': FieldValue.serverTimestamp(),
    });

    // Log: misafir kendi rezervasyonunu iptal etti
    await _firestore.collection('logs').add({
      'action': 'rezervasyon_iptal_edildi',
      'rezervasyonId': docId,
      'misafirUid': _uid,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: appGradient),
      child: SafeArea(
        child: Column(
          children: [
            // ── BAŞLIK ────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          AppColors.teal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.bookmark,
                        color: AppColors.teal, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rezervasyonlarım',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Talepler, onaylananlar ve geçmiş',
                        style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── SEKİM BUTONLARI ───────────────────────────────
            AnimatedBuilder(
              animation: _tabCtrl,
              builder: (context, _) {
                final aktif = _tabCtrl.index;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20),
                  child: Row(
                    children: [
                      _sekmeButon(
                        index: 0,
                        aktif: aktif,
                        ikon: Icons.hourglass_top_rounded,
                        label: 'Talepler',
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
                        ikon: Icons.history,
                        label: 'Geçmiş',
                        renk: Colors.white54,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // ── TAB VIEW ─────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _RezervasyonListesi(
                    uid: _uid,
                    firestore: _firestore,
                    durumlar: const ['beklemede'],
                    bosMesaj:
                        'Bekleyen rezervasyon talebiniz yok.',
                    bosIkon: Icons.hourglass_empty,
                    onIptal: _iptalEt,
                  ),
                  _RezervasyonListesi(
                    uid: _uid,
                    firestore: _firestore,
                    durumlar: const ['onaylandi'],
                    bosMesaj:
                        'Onaylanmış rezervasyonunuz bulunmuyor.',
                    bosIkon: Icons.event_available_outlined,
                  ),
                  _RezervasyonListesi(
                    uid: _uid,
                    firestore: _firestore,
                    durumlar: const [
                      'reddedildi',
                      'iptal edildi'
                    ],
                    bosMesaj: 'Geçmiş rezervasyon kaydı yok.',
                    bosIkon: Icons.history_toggle_off,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
              Icon(
                ikon,
                color: secili ? renk : Colors.white24,
                size: 18,
              ),
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
  final String uid;
  final FirebaseFirestore firestore;
  final List<String> durumlar;
  final String bosMesaj;
  final IconData bosIkon;
  final Future<void> Function(String docId)? onIptal;

  const _RezervasyonListesi({
    required this.uid,
    required this.firestore,
    required this.durumlar,
    required this.bosMesaj,
    required this.bosIkon,
    this.onIptal,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('rezervasyonlar')
          .where('misafirUid', isEqualTo: uid)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(
                  color: AppColors.teal, strokeWidth: 2));
        }

        // Duruma göre filtrele + tarihe göre sırala
        // (orderBy Firestore'da kullanılmıyor → composite index gerekmez)
        final docs = snap.data!.docs.where((d) {
          final durum = (d.data()
              as Map<String, dynamic>)['durum'] as String? ??
              '';
          return durumlar.contains(durum);
        }).toList()
          ..sort((a, b) {
            final aT = (a.data() as Map<String, dynamic>)['olusturmaTarihi'];
            final bT = (b.data() as Map<String, dynamic>)['olusturmaTarihi'];
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
                Text(
                  bosMesaj,
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding:
              const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final doc = docs[i];
            final data =
                doc.data() as Map<String, dynamic>;
            return _RezervasyonKarti(
              docId: doc.id,
              data: data,
              onIptal: onIptal,
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
  final Future<void> Function(String)? onIptal;

  const _RezervasyonKarti({
    required this.docId,
    required this.data,
    this.onIptal,
  });

  @override
  Widget build(BuildContext context) {
    final String tesisAdi = data['tesisAdi'] ?? '-';
    final String odaTip = data['odaTip'] ?? '-';
    final String odaNo = data['odaNo'] ?? '-';
    final String giris = data['girisTarihi'] ?? '-';
    final String cikis = data['cikisTarihi'] ?? '-';
    final int geceSayisi = data['geceSayisi'] ?? 0;
    final int erkek = data['erkekSayisi'] ?? 0;
    final int kadin = data['kadinSayisi'] ?? 0;
    final int cocuk = data['cocukSayisi'] ?? 0;
    final double toplam = (data['toplamTutar'] ?? 0).toDouble();
    final String durum = data['durum'] ?? 'beklemede';
    final int toplamKisi = erkek + kadin + cocuk;

    final _DurumBilgi durumBilgi = _durumBilgi(durum);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: durumBilgi.kenarRenk
              .withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          // ── ÜST BANT (tesis + durum) ──────────────────
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: durumBilgi.kenarRenk
                  .withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.teal
                        .withValues(alpha: 0.15),
                    borderRadius:
                        BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.hotel,
                      color: AppColors.teal, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        tesisAdi,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$odaTip  •  $odaNo Nolu Oda',
                        style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11),
                      ),
                    ],
                  ),
                ),
                // Durum badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: durumBilgi.kenarRenk
                        .withValues(alpha: 0.18),
                    borderRadius:
                        BorderRadius.circular(20),
                    border: Border.all(
                      color: durumBilgi.kenarRenk
                          .withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(durumBilgi.ikon,
                          color: durumBilgi.kenarRenk,
                          size: 12),
                      const SizedBox(width: 4),
                      Text(
                        durumBilgi.etiket,
                        style: TextStyle(
                            color: durumBilgi.kenarRenk,
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── DETAYLAR ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Tarih satırı
                Row(
                  children: [
                    const Icon(
                        Icons.calendar_today_outlined,
                        color: Colors.white38,
                        size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '$giris → $cikis',
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13),
                    ),
                    const Spacer(),
                    const Icon(
                        Icons.nights_stay_outlined,
                        color: Colors.white38,
                        size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$geceSayisi gece',
                      style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Kişi + fiyat satırı
                Row(
                  children: [
                    const Icon(Icons.people_outline,
                        color: Colors.white38, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      _kisiMetni(
                          erkek, kadin, cocuk, toplamKisi),
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13),
                    ),
                    const Spacer(),
                    Text(
                      '₺${toplam.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: AppColors.teal,
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                // İptal butonu (sadece beklemede)
                if (onIptal != null && durum == 'beklemede') ...[
                  const SizedBox(height: 12),
                  Divider(
                      height: 1,
                      color: Colors.white
                          .withValues(alpha: 0.07)),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: OutlinedButton.icon(
                      onPressed: () => onIptal!(docId),
                      icon: const Icon(
                          Icons.cancel_outlined,
                          size: 15),
                      label: const Text(
                          'Talebi İptal Et',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            Colors.redAccent,
                        side: BorderSide(
                            color: Colors.redAccent
                                .withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                                    10)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _kisiMetni(
      int erkek, int kadin, int cocuk, int toplam) {
    final parcalar = <String>[];
    if (erkek > 0) parcalar.add('$erkek erkek');
    if (kadin > 0) parcalar.add('$kadin kadın');
    if (cocuk > 0) parcalar.add('$cocuk çocuk');
    if (parcalar.isEmpty) return '$toplam kişi';
    return parcalar.join(', ');
  }

  _DurumBilgi _durumBilgi(String durum) {
    switch (durum) {
      case 'onaylandi':
        return _DurumBilgi(
          etiket: 'Onaylandı',
          ikon: Icons.check_circle_outline,
          kenarRenk: Colors.green,
        );
      case 'reddedildi':
        return _DurumBilgi(
          etiket: 'Reddedildi',
          ikon: Icons.cancel_outlined,
          kenarRenk: Colors.redAccent,
        );
      case 'iptal edildi':
        return _DurumBilgi(
          etiket: 'İptal Edildi',
          ikon: Icons.do_not_disturb_alt_outlined,
          kenarRenk: Colors.white38,
        );
      default: // beklemede
        return _DurumBilgi(
          etiket: 'Beklemede',
          ikon: Icons.hourglass_top_rounded,
          kenarRenk: Colors.orange,
        );
    }
  }
}

class _DurumBilgi {
  final String etiket;
  final IconData ikon;
  final Color kenarRenk;
  const _DurumBilgi({
    required this.etiket,
    required this.ikon,
    required this.kenarRenk,
  });
}
