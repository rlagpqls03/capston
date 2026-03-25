import 'package:flutter/material.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:flutter_naver_login/interface/types/naver_login_status.dart';

void main() {
  runApp(const MaterialApp(home: NaverTestScreen()));
}

class NaverTestScreen extends StatefulWidget {
  const NaverTestScreen({super.key});

  @override
  State<NaverTestScreen> createState() => _NaverTestScreenState();
}

class _NaverTestScreenState extends State<NaverTestScreen> {
  String _status = "로그인 전";
  String _userData = "";

  Future<void> _login() async {
    print("---------- 네이버 로그인 프로세스 시작 ----------");
    setState(() => _status = "로그인 시도 중...");

    try {
      // 1. 로그인 함수 호출 직전 로그
      print("1. FlutterNaverLogin.logIn() 호출합니다.");
      final result = await FlutterNaverLogin.logIn();

      // 2. 결과 값 로그
      print("2. 응답 수신: status=${result.status}");

      if (result.status == NaverLoginStatus.loggedIn) {
        print("3. 로그인 성공! 사용자 정보 가져오는 중...");
        setState(() {
          _status = "로그인 성공!";
          _userData = "이름: ${result.account?.name}\n이메일: ${result.account?.email}";
        });
      } else {
        print("3. 로그인 실패 혹은 취소됨: ${result.status}");
        setState(() => _status = "로그인 실패: ${result.status}");
      }
    } catch (e) {
      // 4. 에러 발생 시 로그 (이게 제일 중요합니다)
      print("!!! 에러 발생 !!!");
      print("에러 내용: $e");
      setState(() => _status = "에러: $e");
    }
    print("---------- 네이버 로그인 프로세스 종료 ----------");
  }

  Future<void> _logout() async {
    print("로그아웃 호출됨");
    await FlutterNaverLogin.logOut();
    setState(() {
      _status = "로그아웃 완료";
      _userData = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("네이버 로그인 테스트"),
        backgroundColor: const Color(0xFF03C75A),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            if (_userData.isNotEmpty) Text(_userData, textAlign: TextAlign.center),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF03C75A),
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 50),
              ),
              child: const Text("네이버로 시작하기"),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _logout,
              child: const Text("로그아웃"),
            ),
          ],
        ),
      ),
    );
  }
}