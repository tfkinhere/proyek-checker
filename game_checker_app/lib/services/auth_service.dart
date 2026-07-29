import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // PERUBAHAN V7: Pemanggilan tidak lagi menggunakan new GoogleSignIn()
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // PERUBAHAN V7: Di versi terbaru, kita WAJIB melakukan inisialisasi di awal
      await _googleSignIn.initialize();

      // PERUBAHAN V7: Fungsi signIn() diganti menjadi authenticate()
      final GoogleSignInAccount? googleUser = await _googleSignIn
          .authenticate();

      // Jika user menekan tombol 'back' atau batal memilih akun
      if (googleUser == null) return null;

      // PERUBAHAN V7: googleUser.authentication sekarang sinkronus (TIDAK boleh pakai await)
      final googleAuth = googleUser.authentication;

      // PERUBAHAN V7: accessToken sekarang ditarik terpisah untuk keamanan tambahan
      final clientAuth = await googleUser.authorizationClient?.authorizeScopes([
        'email',
        'profile',
      ]);

      // Mengubah kunci dari Google menjadi kunci yang dikenali oleh Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: clientAuth?.accessToken,
        idToken:
            googleAuth.idToken, // idToken tetap ditarik dari authentication
      );

      // Masuk ke Firebase menggunakan kunci tersebut
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print("Terjadi error saat Google Sign-In: $e");
      return null;
    }
  }
}
