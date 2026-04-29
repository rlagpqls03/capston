import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../models/home_search_item.dart';
import 'login_screen.dart';
import 'exercise_screen.dart';
import 'hospital_finder_screen.dart';
import 'job_screen.dart';
import 'health_record_screen.dart';
import 'notification_screen.dart';
import 'point_notification_screen.dart';
import '../features/exercise_recommendation/exercise_recommendation_config.dart';
import '../utils/phone_utils.dart';
import '../widgets/home_app_bar_actions.dart';
import '../widgets/home_menu_search_delegate.dart';

class MainScreen extends StatefulWidget {
  final String? socialId;

  const MainScreen({super.key, this.socialId});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _selectedIndex = 0;
  String userName = '이름';
  String userRole = '';
  String userGender = '';
  String userBirthDate = '';
  String userPhone = '';
  String connectionCode = '';
  String connectedSeniorCode = '';
  String connectedSeniorName = '';
  String connectedSeniorId = '';
  bool exerciseSurveyCompleted = false;
  Map<String, dynamic>? exerciseRecommendation;

  String _normalizeUserName(dynamic name, dynamic displayName) {
    final candidates = [
      (name ?? '').toString().trim(),
      (displayName ?? '').toString().trim(),
    ];
    for (final c in candidates) {
      if (c.isNotEmpty && c != '사용자') return c;
    }
    return '이름';
  }

  String _recommendationTitle() {
    final title = (exerciseRecommendation?['title'] ?? '').toString();
    if (title.trim().isEmpty) return '오늘의 추천 운동을 받아보세요';
    return title;
  }

