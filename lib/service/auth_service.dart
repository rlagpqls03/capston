import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 현재 유저 정보 가져오기
  User? get user => _auth.currentUser;

  // 구글 로그인 로직 (다음 단계에서 상세 구현)
  Future<UserCredential?> signInWithGoogle() async {
    // TODO: GoogleSignIn 구현
    return null;
  }

  // 네이버 로그인 로직 (다음 단계에서 상세 구현)
  Future<UserCredential?> signInWithNaver() async {
    // TODO: NaverLogin 구현
    return null;
  }

  // 로그아웃
  Future<void> signOut() async {
    await _auth.signOut();
  }
}