class CalisanModel {
  final String calisanID;
  final String ad;
  final String soyad;
  final String email;
  final String pozisyon;
  final DateTime? iseBaslamaTarihi;

  CalisanModel({
    required this.calisanID,
    required this.ad,
    required this.soyad,
    required this.email,
    required this.pozisyon,
    this.iseBaslamaTarihi,
  });

  factory CalisanModel.fromMap(Map<String, dynamic> map) {
    return CalisanModel(
      calisanID: map['calisanID'] ?? '',
      ad: map['ad'] ?? '',
      soyad: map['soyad'] ?? '',
      email: map['email'] ?? '',
      pozisyon: map['pozisyon'] ?? '',
      iseBaslamaTarihi: map['iseBaslamaTarihi']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'calisanID': calisanID,
      'ad': ad,
      'soyad': soyad,
      'email': email,
      'pozisyon': pozisyon,
      'rol': 'admin',
      'iseBaslamaTarihi': iseBaslamaTarihi,
    };
  }
}
