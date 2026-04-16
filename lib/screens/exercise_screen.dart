import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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
              color: AppColors.textMain,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.black87),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
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
                  const Icon(Icons.play_circle_fill, color: AppColors.primary, size: 32),
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
