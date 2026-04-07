import 'package:flutter/material.dart';

class WelfareCenterScreen extends StatelessWidget {
  const WelfareCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("복지관 찾기"),
        backgroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          "복지관 목록/지도 기능이 들어갈 화면입니다.",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}