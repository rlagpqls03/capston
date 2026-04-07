import 'package:flutter/material.dart';

class JobScreen extends StatelessWidget {
  const JobScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("일자리 찾기"),
        backgroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          "일자리 정보와 사이트 연동 기능이 들어갈 화면입니다.",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}