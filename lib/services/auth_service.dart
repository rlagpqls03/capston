import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_naver_login/interface/types/naver_login_result.dart';
import 'package:flutter_naver_login/interface/types/naver_login_status.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // 현재 유저 정보 가져오기
  User? get user => _auth.currentUser;

  // 1. 구글 로그인 로직
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 구글 로그인 팝업 호출
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      // 구글 인증 정보 획득
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 파이어베이스용 크리덴셜 생성
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 파이어베이스 로그인 실행
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print("구글 로그인 에러: $e");
      return null;
    }
  }

  // 2. 네이버 로그인 로직
  // *참고: 네이버는 파이어베이스와 직접 연동되지 않으므로, 로그인 후 정보를 받아오는 방식입니다.*
  Future<NaverLoginResult?> signInWithNaver() async {
    try {
      // 네이버 로그인 실행
      final NaverLoginResult result = await FlutterNaverLogin.logIn();

      if (result.status == NaverLoginStatus.loggedIn) {
        print("네이버 로그인 성공: ${result.account?.nickname}");

        // [백엔드 팁] 파이어베이스 유저로 등록하고 싶다면:
        // 여기서 받아온 result.account.email을 이용해
        // 파이어베이스 익명 로그인이나 커스텀 토큰 처리를 추가할 수 있습니다.

        return result;
      }
      return null;
    } catch (e) {
      print("네이버 로그인 에러: $e");
      return null;
    }
  }

  // 3. 로그아웃 (구글, 네이버 모두 세션 해제)
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();      // 구글 세션 해제
      await FlutterNaverLogin.logOut();    // 네이버 세션 해제
      await _auth.signOut();              // 파이어베이스 세션 해제
    } catch (e) {
      print("로그아웃 에러: $e");
    }
  }
}