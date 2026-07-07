import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FacebookAuth _fbAuth = FacebookAuth.instance;

  Future<User?> signInWithFacebook() async {
    try {
      final LoginResult result = await _fbAuth.login(
        permissions: ['email', 'pages_show_list', 'pages_manage_posts'],
      );

      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        final OAuthCredential credential = FacebookAuthProvider.credential(accessToken.token);
        final UserCredential userCredential = await _auth.signInWithCredential(credential);
        return userCredential.user;
      }
      return null;
    } catch (e) {
      print("Lỗi đăng nhập: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    await _fbAuth.logOut();
    await _auth.signOut();
  }
}