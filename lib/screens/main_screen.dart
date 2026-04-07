import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class MainScreen extends StatefulWidget {
  final String? socialId;

  const MainScreen({super.key, this.socialId});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String userName = "사용자";

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    if (widget.socialId == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.socialId!)
          .get();

      if (doc.exists) {
        final data = doc.data();
        setState(() {
          userName = data?['displayName'] ?? "사용자";
        });
      }
    } catch (e) {
      print("이름 불러오기 에러: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeTab(),
      _buildActivityTab(),
      _buildProfileTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "느티나무",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
            fontSize: 28,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            onPressed: () async {
              await AuthService().signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                      (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        color: Colors.grey.shade50,
        child: pages[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 16,
        unselectedFontSize: 14,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "홈"),
          BottomNavigationBarItem(icon: Icon(Icons.directions_run), label: "활동"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "내정보"),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    final int currentSteps = 0;
    final int goalSteps = 5000;
    final int myPoint = 0;
    final double progress = goalSteps == 0 ? 0 : currentSteps / goalSteps;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 인사
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "안녕하세요, $userName님!",
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.settings, color: Colors.black87),
                  onPressed: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 오늘의 걷기 목표 카드
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7E8),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "오늘의 걷기 목표",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  "$currentSteps / $goalSteps 걸음",
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: Colors.white,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF66BB6A)),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  currentSteps == 0
                      ? "운동을 시작하면 걸음 수가 기록돼요"
                      : "목표의 ${(progress * 100).toInt()}%를 달성했어요",
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 내 포인트 카드
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4D6),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.stars_rounded,
                    color: Colors.orange,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "내 포인트",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "$myPoint P",
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "운동과 걷기를 통해 포인트가 쌓여요",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 빠른 메뉴 2x2
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.05,
            children: [
              _buildQuickMenuCard(
                icon: Icons.directions_walk,
                iconColor: Colors.green,
                title: "운동 시작",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ExerciseScreen(),
                    ),
                  );
                },
              ),
              _buildQuickMenuCard(
                icon: Icons.map_outlined,
                iconColor: Colors.orange,
                title: "복지관 찾기",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WelfareCenterScreen(),
                    ),
                  );
                },
              ),
              _buildQuickMenuCard(
                icon: Icons.work_outline,
                iconColor: Colors.blue,
                title: "일자리 찾기",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const JobScreen(),
                    ),
                  );
                },
              ),
              _buildQuickMenuCard(
                icon: Icons.favorite_border,
                iconColor: Colors.red,
                title: "건강 기록",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HealthRecordScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSectionTitle("활동 추천"),
          _buildInfoCard(
            icon: Icons.sports_tennis,
            title: "배드민턴",
            subtitle: "기본 규칙과 자세를 쉽게 배워보세요.",
            onTap: () {},
          ),
          _buildInfoCard(
            icon: Icons.sports_golf,
            title: "골프",
            subtitle: "기초 스윙 방법과 준비 자세를 알려드려요.",
            onTap: () {},
          ),
          _buildInfoCard(
            icon: Icons.terrain,
            title: "등산",
            subtitle: "난이도별 코스와 주의사항을 확인해보세요.",
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSectionTitle("내 정보"),
          _buildInfoCard(
            icon: Icons.person_outline,
            title: "내 프로필",
            subtitle: "이름, 관심 분야, 활동 정보를 확인할 수 있어요.",
            onTap: () {},
          ),
          _buildInfoCard(
            icon: Icons.history,
            title: "활동 기록",
            subtitle: "내가 참여한 운동, 레저, 활동 내역을 볼 수 있어요.",
            onTap: () {},
          ),
          _buildInfoCard(
            icon: Icons.settings_outlined,
            title: "설정",
            subtitle: "알림, 계정, 앱 설정을 관리할 수 있어요.",
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      alignment: Alignment.centerLeft,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.green, size: 34),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMenuCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 42, color: iconColor),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseTabContent extends StatelessWidget {
  final String title;
  final List<String> items;

  const _ExerciseTabContent({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade50,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...items.map(
                (item) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.play_circle_fill, color: Colors.green, size: 32),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ExerciseScreen extends StatelessWidget {
  const ExerciseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "운동 시작",
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.black87),
          bottom: const TabBar(
            labelColor: Colors.green,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.green,
            tabs: [
              Tab(text: "스트레칭"),
              Tab(text: "걷기 운동"),
              Tab(text: "난이도별"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ExerciseTabContent(
              title: "스트레칭 운동",
              items: [
                "목과 어깨 스트레칭",
                "허리 풀기 운동",
                "무릎 관절 스트레칭",
              ],
            ),
            _ExerciseTabContent(
              title: "걷기 운동",
              items: [
                "실내 걷기 운동",
                "바른 자세 걷기",
                "10분 걷기 챌린지",
              ],
            ),
            _ExerciseTabContent(
              title: "난이도별 운동",
              items: [
                "초급 운동 프로그램",
                "중급 운동 프로그램",
                "고급 운동 프로그램",
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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

class HealthRecordScreen extends StatelessWidget {
  const HealthRecordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("건강 기록"),
        backgroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          "건강 기록 기능이 들어갈 화면입니다.",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}