import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:flutter_naver_login/flutter_naver_login.dart';

class AuthService {
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<auth.User?> get userStream => _auth.authStateChanges();

  // [수정] 고정된 소셜 ID를 사용하여 가입 여부를 정확히 판단합니다.
  Future<bool> isProfileIncomplete(String socialId) async {
    try {
      final doc = await _db.collection('users').doc(socialId).get();
      if (!doc.exists) return true;

      Map<String, dynamic>? data = doc.data();
      final role = (data?['role'] ?? '').toString();
      final phone = (data?['phone'] ?? '').toString();
      return role.isEmpty || phone.isEmpty;
    } catch (e) {
      return true;
    }
  }

  // [핵심] 익명 UID 대신 socialId를 문서 이름으로 사용합니다.
  Future<void> _saveUserToFirestore({
    required String socialId, // 고정된 번호 (kakao_123 등)
    required String authUid,
    String? email,
    String? displayName,
    String? photoUrl,
    required String provider,
  }) async {
    try {
      await _db.collection('users').doc(socialId).set({
        'socialId': socialId,
        'email': email ?? '',
        'displayName': displayName ?? '사용자',
        'photoUrl': photoUrl ?? '',
        'provider': provider,
        'authUid': authUid,
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // 기존 데이터 유지하며 업데이트
    } catch (e) {
      print("Firestore 저장 에러: $e");
    }
  }

  Future<String?> resolveSocialIdForCurrentUser(auth.User user) async {
    if (!user.isAnonymous) return user.uid;

    try {
      final result = await _db
          .collection('users')
          .where('authUid', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (result.docs.isNotEmpty) {
        return result.docs.first.id;
      }
    } catch (_) {}

    return null;
  }

  // 1. 구글 로그인
  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final auth.OAuthCredential credential = auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken, idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        await _saveUserToFirestore(
          socialId: user.uid, // 구글은 UID가 고정되므로 그대로 사용
          authUid: user.uid,
          email: user.email,
          displayName: user.displayName,
          photoUrl: user.photoURL,
          provider: 'google',
        );
        return user.uid;
      }
      return null;
    } catch (e) { return null; }
  }

  // 2. 네이버 로그인
  Future<String?> signInWithNaver() async {
    try {
      final dynamic result = await FlutterNaverLogin.logIn();
      if (result.status.toString().contains('loggedIn')) {
        String naverId = "naver_${result.account.id}"; // ID 고정

        await _auth.signInAnonymously(); // 통행증 발급
        final authUid = _auth.currentUser?.uid ?? "";
        if (authUid.isEmpty) return null;

        await _saveUserToFirestore(
          socialId: naverId,
          authUid: authUid,
          email: result.account?.email,
          displayName: result.account?.nickname,
          photoUrl: result.account?.profileImage,
          provider: 'naver',
        );
        return naverId;
      }
      return null;
    } catch (e) { return null; }
  }

  // 3. 카카오 로그인
  Future<String?> signInWithKakao() async {
    try {
      bool isInstalled = await kakao.isKakaoTalkInstalled();
      isInstalled ? await kakao.UserApi.instance.loginWithKakaoTalk()
          : await kakao.UserApi.instance.loginWithKakaoAccount();

      final kakaoUser = await kakao.UserApi.instance.me();
      String kakaoId = "kakao_${kakaoUser.id}"; // ID 고정

      await _auth.signInAnonymously(); // 통행증 발급
      final authUid = _auth.currentUser?.uid ?? "";
      if (authUid.isEmpty) return null;

      await _saveUserToFirestore(
        socialId: kakaoId,
        authUid: authUid,
        email: kakaoUser.kakaoAccount?.email,
        displayName: kakaoUser.kakaoAccount?.profile?.nickname,
        photoUrl: kakaoUser.kakaoAccount?.profile?.thumbnailImageUrl,
        provider: 'kakao',
      );
      return kakaoId;
    } catch (e) { return null; }
  }

  Future<void> signOut() async {
    try { if (await _googleSignIn.isSignedIn()) await _googleSignIn.signOut(); } catch (_) {}
    try { await FlutterNaverLogin.logOut(); } catch (_) {}
    try { await kakao.UserApi.instance.logout(); } catch (_) {}
    await _auth.signOut();
  }
}
