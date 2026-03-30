import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // 각 탭에 들어갈 임시 화면들
  final List<Widget> _pages = [
    const Center(child: Text("오늘의 추천 운동 영상이 올 곳입니다.", style: TextStyle(fontSize: 20))),
    const Center(child: Text("주변 일자리 정보가 올 곳입니다.", style: TextStyle(fontSize: 20))),
    const Center(child: Text("어르신들의 대화방이 올 곳입니다.", style: TextStyle(fontSize: 20))),
    const Center(child: Text("내 포인트와 정보가 올 곳입니다.", style: TextStyle(fontSize: 20))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("느티나무", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            onPressed: () async {
              await AuthService().signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => LoginScreen()), (route) => false,
                );
              }
            },
          )
        ],
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: Column(
          children: [
            // 상단 환영 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.green.shade400,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("안녕하세요!", style: TextStyle(color: Colors.white, fontSize: 18)),
                  SizedBox(height: 5),
                  Text("오늘도 건강한 하루 되세요!", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(child: _pages[_selectedIndex]),
          ],
        ),
      ),
      // 하단 네비게이션 바 (어르신들이 보기 쉽게 아이콘과 글자를 크게)
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 16,
        unselectedFontSize: 14,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: "운동"),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: "일자리"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "동네"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "내정보"),
        ],
      ),
    );
  }
}