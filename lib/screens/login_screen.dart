import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'main_screen.dart';

class LoginScreen extends StatelessWidget {
  final AuthService _authService = AuthService();

  LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. 로고 아이콘 (느티나무 상징)
              const Icon(Icons.park_rounded, size: 100, color: Colors.green),
              const SizedBox(height: 20),

              // 2. 환영 문구
              const Text(
                "느티나무",
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const SizedBox(height: 10),
              const Text(
                "어르신의 건강한 일상,\n느티나무가 함께합니다.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 60),

              // 3. 소셜 로그인 버튼들
              _buildLoginButton(
                label: "구글로 시작하기",
                icon: Icons.g_mobiledata,
                color: Colors.white,
                textColor: Colors.black87,
                borderColor: Colors.grey.shade300,
                onPressed: () async {
                  if (await _authService.signInWithGoogle() != null) _navigateToMain(context);
                },
              ),
              const SizedBox(height: 15),

              _buildLoginButton(
                label: "네이버로 시작하기",
                icon: Icons.check_circle,
                color: const Color(0xFF03C75A),
                textColor: Colors.white,
                onPressed: () async {
                  if (await _authService.signInWithNaver() != null) _navigateToMain(context);
                },
              ),
              const SizedBox(height: 15),

              _buildLoginButton(
                label: "카카오로 시작하기",
                icon: Icons.chat_bubble,
                color: const Color(0xFFFEE500),
                textColor: Colors.black87,
                onPressed: () async {
                  if (await _authService.signInWithKakao() != null) _navigateToMain(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToMain(BuildContext context) {
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }

  // 커스텀 버튼 위젯
  Widget _buildLoginButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
    Color? borderColor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 60, // 어르신들이 누르기 편하게 높이를 키움
      child: OutlinedButton.icon(
        icon: Icon(icon, color: textColor, size: 28),
        label: Text(label, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          backgroundColor: color,
          side: borderColor != null ? BorderSide(color: borderColor) : BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onPressed,
      ),
    );
  }
}