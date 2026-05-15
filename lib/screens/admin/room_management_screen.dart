import 'package:flutter/material.dart';
import '../../constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoomManagementScreen extends StatefulWidget {
  final String yoneticiUid;
  final String tesisAdi;

  const RoomManagementScreen({
    super.key,
    required this.yoneticiUid,
    required this.tesisAdi,
  });

  @override
  State<RoomManagementScreen> createState() => _RoomManagementScreenState();
}

class _RoomManagementScreenState extends State<RoomManagementScreen> {

  final _firestore = FirebaseFirestore.instance;

  void _odaEkleDialog({DocumentSnapshot? mevcutOda}) {
    final odaNoCtrl = TextEditingController(
        text: mevcutOda != null ? (mevcutOda['odaNo'] ?? '') : '');
    final kapasteCtrl = TextEditingController(
        text: mevcutOda != null ? '${mevcutOda['kapasite'] ?? 2}' : '2');
    final fiyatCtrl = TextEditingController(
        text: mevcutOda != null ? '${mevcutOda['fiyat'] ?? ''}' : '');
    final aciklamaCtrl = TextEditingController(
        text: mevcutOda != null ? (mevcutOda['aciklama'] ?? '') : '');
    String seciliTip =
        mevcutOda != null ? (mevcutOda['tip'] ?? 'Standart') : 'Standart';
    bool musait =
        mevcutOda != null ? (mevcutOda['musait'] ?? true) : true;

    final tipler = ['Standart', 'Delüks', 'Süit', 'Aile', 'Apart'];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0B2E2E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModal) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      mevcutOda == null ? 'Yeni Oda Ekle' : 'Oda Düzenle',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(ctx),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                _modalField(odaNoCtrl, 'Oda Numarası', Icons.numbers),
                const SizedBox(height: 12),
                // Oda tipi dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: seciliTip,
                      dropdownColor: const Color(0xFF0F3B39),
                      isExpanded: true,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
                      items: tipler.map((t) => DropdownMenuItem(
                        value: t,
                        child: Row(
                          children: [
                            const Icon(Icons.hotel, color: Colors.white38, size: 18),
                            const SizedBox(width: 10),
                            Text(t),
                          ],
                        ),
                      )).toList(),
                      onChanged: (v) => setModal(() => seciliTip = v!),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _modalField(kapasteCtrl, 'Kapasite (kişi)',
                          Icons.people_outline,
                          inputType: TextInputType.number),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _modalField(
                          fiyatCtrl, 'Gecelik Fiyat (₺)', Icons.attach_money,
                          inputType: TextInputType.number),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _modalField(aciklamaCtrl, 'Açıklama (opsiyonel)',
                    Icons.description_outlined),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.circle, color: Colors.white38, size: 14),
                    const SizedBox(width: 8),
                    const Text('Oda Müsait mi?',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 14)),
                    const Spacer(),
                    Switch(
                      value: musait,
                      // thumbColor: Switch'in yuvarlak kısmının rengi
                      // WidgetState.selected → açık (musait) konumdayken teal rengi uygular
                      thumbColor: WidgetStateProperty.resolveWith<Color?>(
                        (states) => states.contains(WidgetState.selected)
                            ? AppColors.teal
                            : null,
                      ),
                      onChanged: (v) => setModal(() => musait = v),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (odaNoCtrl.text.trim().isEmpty ||
                          fiyatCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Oda numarası ve fiyat zorunludur.'),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                        ));
                        return;
                      }

                      // ScaffoldMessenger'ı async işlemden ÖNCE yakala
                      // Async boşluktan sonra doğrudan context kullanımı hata verir
                      final messengerRef = ScaffoldMessenger.of(context);

                      final odaData = {
                        'yoneticiUid': widget.yoneticiUid,
                        'tesisAdi': widget.tesisAdi,
                        'odaNo': odaNoCtrl.text.trim(),
                        'tip': seciliTip,
                        'kapasite':
                            int.tryParse(kapasteCtrl.text.trim()) ?? 2,
                        'fiyat':
                            double.tryParse(fiyatCtrl.text.trim()) ?? 0.0,
                        'aciklama': aciklamaCtrl.text.trim(),
                        'musait': musait,
                        'guncellemeTarihi': FieldValue.serverTimestamp(),
                      };

                      if (mevcutOda == null) {
                        odaData['olusturmaTarihi'] =
                            FieldValue.serverTimestamp();
                        await _firestore.collection('odalar').add(odaData);
                      } else {
                        await _firestore
                            .collection('odalar')
                            .doc(mevcutOda.id)
                            .update(odaData);
                      }

                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      // Önceden yakalanan messenger referansı ile snackbar göster
                      messengerRef.showSnackBar(SnackBar(
                        content: Text(mevcutOda == null
                            ? 'Oda başarıyla eklendi.'
                            : 'Oda güncellendi.'),
                        backgroundColor: AppColors.teal,
                        behavior: SnackBarBehavior.floating,
                      ));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text(
                      mevcutOda == null ? 'Oda Ekle' : 'Güncelle',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _modalField(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? inputType}) {
    return TextField(
      controller: ctrl,
      keyboardType: inputType,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.teal, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      ),
    );
  }

  Future<void> _odaSil(String docId, String odaNo) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Oda Sil',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Oda $odaNo silinecek. Bu işlem geri alınamaz.',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('İptal', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (onay == true) {
      await _firestore.collection('odalar').doc(docId).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Oda $odaNo silindi.'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _musaitlikDegistir(String docId, bool yeniDurum) async {
    await _firestore
        .collection('odalar')
        .doc(docId)
        .update({'musait': yeniDurum});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: [
              const Text('Oda Yönetimi',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _odaEkleDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Oda Ekle',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('odalar')
                .where('yoneticiUid', isEqualTo: widget.yoneticiUid)
                .orderBy('odaNo')
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: AppColors.teal));
              }
              final odalar = snap.data!.docs;

              if (odalar.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bed_outlined,
                          color: Colors.white24, size: 56),
                      const SizedBox(height: 12),
                      const Text('Henüz oda eklenmedi.',
                          style:
                              TextStyle(color: Colors.white38, fontSize: 15)),
                      const SizedBox(height: 8),
                      const Text('Sağ üstteki "Oda Ekle" butonunu kullanın.',
                          style:
                              TextStyle(color: Colors.white24, fontSize: 12)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: odalar.length,
                itemBuilder: (ctx, i) {
                  final doc = odalar[i];
                  final data = doc.data() as Map<String, dynamic>;
                  return _odaKarti(doc, data);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _odaKarti(DocumentSnapshot doc, Map<String, dynamic> data) {
    final odaNo = data['odaNo'] ?? '-';
    final tip = data['tip'] ?? 'Standart';
    final kapasite = data['kapasite'] ?? 2;
    final fiyat = data['fiyat'] ?? 0;
    final musait = data['musait'] ?? true;
    final aciklama = data['aciklama'] ?? '';

    final musaitRenk = musait ? Colors.green : Colors.redAccent;
    final musaitYazi = musait ? 'Müsait' : 'Dolu';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: musaitRenk.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: musaitRenk.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    odaNo,
                    style: TextStyle(
                        color: musaitRenk,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$tip Oda',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                    Text(
                      '$kapasite Kişilik  •  ₺${fiyat.toStringAsFixed(0)} / gece',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12),
                    ),
                    if (aciklama.isNotEmpty)
                      Text(aciklama,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: musaitRenk.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(musaitYazi,
                    style: TextStyle(
                        color: musaitRenk,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Müsaitlik toggle
              GestureDetector(
                onTap: () => _musaitlikDegistir(doc.id, !musait),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                          musait
                              ? Icons.toggle_on
                              : Icons.toggle_off,
                          color: musait ? AppColors.teal : Colors.white38,
                          size: 18),
                      const SizedBox(width: 6),
                      Text(
                        musait ? 'Dolu Yap' : 'Müsait Yap',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // Düzenle butonu
              IconButton(
                onPressed: () => _odaEkleDialog(mevcutOda: doc),
                icon: const Icon(Icons.edit_outlined,
                    color: Colors.white54, size: 20),
                tooltip: 'Düzenle',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 16),
              // Sil butonu
              IconButton(
                onPressed: () => _odaSil(doc.id, odaNo),
                icon: const Icon(Icons.delete_outline,
                    color: Colors.redAccent, size: 20),
                tooltip: 'Sil',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