  String _recommendationSummary() {
    final summary = (exerciseRecommendation?['summary'] ?? '').toString();
    if (summary.trim().isEmpty) return '통증 문답을 통해 맞춤 운동을 추천해 드려요.';
    return summary;
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    if (widget.socialId == null) return;

    try {
      final doc =
          await _firestore.collection('users').doc(widget.socialId!).get();

      if (doc.exists) {
        final data = doc.data();
        if (!mounted) return;
        setState(() {
          userName = _normalizeUserName(data?['name'], data?['displayName']);
          userRole = (data?['role'] ?? '').toString();
          userGender = (data?['gender'] ?? '').toString();
          userBirthDate = (data?['birthDate'] ?? '').toString();
          userPhone =
              PhoneUtils.formatKoreanPhone((data?['phone'] ?? '').toString());
          connectionCode = (data?['connectionCode'] ?? '').toString();
          connectedSeniorCode = (data?['connectedSeniorCode'] ?? '').toString();
          connectedSeniorName = (data?['connectedSeniorName'] ?? '').toString();
          connectedSeniorId = (data?['connectedSeniorId'] ?? '').toString();
          final rawRecommendation = data?['exerciseRecommendation'];
          if (rawRecommendation is Map) {
            exerciseRecommendation =
                Map<String, dynamic>.from(rawRecommendation);
          } else {
            exerciseRecommendation = null;
          }
          exerciseSurveyCompleted =
              (data?['exerciseSurveyCompleted'] == true) ||
                  exerciseRecommendation != null;
        });
      }
    } catch (e) {
      debugPrint('사용자 정보 로딩 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeTab(),
      _buildActivityTab(),
      JobScreen(socialId: widget.socialId),
      _buildProfileTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '느티나무',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF24C768),
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: _selectedIndex == 0
            ? [
                HomeSearchActionButton(onPressed: _openHomeSearch),
                const SizedBox(width: 8),
                HomeBellActionButton(onPressed: _openNotificationScreen),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: const HomeTreeAvatarButton(),
                ),
              ]
            : [
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
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSub,
        selectedFontSize: 16,
        unselectedFontSize: 14,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(
              icon: Icon(Icons.directions_run), label: '활동'),
          BottomNavigationBarItem(icon: Icon(Icons.work_outline), label: '구직'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '내 정보'),
        ],
      ),
    );
  }

  List<HomeSearchItem> get _homeSearchItems => const [
        HomeSearchItem(
          title: '추천 운동 받기',
          subtitle: '오늘의 추천 운동 카드로 이동',
          keywords: ['추천운동', '운동 추천', '문답', '운동'],
          type: HomeSearchType.recommendation,
        ),
        HomeSearchItem(
          title: '운동 시작',
          subtitle: '운동 화면 열기',
          keywords: ['운동', '활동', '걷기'],
          type: HomeSearchType.exercise,
        ),
        HomeSearchItem(
          title: '병원찾기',
          subtitle: '주변 병원 찾기',
          keywords: ['병원', '의원', '지도', '위치'],
          type: HomeSearchType.hospital,
        ),
        HomeSearchItem(
          title: '일자리 찾기',
          subtitle: '구직 정보 확인',
          keywords: ['구직', '일자리', '취업', '채용'],
          type: HomeSearchType.job,
        ),
        HomeSearchItem(
          title: '건강 기록',
          subtitle: '건강 기록 화면 열기',
          keywords: ['건강', '기록', '증상'],
          type: HomeSearchType.health,
        ),
        HomeSearchItem(
          title: '포인트 적립',
          subtitle: '포인트 적립 안내 화면 열기',
          keywords: ['포인트', '적립', '알림', '보상'],
          type: HomeSearchType.point,
        ),
        HomeSearchItem(
          title: '활동 탭',
          subtitle: '활동 추천 탭으로 이동',
          keywords: ['활동', '배드민턴', '골프', '등산'],
          type: HomeSearchType.activityTab,
        ),
        HomeSearchItem(
          title: '내 정보',
          subtitle: '프로필 탭으로 이동',
          keywords: ['내정보', '프로필', '정보'],
          type: HomeSearchType.profileTab,
        ),
      ];

  Future<void> _openHomeSearch() async {
    final selected = await showSearch<HomeSearchItem?>(
      context: context,
      delegate: HomeMenuSearchDelegate(items: _homeSearchItems),
    );

    if (!mounted || selected == null) return;
    _handleHomeSearchSelection(selected);
  }

  void _openPointNotification() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PointNotificationScreen()),
    );
  }

  void _openNotificationScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationScreen()),
    );
  }

  void _handleHomeSearchSelection(HomeSearchItem item) {
    switch (item.type) {
      case HomeSearchType.recommendation:
        _handleTodayExerciseCardTap();
        return;
      case HomeSearchType.exercise:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ExerciseScreen()),
        );
        return;
      case HomeSearchType.hospital:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HospitalFinderScreen()),
        );
        return;
      case HomeSearchType.job:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => JobScreen(socialId: widget.socialId),
          ),
        );
        return;
      case HomeSearchType.health:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HealthRecordScreen()),
        );
        return;
      case HomeSearchType.point:
        _openPointNotification();
        return;
      case HomeSearchType.activityTab:
        setState(() => _selectedIndex = 1);
        return;
      case HomeSearchType.profileTab:
        setState(() => _selectedIndex = 3);
        return;
    }
  }

  Widget _buildHomeTab() {
    const int myPoint = 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHomeGreeting(),
          const SizedBox(height: 16),
          _buildTodayExerciseCard(),
          const SizedBox(height: 16),
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: _openPointNotification,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: _homeCardDecoration(
                colors: const [
                  Color(0xFFFCFEFC),
                  Color(0xFFF2FBF4),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE1EEE5),
                        width: 8,
                      ),
                      color: Colors.white,
                    ),
                    child: const Icon(
                      Icons.stars_rounded,
                      color: AppColors.primary,
                      size: 36,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '나의 포인트',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.textSub,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$myPoint P',
                          style: const TextStyle(
                            fontSize: 36,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '활동으로 포인트를 모아보세요.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSub,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 42,
                    height: 42,
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
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 360;
              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: compact ? 0.72 : 0.80,
                children: [
                  _buildQuickMenuCard(
                    icon: Icons.directions_walk_rounded,
                    iconColor: const Color(0xFF289A51),
                    title: '운동 시작',
                    subtitle: '오늘의 운동을\n시작해 보세요',
                    accent: const Color(0xFFE7F7EB),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ExerciseScreen()),
                      );
                    },
                  ),
                  _buildQuickMenuCard(
                    icon: Icons.local_hospital_outlined,
                    iconColor: const Color(0xFF1E9A86),
                    title: '병원찾기',
                    subtitle: '내 주변 병원을\n찾아보세요',
                    accent: const Color(0xFFE7F8F5),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HospitalFinderScreen(),
                        ),
                      );
                    },
                  ),
                  _buildQuickMenuCard(
                    icon: Icons.work_outline_rounded,
                    iconColor: const Color(0xFF7B57D1),
                    title: '일자리 찾기',
                    subtitle: '다양한 일자리를\n확인해 보세요',
                    accent: const Color(0xFFF2ECFF),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => JobScreen(socialId: widget.socialId),
                        ),
                      );
                    },
                  ),
                  _buildQuickMenuCard(
                    icon: Icons.favorite_border_rounded,
                    iconColor: const Color(0xFFE16A56),
                    title: '건강 기록',
                    subtitle: '나의 건강 기록을\n관리해 보세요',
                    accent: const Color(0xFFFFEEE9),
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
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHomeGreeting() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '안녕하세요, $userName 님',
                  style: const TextStyle(
                    fontSize: 24,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Expanded(
                      child: Text(
                        '오늘도 건강한 하루 되세요!',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSub,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.eco_rounded,
                      size: 22,
                      color: Color(0xFF8CC63E),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE6ECE6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.settings_outlined,
              color: AppColors.textMain,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _homeCardDecoration({
    required List<Color> colors,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: const Color(0xFFE3ECE4)),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFBCCDBF).withValues(alpha: 0.18),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  Widget _buildTodayExerciseCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: _handleTodayExerciseCardTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        decoration: _homeCardDecoration(
          colors: const [
            Color(0xFFFDFEFC),
            Color(0xFFEFF8F1),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.health_and_safety_outlined,
                    color: AppColors.primaryDark, size: 28),
                const SizedBox(width: 8),
                const Text(
                  '오늘의 추천 운동',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.textMain,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Icon(
                  exerciseSurveyCompleted
                      ? Icons.check_circle
                      : Icons.chevron_right_rounded,
                  color: exerciseSurveyCompleted
                      ? AppColors.primary
                      : AppColors.textSub,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _recommendationTitle(),
              style: const TextStyle(
                fontSize: 24,
                height: 1.2,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _recommendationSummary(),
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSub,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.74),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      exerciseSurveyCompleted
                          ? '추천 운동과 영상을 확인해 보세요.'
                          : '처음 3단계 문답으로 맞춤 운동을 추천해 드려요.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSub,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMenuCard({
    required IconData icon,
    required Color iconColor,
    required Color accent,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 14, 14),
        decoration: _homeCardDecoration(
          colors: const [
            Color(0xFFFFFFFF),
            Color(0xFFFAFCFA),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: iconColor),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                color: AppColors.textSub,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: iconColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTodayExerciseCardTap() async {
    if (widget.socialId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 후 이용할 수 있어요.')),
      );
      return;
    }

    if (!exerciseSurveyCompleted || exerciseRecommendation == null) {
      await _showExerciseSurveySheet();
      return;
    }

    _showExerciseRecommendationDialog(
        Map<String, dynamic>.from(exerciseRecommendation!));
  }

  Future<void> _showExerciseSurveySheet() async {
    int step = 0;
    String? primary;
    String? detail;
    bool isSaving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            String question = '어디가 가장 불편하세요?';
            List<String> options = exerciseDetailOptions.keys.toList();

            if (step == 1) {
              question = '$primary 증상 중 가장 가까운 것을 선택해 주세요.';
              options = exerciseDetailOptions[primary] ?? [];
            } else if (step == 2) {
              question = '불편함 정도는 어느 정도인가요?';
              options = ['가벼운 편이에요', '중간 정도예요', '심한 편이에요'];
            }

            return SafeArea(
              child: SizedBox(
                height: 560,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '추천 운동 문답 ${step + 1}/3',
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textSub,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        question,
                        style: const TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textMain,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: ListView.separated(
                          itemCount: options.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, index) {
                            final option = options[index];
                            return _surveyChoiceButton(
                              label: option,
                              onTap: isSaving
                                  ? null
                                  : () async {
                                      if (step == 0) {
                                        setSheetState(() {
                                          primary = option;
                                          detail = null;
                                          step = 1;
                                        });
                                        return;
                                      }

                                      if (step == 1) {
                                        setSheetState(() {
                                          detail = option;
                                          step = 2;
                                        });
                                        return;
                                      }

                                      setSheetState(() => isSaving = true);
                                      try {
                                        final recommendation =
                                            buildExerciseRecommendation(
                                          primary: primary ?? '전신 피로',
                                          detail: detail ?? '몸이 무겁고 무기력해요',
                                          severity: option,
                                        );
                                        await _saveExerciseRecommendation(
                                            recommendation);
                                        if (sheetContext.mounted) {
                                          Navigator.pop(sheetContext);
                                        }
                                        if (mounted) {
                                          _showExerciseRecommendationDialog(
                                              recommendation);
                                        }
                                      } catch (e) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text('추천 저장 실패: $e')),
                                        );
                                        if (sheetContext.mounted) {
                                          setSheetState(() => isSaving = false);
                                        }
                                      }
                                    },
                            );
                          },
                        ),
                      ),
                      if (isSaving)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: CircularProgressIndicator(
                                color: AppColors.primary),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _surveyChoiceButton({
    required String label,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.6),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 21,
                  color: AppColors.textMain,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSub),
          ],
        ),
      ),
    );
  }

  Future<void> _saveExerciseRecommendation(
      Map<String, dynamic> recommendation) async {
    if (widget.socialId == null) return;
    await _firestore.collection('users').doc(widget.socialId!).set({
      'exerciseSurveyCompleted': true,
      'exerciseRecommendation': recommendation,
      'exerciseRecommendationUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;
    setState(() {
      exerciseSurveyCompleted = true;
      exerciseRecommendation = recommendation;
    });
  }

  void _showExerciseRecommendationDialog(Map<String, dynamic> recommendation) {
    final title = (recommendation['title'] ?? '추천 운동').toString();
    final summary = (recommendation['summary'] ?? '').toString();
    final reason = (recommendation['reason'] ?? '').toString();
    final videoLink = (recommendation['videoLink'] ?? '').toString();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('오늘의 맞춤 운동'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                summary,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text(
                reason,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSub,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                '추천 영상 링크',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                videoLink.isEmpty ? '영상 링크는 추후 연결 예정입니다.' : videoLink,
                style: const TextStyle(fontSize: 14, color: AppColors.textSub),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _showExerciseSurveySheet();
            },
            child: const Text('다시 조사하기'),
          ),
          if (videoLink.isNotEmpty)
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: videoLink));
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('영상 링크를 복사했어요.')),
                );
              },
              child: const Text('링크 복사'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
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
          _buildSectionTitle('활동 추천'),
          _buildInfoCard(
            icon: Icons.sports_tennis,
            title: '배드민턴',
            subtitle: '기본 규칙과 자세를 쉽게 배워보세요.',
            onTap: () {},
          ),
          _buildInfoCard(
            icon: Icons.sports_golf,
            title: '골프',
            subtitle: '기초 스윙 방법과 준비 자세를 알려드려요.',
            onTap: () {},
          ),
          _buildInfoCard(
            icon: Icons.terrain,
            title: '등산',
            subtitle: '초보자 코스와 주의사항을 확인해 보세요.',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    final bool isSenior = userRole == '어르신';
    final bool isGuardian = userRole == '보호자';
    final bool hasConnectionCode = connectionCode.trim().isNotEmpty;
    final bool hasConnectedSenior = connectedSeniorCode.trim().isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSectionTitle('내 정보'),
          _buildInfoCard(
            icon: Icons.person_outline,
            title: '내 프로필',
            subtitle: '이름, 생년월일, 성별, 전화번호를 확인할 수 있어요.',
            onTap: _showMyProfileDialog,
          ),
          if (isSenior)
            _buildInfoCard(
              icon: Icons.password_rounded,
              title: '내 연결코드',
              subtitle: hasConnectionCode
                  ? '현재 코드: $connectionCode'
                  : '아직 등록된 연결코드가 없어요.',
              onTap: hasConnectionCode ? _showConnectionCodeDialog : null,
            ),
          if (isGuardian)
            _buildInfoCard(
              icon: Icons.link_rounded,
              title: '코드 연결하기',
              subtitle: hasConnectedSenior
                  ? '연결됨: $connectedSeniorName ($connectedSeniorCode)'
                  : '어르신 연결코드를 입력해 연결해 주세요.',
              onTap: _showGuardianCodeInputDialog,
            ),
          if (isGuardian && hasConnectedSenior)
            _buildInfoCard(
              icon: Icons.badge_outlined,
              title: '연결된 어르신 정보',
              subtitle: '연결된 어르신 개인정보를 확인할 수 있어요.',
              onTap: _showConnectedSeniorProfileDialog,
            ),
        ],
      ),
    );
  }

  void _showMyProfileDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('내 프로필'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _profileInfoRow('이름', userName.trim().isEmpty ? '미등록' : userName),
            _profileInfoRow('역할', userRole.trim().isEmpty ? '미등록' : userRole),
            _profileInfoRow(
                '생년월일', userBirthDate.trim().isEmpty ? '미등록' : userBirthDate),
            _profileInfoRow(
                '성별', userGender.trim().isEmpty ? '미등록' : userGender),
            _profileInfoRow(
                '전화번호', userPhone.trim().isEmpty ? '미등록' : userPhone),
            if (userRole == '어르신')
              _profileInfoRow('내 연결코드',
                  connectionCode.trim().isEmpty ? '미등록' : connectionCode),
            if (userRole == '보호자')
              _profileInfoRow(
                  '연결된 코드',
                  connectedSeniorCode.trim().isEmpty
                      ? '미등록'
                      : connectedSeniorCode),
            if (userRole == '보호자')
              _profileInfoRow(
                  '연결된 어르신',
                  connectedSeniorName.trim().isEmpty
                      ? '미등록'
                      : connectedSeniorName),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _showConnectionCodeDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('내 연결코드'),
        content: Text(
          connectionCode,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 36,
            letterSpacing: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _showGuardianCodeInputDialog() {
    final controller = TextEditingController(text: connectedSeniorCode);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('어르신 코드 연결'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '어르신 연결코드 6자리를 입력해 주세요.',
              style: TextStyle(fontSize: 15, color: AppColors.textSub),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: const InputDecoration(
                hintText: '예: 123456',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              final code = controller.text.trim();
              Navigator.pop(dialogContext);
              await _connectGuardianByCode(code);
            },
            child: const Text('연결'),
          ),
        ],
      ),
    );
  }

  Future<void> _connectGuardianByCode(String code) async {
    if (widget.socialId == null || userRole != '보호자') return;

    if (code.length != 6) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('연결코드 6자리를 입력해 주세요.')),
      );
      return;
    }

    try {
      final query = await _firestore
          .collection('users')
          .where('connectionCode', isEqualTo: code)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('일치하는 연결코드를 찾지 못했어요.')),
        );
        return;
      }

      final seniorDoc = query.docs.first;
      final seniorData = seniorDoc.data();
      final seniorRole = (seniorData['role'] ?? '').toString();
      if (seniorRole != '어르신') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('어르신 계정 코드만 연결할 수 있어요.')),
        );
        return;
      }

      final seniorName =
          _normalizeUserName(seniorData['name'], seniorData['displayName']);

      await _firestore.collection('users').doc(widget.socialId!).set({
        'connectedSeniorCode': code,
        'connectedSeniorId': seniorDoc.id,
        'connectedSeniorName': seniorName,
        'connectedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() {
        connectedSeniorCode = code;
        connectedSeniorId = seniorDoc.id;
        connectedSeniorName = seniorName;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$seniorName 님과 연결되었어요.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('연결 실패: $e')),
      );
    }
  }

  Future<void> _showConnectedSeniorProfileDialog() async {
    if (userRole != '보호자') return;
    if (connectedSeniorId.trim().isEmpty &&
        connectedSeniorCode.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 어르신 코드를 연결해 주세요.')),
      );
      return;
    }

    try {
      DocumentSnapshot<Map<String, dynamic>>? seniorDoc;

      if (connectedSeniorId.trim().isNotEmpty) {
        final doc = await _firestore
            .collection('users')
            .doc(connectedSeniorId.trim())
            .get();
        if (doc.exists) seniorDoc = doc;
      }

      if (seniorDoc == null) {
        final query = await _firestore
            .collection('users')
            .where('connectionCode', isEqualTo: connectedSeniorCode.trim())
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          seniorDoc = query.docs.first;
        }
      }

      if (seniorDoc == null || !seniorDoc.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('연결된 어르신 정보를 찾지 못했어요.')),
        );
        return;
      }

      final data = seniorDoc.data() ?? <String, dynamic>{};
      final seniorRole = (data['role'] ?? '').toString();
      if (seniorRole != '어르신') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('연결된 대상이 어르신 계정이 아니에요.')),
        );
        return;
      }

      final seniorName = _normalizeUserName(data['name'], data['displayName']);
      final seniorBirthDate = (data['birthDate'] ?? '').toString();
      final seniorGender = (data['gender'] ?? '').toString();
      final seniorPhone =
          PhoneUtils.formatKoreanPhone((data['phone'] ?? '').toString());
      final seniorConnectionCode = (data['connectionCode'] ?? '').toString();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('연결된 어르신 정보'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _profileInfoRow('이름', seniorName.isEmpty ? '미등록' : seniorName),
              _profileInfoRow(
                  '생년월일', seniorBirthDate.isEmpty ? '미등록' : seniorBirthDate),
              _profileInfoRow(
                  '성별', seniorGender.isEmpty ? '미등록' : seniorGender),
              _profileInfoRow(
                  '전화번호', seniorPhone.isEmpty ? '미등록' : seniorPhone),
              _profileInfoRow('연결코드',
                  seniorConnectionCode.isEmpty ? '미등록' : seniorConnectionCode),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('어르신 정보 조회 실패: $e')),
      );
    }
  }

  Widget _profileInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textSub,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              ),
            ),
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
            Icon(icon, color: AppColors.primary, size: 34),
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
}
