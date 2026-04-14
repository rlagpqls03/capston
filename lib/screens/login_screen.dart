import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../services/auth_service.dart';
import 'registration_screen.dart';
import 'main_screen.dart';

class LoginScreen extends StatelessWidget {
  final AuthService _authService = AuthService();

  LoginScreen({super.key});

  Future<void> _handleLogin(BuildContext context, String provider) async {
    String? socialId;

    // 로딩 인디케이터 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.green),
      ),
    );

    try {
      if (provider == "google") {
        socialId = await _authService.signInWithGoogle();
      } else if (provider == "kakao") {
        socialId = await _authService.signInWithKakao();
      } else if (provider == "naver") {
        socialId = await _authService.signInWithNaver();
      }

      // [핵심] socialId가 널이 아님을 이미 체크했습니다.
      if (socialId != null && context.mounted) {
        bool isIncomplete = await _authService.isProfileIncomplete(socialId);

        if (context.mounted) {
          Navigator.pop(context); // 로딩 창 닫기
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => isIncomplete
                  ? RegistrationScreen(socialId: socialId!) // [에러 해결!] ! 추가
                  : MainScreen(socialId: socialId),
            ),
          );
        }
      } else {
        if (context.mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      print("로그인 에러: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.park_rounded, size: 100, color: Colors.green),
              ),
              const SizedBox(height: 24),
              const Text(
                "느티나무",
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E4D2E),
                ),
              ),
              const Spacer(flex: 2),
              _buildSocialButton(
                label: "카카오톡으로 시작하기",
                color: const Color(0xFFFEE500),
                textColor: Colors.black87,
                imagePath: 'assets/img/kakao_logo.png',
                imageSize: 40,
                onPressed: () => _handleLogin(context, "kakao"),
              ),
              const SizedBox(height: 16),
              _buildSocialButton(
                label: "네이버로 시작하기",
                color: const Color(0xFF03C75A),
                textColor: Colors.white,
                imagePath: 'assets/img/naver_logo.png',
                imageSize: 40,
                onPressed: () => _handleLogin(context, "naver"),
              ),
              const SizedBox(height: 16),
              _buildSocialButton(
                label: "구글로 시작하기",
                color: Colors.white,
                textColor: Colors.black87,
                imagePath: 'assets/img/google_logo.png',
                imageSize: 35,
                border: BorderSide(color: Colors.grey.shade300, width: 2),
                onPressed: () => _handleLogin(context, "google"),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String label,
    required Color color,
    required Color textColor,
    required String imagePath,
    required double imageSize,
    required VoidCallback onPressed,
    BorderSide? border,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 80,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 2,
          side: border,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onPressed,
        child: Row(
          children: [
            const SizedBox(width: 16),
            SizedBox(
              width: 48,
              child: Center(
                child: Image.asset(imagePath, width: imageSize, height: imageSize, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}
