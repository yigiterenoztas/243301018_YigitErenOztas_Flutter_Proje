import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// AuthService: Tüm kimlik doğrulama işlemlerini yöneten servis sınıfı
// Firebase Authentication ve Firestore ile iletişim buradan
class AuthService {
  // Firebase Authentication örneği - giriş/çıkış/kayıt işlemleri için
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Firestore veritabanı örneği - kullanıcı bilgilerini kaydetmek için
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Oturum durumunu anlık izleyen stream
  // Kullanıcı giriş/çıkış yaptığında otomatik tetiklenir
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── MİSAFİR KAYDI ─────────────────────────────────────────────
  // Normal kullanıcı (misafir) kaydı oluşturur
  // email, password: giriş bilgileri | ad, soyad: kullanıcı adı
  Future<String?> register({
    required String email,
    required String password,
    required String ad,
    required String soyad,
  }) async {
    try {
      // Firebase Authentication'da yeni kullanıcı oluştur
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Kullanıcı bilgilerini Firestore'daki 'users' koleksiyonuna kaydet
      // doc(uid) → her kullanıcının kendi ID'si ile belgesi olur
      await _firestore.collection('users').doc(result.user!.uid).set({
        'uid': result.user!.uid,
        'email': email,
        'ad': ad,
        'soyad': soyad,
        'role': 'guest', // Varsayılan rol: misafir
        'createdAt':
            FieldValue.serverTimestamp(), // Kayıt tarihi (sunucu saati)
      });

      // Kayıt işlemini log koleksiyonuna yaz (takip amaçlı)
      await _firestore.collection('logs').add({
        'uid': result.user!.uid,
        'action': 'register',
        'timestamp': FieldValue.serverTimestamp(),
      });

      return null; // null = hata yok, işlem başarılı
    } on FirebaseAuthException catch (e) {
      // Firebase'den gelen özel hata kodlarını Türkçe mesaja çevir
      switch (e.code) {
        case 'email-already-in-use':
          return 'Bu e-posta adresi zaten kullanımda.';
        case 'invalid-email':
          return 'Geçersiz bir e-posta adresi girdiniz.';
        case 'weak-password':
          return 'Şifre çok zayıf. Lütfen daha güçlü bir şifre seçin.';
        default:
          return 'Kayıt sırasında bir hata oluştu: ${e.message}';
      }
    } catch (e) {
      return 'Beklenmedik bir hata oluştu.';
    }
  }

  // ── TESİS YÖNETİCİSİ KAYDI ────────────────────────────────────
  // Tesis yöneticisi kaydı - süper admin onayı gerektirir
  // Misafir kaydından farkı: 'role' alanı 'pending_yonetici' olarak başlar
  Future<String?> registerYonetici({
    required String email,
    required String password,
    required String ad,
    required String soyad,
    required String tesisAdi, // Misafir kaydında bu alan yok
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Yönetici adayını Firestore'a kaydet
      await _firestore.collection('users').doc(result.user!.uid).set({
        'uid': result.user!.uid,
        'email': email,
        'ad': ad,
        'soyad': soyad,
        'tesisAdi': tesisAdi,
        'role': 'pending_yonetici', // Süper admin onaylayana kadar bu rol kalır
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Yönetici kayıt isteğini logla
      await _firestore.collection('logs').add({
        'uid': result.user!.uid,
        'action': 'yonetici_register',
        'timestamp': FieldValue.serverTimestamp(),
      });

      return null; // Hata yok
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'Bu e-posta adresi zaten kullanımda.';
        case 'invalid-email':
          return 'Geçersiz bir e-posta adresi girdiniz.';
        case 'weak-password':
          return 'Şifre çok zayıf. Lütfen daha güçlü bir şifre seçin.';
        default:
          return 'Kayıt sırasında bir hata oluştu: ${e.message}';
      }
    } catch (e) {
      return 'Beklenmedik bir hata oluştu.';
    }
  }

  // ── GİRİŞ YAP ─────────────────────────────────────────────────
  // Kullanıcıyı e-posta ve şifre ile giriş yaptırır
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Giriş yapıldığını logla
      await _firestore.collection('logs').add({
        'uid': result.user!.uid,
        'action': 'login',
        'timestamp': FieldValue.serverTimestamp(),
      });

      return null; // Giriş başarılı
    } on FirebaseAuthException catch (e) {
      // Firebase hata kodlarını kullanıcı dostu mesajlara çevir
      switch (e.code) {
        case 'invalid-credential':
          return 'E-posta veya şifre hatalı. Lütfen tekrar deneyin.';
        case 'user-not-found':
          return 'Bu e-posta adresine ait bir kullanıcı bulunamadı.';
        case 'wrong-password':
          return 'Hatalı şifre girdiniz.';
        case 'user-disabled':
          return 'Bu hesap devre dışı bırakılmıştır.';
        case 'too-many-requests':
          return 'Çok fazla hatalı giriş denemesi. Lütfen bir süre bekleyin.';
        case 'invalid-email':
          return 'Girdiğiniz e-posta adresi geçersizdir.';
        default:
          return 'Giriş yapılamadı: ${e.message}';
      }
    } catch (e) {
      return 'Bağlantı hatası veya beklenmedik bir sorun oluştu.';
    }
  }

  // ── ÇIKIŞ YAP ─────────────────────────────────────────────────
  // Kullanıcının oturumunu sonlandırır
  Future<void> logout() async {
    String? uid = _auth.currentUser?.uid;
    if (uid != null) {
      // Çıkış işlemini logla
      await _firestore.collection('logs').add({
        'uid': uid,
        'action': 'logout',
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
    await _auth.signOut(); // Firebase oturumunu kapat
  }

  // ── MEVCUT KULLANICI ──────────────────────────────────────────
  // Şu an giriş yapmış kullanıcıyı döndürür, giriş yoksa null
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // ── KULLANICI ROLÜ ────────────────────────────────────────────
  // Giriş yapan kullanıcının rolünü Firestore'dan çeker
  // Dönen değerler: 'guest' | 'yonetici' | 'pending_yonetici' | 'superadmin' | 'rejected'
  Future<String?> getUserRole() async {
    User? user = _auth.currentUser;
    if (user == null) return null;

    DocumentSnapshot doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();
    if (doc.exists) {
      return doc['role'] as String?;
    }
    return null;
  }

  // ── MEVCUT ÇALIŞAN ────────────────────────────────────────────
  // Admin paneli için çalışan bilgisini ayrı koleksiyondan çeker
  Future<Map<String, dynamic>?> getCurrentCalisan() async {
    User? user = _auth.currentUser;
    if (user == null) return null;

    DocumentSnapshot doc = await _firestore
        .collection('calisanlar')
        .doc(user.uid)
        .get();
    if (doc.exists) {
      return doc.data() as Map<String, dynamic>;
    }
    return null;
  }
}
