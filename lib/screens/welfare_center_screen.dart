import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class WelfareCenterScreen extends StatelessWidget {
  const WelfareCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("복지관 찾기"),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: const Text(
            "복지관 목록과 지도 연결 기능을\n곧 여기서 사용할 수 있어요.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              height: 1.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
        ),
      ),
    );
  }
}
