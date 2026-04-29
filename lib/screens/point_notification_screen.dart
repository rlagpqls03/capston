import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PointNotificationScreen extends StatelessWidget {
  const PointNotificationScreen({super.key});

  static const List<_PointHistoryItem> _historyItems = [
    _PointHistoryItem(
      title: '오늘의 운동 완료',
      date: '2026.04.29',
      description: '추천 운동 1회를 완료했어요.',
      point: '+30P',
      icon: Icons.directions_walk_rounded,
    ),
    _PointHistoryItem(
      title: '건강 기록 작성',
      date: '2026.04.28',
      description: '허리 통증 관련 건강 기록을 남겼어요.',
      point: '+20P',
      icon: Icons.edit_note_rounded,
    ),
    _PointHistoryItem(
      title: '병원 방문 체크',
      date: '2026.04.27',
      description: '주변 병원 방문 기록이 저장되었어요.',
      point: '+15P',
      icon: Icons.location_on_outlined,
    ),
    _PointHistoryItem(
      title: '연속 참여 보너스',
      date: '2026.04.27',
      description: '3일 연속 앱 활동으로 보너스를 받았어요.',
      point: '+50P',
      icon: Icons.emoji_events_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('포인트 적립'),
      ),
      body: const _PointBody(historyItems: _historyItems),
    );
  }
}

class _PointBody extends StatelessWidget {
  final List<_PointHistoryItem> historyItems;

  const _PointBody({
    required this.historyItems,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const _PointHeroCard(),
        const SizedBox(height: 16),
        const _PointInfoCard(
          icon: Icons.directions_walk_rounded,
          title: '오늘의 운동 완료',
          description: '추천 운동이나 활동 운동을 완료하면 포인트를 받을 수 있어요.',
          reward: '+30P',
        ),
        const SizedBox(height: 12),
        const _PointInfoCard(
          icon: Icons.edit_note_rounded,
          title: '건강 기록 작성',
          description: '몸 상태와 증상을 기록하면 건강 관리 포인트가 적립돼요.',
          reward: '+20P',
        ),
        const SizedBox(height: 12),
        const _PointInfoCard(
          icon: Icons.location_on_outlined,
          title: '병원 방문 체크',
          description: '주변 병원을 찾고 방문 기록을 남기면 추가 포인트를 받을 수 있어요.',
          reward: '+15P',
        ),
        const SizedBox(height: 12),
        const _PointInfoCard(
          icon: Icons.emoji_events_outlined,
          title: '연속 참여 보너스',
          description: '3일 연속으로 앱 활동을 하면 보너스 포인트가 적립돼요.',
          reward: '+50P',
        ),
        const SizedBox(height: 22),
        _PointHistorySection(historyItems: historyItems),
      ],
    );
  }
}

class _PointHistoryItem {
  final String title;
  final String date;
  final String description;
  final String point;
  final IconData icon;

  const _PointHistoryItem({
    required this.title,
    required this.date,
    required this.description,
    required this.point,
    required this.icon,
  });
}

class _PointHistorySection extends StatelessWidget {
  final List<_PointHistoryItem> historyItems;

  const _PointHistorySection({
    required this.historyItems,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '최근 적립 내역',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 12),
        ...historyItems.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PointHistoryCard(item: item),
          ),
        ),
      ],
    );
  }
}

class _PointHistoryCard extends StatelessWidget {
  final _PointHistoryItem item;

  const _PointHistoryCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFF4FBF6),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: AppColors.primary, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textMain,
                        ),
                      ),
                    ),
                    Text(
                      item.point,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.date,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSub,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.textSub,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PointHeroCard extends StatelessWidget {
  const _PointHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF0FAF2),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: AppColors.primary,
              size: 36,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '포인트 적립 안내',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMain,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '앱에서 운동, 기록, 방문 활동을 하면 포인트가 쌓여요.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    color: AppColors.textSub,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PointInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String reward;

  const _PointInfoCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.reward,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFFF4FBF6),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textMain,
                        ),
                      ),
                    ),
                    Text(
                      reward,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: AppColors.textSub,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
