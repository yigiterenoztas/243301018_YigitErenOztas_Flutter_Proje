import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Giriş yapmış kullanıcıyı dinle
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Kayıt ol
  Future<String?> register({
    required String email,
    required String password,
    required String ad,
    required String soyad,
  }) async {
    try {
      // Firebase Auth'a kayıt et
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Firestore'a kullanıcı bilgilerini kaydet
      await _firestore.collection('users').doc(result.user!.uid).set({
        'uid': result.user!.uid,
        'email': email,
        'ad': ad,
        'soyad': soyad,
        'role': 'guest',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Log kaydı
      await _firestore.collection('logs').add({
        'uid': result.user!.uid,
        'action': 'register',
        'timestamp': FieldValue.serverTimestamp(),
      });

      return null; // Hata yok
    } catch (e) {
      return e.toString(); // Hata mesajını döndür
    }
  }

  // Giriş yap
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Log kaydı
      await _firestore.collection('logs').add({
        'uid': result.user!.uid,
        'action': 'login',
        'timestamp': FieldValue.serverTimestamp(),
      });

      return null; // Hata yok
    } catch (e) {
      return e.toString(); // Hata mesajını döndür
    }
  }

  // Çıkış yap
  Future<void> logout() async {
    String? uid = _auth.currentUser?.uid;

    // Log kaydı
    if (uid != null) {
      await _firestore.collection('logs').add({
        'uid': uid,
        'action': 'logout',
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    await _auth.signOut();
  }

  // Mevcut kullanıcıyı getir
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Kullanıcı rolünü getir
  Future<String?> getUserRole() async {
    User? user = _auth.currentUser;
    if (user == null) return null;

    DocumentSnapshot doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();
    return doc['role'];
  }
}
