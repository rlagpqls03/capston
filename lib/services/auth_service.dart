import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_naver_login/interface/types/naver_login_result.dart';
import 'package:flutter_naver_login/interface/types/naver_login_status.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;

class AuthService {
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // 인증 상태 스트림 (주로 구글/파이어베이스용)
  Stream<auth.User?> get userStream => _auth.authStateChanges();

  // Firestore 저장 로직 (에러 발생 시에도 중단되지 않도록 수정)
  Future<void> _saveUserToFirestore({
    required String uid,
    String? email,
    String? displayName,
    String? photoUrl,
    required String provider,
  }) async {
    try {
      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'email': email ?? '',
        'displayName': displayName ?? '사용자',
        'photoUrl': photoUrl ?? '',
        'provider': provider,
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print("DEBUG: Firestore 저장 성공 ($provider)");
    } catch (e) {
      // 에러가 나더라도 로그만 찍고 프로세스를 멈추지 않음
      print("DEBUG: Firestore 권한 부족 또는 에러 발생(무시하고 진행): $e");
    }
  }

  // 구글 로그인
  Future<auth.UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final auth.OAuthCredential credential = auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken, idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        await _saveUserToFirestore(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email,
          displayName: userCredential.user!.displayName,
          photoUrl: userCredential.user!.photoURL,
          provider: 'google',
        );
      }
      return userCredential;
    } catch (e) { return null; }
  }

  // 네이버 로그인
  Future<NaverLoginResult?> signInWithNaver() async {
    try {
      final NaverLoginResult result = await FlutterNaverLogin.logIn();
      if (result.status == NaverLoginStatus.loggedIn) {
        await _saveUserToFirestore(
          uid: "naver_${result.account?.id}",
          email: result.account?.email,
          displayName: result.account?.nickname,
          photoUrl: result.account?.profileImage,
          provider: 'naver',
        );
        return result;
      }
      return null;
    } catch (e) { return null; }
  }

  // 카카오 로그인
  Future<kakao.User?> signInWithKakao() async {
    try {
      bool isInstalled = await kakao.isKakaoTalkInstalled();
      if (isInstalled) {
        await kakao.UserApi.instance.loginWithKakaoTalk();
      } else {
        await kakao.UserApi.instance.loginWithKakaoAccount();
      }
      final kakaoUser = await kakao.UserApi.instance.me();
      await _saveUserToFirestore(
        uid: "kakao_${kakaoUser.id}",
        email: kakaoUser.kakaoAccount?.email,
        displayName: kakaoUser.kakaoAccount?.profile?.nickname,
        photoUrl: kakaoUser.kakaoAccount?.profile?.thumbnailImageUrl,
        provider: 'kakao',
      );
      return kakaoUser;
    } catch (e) { return null; }
  }

  // 통합 로그아웃
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await FlutterNaverLogin.logOut();
    try { await kakao.UserApi.instance.logout(); } catch (_) {}
    await _auth.signOut();
  }
}