class UserModel {
  final String uid;
  final String email;
  final String ad;
  final String soyad;
  final String role;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.ad,
    required this.soyad,
    required this.role,
    this.createdAt,
  });

  // Firestore'dan gelen veriyi UserModel'e çevir
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      ad: map['ad'] ?? '',
      soyad: map['soyad'] ?? '',
      role: map['role'] ?? 'guest',
      createdAt: map['createdAt']?.toDate(),
    );
  }

  // UserModel'i Firestore'a göndermek için Map'e çevir
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'ad': ad,
      'soyad': soyad,
      'role': role,
      'createdAt': createdAt,
    };
  }
}
