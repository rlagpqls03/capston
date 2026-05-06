import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../theme/app_theme.dart';

class ExerciseScreen extends StatelessWidget {
  const ExerciseScreen({super.key});

  static const List<_ExerciseCategory> _categories = [
    _ExerciseCategory(
      title: '스트레칭 운동',
      items: [
        ExerciseVideoData(
          title: '목과 어깨 스트레칭',
          youtubeUrl: 'https://youtu.be/mUnSpfItRf0?si=wYHCGkFH6ew24dGz',
        ),
        ExerciseVideoData(
          title: '허리 풀기 운동',
          youtubeUrl: 'https://youtu.be/QhRcs9d2Y9E?si=5R-DkoRebp5v7Ps2',
        ),
        ExerciseVideoData(
          title: '무릎 관절 스트레칭',
          youtubeUrl: 'https://youtu.be/0orqUF-BSAU?si=qpbL8MpnQN4Gkb23',
        ),
      ],
    ),
    _ExerciseCategory(
      title: '낙상 예방 운동',
      items: [
        ExerciseVideoData(
          title: '낙상 예방 운동',
          youtubeUrl: 'https://youtu.be/pCyT7MWC_H4?si=fqUGiR5sevyZpVOu',
        ),
        ExerciseVideoData(
          title: '낙상 예방 밴드 운동',
          youtubeUrl: 'https://youtu.be/2iqLh4WR6gY?si=q8mTjXn0Ow26Ycob',
        ),
        ExerciseVideoData(
          title: '낙상 예방법',
          youtubeUrl: 'https://youtu.be/V9rHCOzzs6k?si=yjCRxya6-JxudtTf',
        ),
      ],
    ),
    _ExerciseCategory(
      title: '근력운동',
      items: [
        ExerciseVideoData(
          title: '기초 체력 기르기',
          youtubeUrl: 'https://youtu.be/5HWOgV9xQgM?si=KIgXaN15CaTbn1HG',
        ),
        ExerciseVideoData(
          title: '근육량 늘리기',
          youtubeUrl: 'https://youtu.be/S1B8uwgAzLc?si=NWS-ZzHL8TQ9zS-e',
        ),
        ExerciseVideoData(
          title: '하체 운동',
          youtubeUrl: 'https://youtu.be/VGjc4mach_U?si=kYfWH4Ph-xiLuBhS',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _categories.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '운동 시작',
            style: GoogleFonts.notoSansKr(
              color: AppColors.textMain,
              fontWeight: FontWeight.w900,
            ),
          ),
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.black87),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: '스트레칭'),
              Tab(text: '낙상 예방'),
              Tab(text: '근력운동'),
            ],
          ),
        ),
        body: TabBarView(
          children: _categories
              .map(
                (category) => _ExerciseTabContent(
                  title: category.title,
                  items: category.items,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _ExerciseTabContent extends StatelessWidget {
  final String title;
  final List<ExerciseVideoData> items;

  const _ExerciseTabContent({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _ExerciseHeroCard(title: title),
        const SizedBox(height: 18),
        ...items.map(
          (item) => _ExerciseListTile(video: item),
        ),
      ],
    );
  }
}

class _ExerciseHeroCard extends StatelessWidget {
  final String title;

  const _ExerciseHeroCard({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w900,
        color: AppColors.textMain,
      ),
    );
  }
}

class _ExerciseListTile extends StatelessWidget {
  final ExerciseVideoData video;

  const _ExerciseListTile({
    required this.video,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE3ECE4)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFFAFCFA),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFBCCDBF).withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ExerciseVideoPlayerScreen(video: video),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE7F7EB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_circle_fill_rounded,
                    color: AppColors.primaryDark,
                    size: 34,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    video.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textMain,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF8F1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ExerciseVideoPlayerScreen extends StatefulWidget {
  final ExerciseVideoData video;

  const ExerciseVideoPlayerScreen({
    super.key,
    required this.video,
  });

  @override
  State<ExerciseVideoPlayerScreen> createState() =>
      _ExerciseVideoPlayerScreenState();
}

class _ExerciseVideoPlayerScreenState extends State<ExerciseVideoPlayerScreen> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.video.youtubeVideoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        strictRelatedVideos: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  Future<void> _openOutside() async {
    final webUri = Uri.parse(widget.video.youtubeUrl);
    if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerScaffold(
      controller: _controller,
      aspectRatio: 16 / 9,
      builder: (context, player) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
              widget.video.title,
              style: const TextStyle(
                color: AppColors.textMain,
                fontWeight: FontWeight.w900,
              ),
            ),
            backgroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.black87),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFE3ECE4)),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFDFEFC),
                      Color(0xFFEFF8F1),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFBCCDBF).withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE7F7EB),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.ondemand_video_rounded,
                            color: AppColors.primaryDark,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            '운동 영상 재생',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textSub,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      widget.video.title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textMain,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: player,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _openOutside,
                icon: const Icon(Icons.open_in_new),
                label: const Text('유튜브 앱에서 열기'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ExerciseCategory {
  final String title;
  final List<ExerciseVideoData> items;

  const _ExerciseCategory({
    required this.title,
    required this.items,
  });
}

class ExerciseVideoData {
  final String title;
  final String youtubeUrl;

  const ExerciseVideoData({
    required this.title,
    required this.youtubeUrl,
  });

  String get youtubeVideoId {
    final uri = Uri.parse(youtubeUrl);
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
    }

    final videoId = uri.queryParameters['v'];
    if (videoId != null && videoId.isNotEmpty) {
      return videoId;
    }

    return '';
  }
}
