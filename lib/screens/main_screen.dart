import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'exercise_screen.dart';
import 'exercise_camera_screen.dart';
import 'hospital_finder_screen.dart';
import 'job_screen.dart';
import 'health_record_screen.dart';
import 'notification_screen.dart';
import 'point_notification_screen.dart';
import '../features/exercise_recommendation/exercise_recommendation_config.dart';
import '../utils/phone_utils.dart';
import '../widgets/home_app_bar_actions.dart';

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
            fontWeight: FontWeight.w900,
            color: Color(0xFF24C768),
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: _selectedIndex == 0
            ? [
                HomeBellActionButton(onPressed: _openNotificationScreen),
                const SizedBox(width: 8),
                const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: HomeTreeAvatarButton(),
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.grey),
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    await AuthService().signOut();
                    if (!mounted) return;
                    navigator.pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => LoginScreen()),
                      (route) => false,
                    );
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
                        Text(
                          '나의 포인트',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 18,
                            color: AppColors.textSub,
                            fontWeight: FontWeight.w900,
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
                childAspectRatio: compact ? 0.94 : 1.02,
                children: [
                  _buildQuickMenuCard(
                    icon: Icons.directions_walk_rounded,
                    iconColor: const Color(0xFF289A51),
                    title: '운동 시작',
                    subtitle: '',
                    accent: const Color(0xFFE7F7EB),
                    cardColors: const [
                      Color(0xFFFFFFFF),
                      Color(0xFFE7F7EB),
                    ],
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
                    title: '병원 찾기',
                    subtitle: '',
                    accent: const Color(0xFFE7F8F5),
                    cardColors: const [
                      Color(0xFFFFFFFF),
                      Color(0xFFE7F8F5),
                    ],
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
                    subtitle: '',
                    accent: const Color(0xFFF2ECFF),
                    cardColors: const [
                      Color(0xFFFFFFFF),
                      Color(0xFFF2ECFF),
                    ],
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
                    subtitle: '',
                    accent: const Color(0xFFFFEEE9),
                    cardColors: const [
                      Color(0xFFFFFFFF),
                      Color(0xFFFFEEE9),
                    ],
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
                  style: GoogleFonts.notoSansKr(
                    fontSize: 24,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '오늘도 건강한 하루 되세요!',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
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
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: _showFontSettingsSheet,
            child: Container(
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
          ),
        ],
      ),
    );
  }

  void _showFontSettingsSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return ValueListenableBuilder<double>(
          valueListenable: AppFontSettings.scale,
          builder: (context, fontScale, _) {
            return MediaQuery(
              data: MediaQuery.of(sheetContext).copyWith(
                textScaler: const TextScaler.linear(1.0),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '글자 크기 조절',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                final nextValue =
                                    (fontScale - 0.1).clamp(0.9, 1.4);
                                AppFontSettings.scale.value = nextValue;
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: const Text(
                                  '작게',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: AppColors.textSub,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Slider(
                              value: fontScale,
                              min: 0.9,
                              max: 1.4,
                              divisions: 5,
                              label: '${fontScale.toStringAsFixed(1)}배',
                              activeColor: AppColors.primary,
                              onChanged: (value) {
                                AppFontSettings.scale.value = value;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                final nextValue =
                                    (fontScale + 0.1).clamp(0.9, 1.4);
                                AppFontSettings.scale.value = nextValue;
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF9F0),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: const Text(
                                  '크게',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          child: const Text('확인'),
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
                Text(
                  '오늘의 추천 운동',
                  style: GoogleFonts.notoSansKr(
                    fontSize: 18,
                    color: AppColors.textMain,
                    fontWeight: FontWeight.w900,
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
            const SizedBox(height: 12),
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
                      exerciseSurveyCompleted ? '추천 운동 보기' : '3단계 문답으로 추천받기',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSub,
                        fontWeight: FontWeight.w900,
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
    required List<Color> cardColors,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final titleColor =
        Color.lerp(AppColors.textMain, iconColor, 0.42) ?? AppColors.textMain;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: _homeCardDecoration(
          colors: cardColors,
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.48),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: iconColor),
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: iconColor,
                  size: 20,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 22, bottom: 22),
                child: Text(
                  title,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: titleColor,
                    height: 1.2,
                  ),
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

    _openExerciseCamera(Map<String, dynamic>.from(exerciseRecommendation!));
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
              options = exerciseSeverityOptions;
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
                                          _openExerciseCamera(recommendation);
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

  void _openExerciseCamera(Map<String, dynamic> recommendation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExerciseCameraScreen(recommendation: recommendation),
      ),
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

  Widget _buildActivityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTabHeroCard(
            eyebrow: '',
            title: '가볍게 시작하는 활동 추천',
            description: '',
            icon: Icons.directions_run_rounded,
            accent: const Color(0xFFE8F7EC),
            iconColor: const Color(0xFF289A51),
          ),
          const SizedBox(height: 18),
          _buildInfoCard(
            icon: Icons.sports_tennis,
            title: '배드민턴',
            subtitle: '기본 규칙과 자세를 쉽게 배워보세요.',
            accent: const Color(0xFFE7F7EB),
            iconColor: const Color(0xFF289A51),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ActivityVideoListScreen(
                    title: '배드민턴',
                    description: '배드민턴 강의 영상을 보고 따라해 보세요.',
                    icon: Icons.sports_tennis,
                    accent: Color(0xFFE7F7EB),
                    iconColor: Color(0xFF289A51),
                    videos: [
                      ActivityVideoItem(
                        title: '배드민턴 강의 영상',
                        youtubeUrl:
                            'https://youtu.be/KharYkgsggk?si=eyGWoKnmrzaksFeK',
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          _buildInfoCard(
            icon: Icons.sports_golf,
            title: '골프',
            subtitle: '기초 스윙 방법과 준비 자세를 알려드려요.',
            accent: const Color(0xFFE9F8F6),
            iconColor: const Color(0xFF1E9A86),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ActivityVideoListScreen(
                    title: '골프',
                    description: '골프 강의 영상을 보고 차근차근 익혀보세요.',
                    icon: Icons.sports_golf,
                    accent: Color(0xFFE9F8F6),
                    iconColor: Color(0xFF1E9A86),
                    videos: [
                      ActivityVideoItem(
                        title: '골프 강의 영상',
                        youtubeUrl:
                            'https://youtu.be/v8azrl2h2-M?si=UeV8VquRyddxyMpv',
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          _buildInfoCard(
            icon: Icons.terrain,
            title: '등산',
            subtitle: '초보자 코스와 주의사항을 확인해 보세요.',
            accent: const Color(0xFFF4F1FF),
            iconColor: const Color(0xFF7B57D1),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BeginnerHikingScreen(),
                ),
              );
            },
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTabHeroCard(
            eyebrow: '나의 계정과 연결 정보',
            title: '내 정보를 한눈에 확인해 보세요',
            description: '프로필, 연결코드, 보호자 연동 상태를 깔끔하게 관리할 수 있어요.',
            icon: Icons.account_circle_rounded,
            accent: const Color(0xFFEAF9F0),
            iconColor: AppColors.primaryDark,
          ),
          const SizedBox(height: 18),
          _buildInfoCard(
            icon: Icons.person_outline,
            title: '내 프로필',
            subtitle: '이름, 생년월일, 성별, 전화번호를 확인할 수 있어요.',
            accent: const Color(0xFFEAF9F0),
            iconColor: AppColors.primaryDark,
            onTap: _showMyProfileDialog,
          ),
          if (isSenior)
            _buildInfoCard(
              icon: Icons.password_rounded,
              title: '내 연결코드',
              subtitle: hasConnectionCode
                  ? '현재 코드: $connectionCode'
                  : '아직 등록된 연결코드가 없어요.',
              accent: const Color(0xFFFFF2E9),
              iconColor: const Color(0xFFE16A56),
              onTap: hasConnectionCode ? _showConnectionCodeDialog : null,
            ),
          if (isGuardian)
            _buildInfoCard(
              icon: Icons.link_rounded,
              title: '코드 연결하기',
              subtitle: hasConnectedSenior
                  ? '연결됨: $connectedSeniorName ($connectedSeniorCode)'
                  : '어르신 연결코드를 입력해 연결해 주세요.',
              accent: const Color(0xFFF2ECFF),
              iconColor: const Color(0xFF7B57D1),
              onTap: _showGuardianCodeInputDialog,
            ),
          if (isGuardian && hasConnectedSenior)
            _buildInfoCard(
              icon: Icons.badge_outlined,
              title: '연결된 어르신 정보',
              subtitle: '연결된 어르신 개인정보를 확인할 수 있어요.',
              accent: const Color(0xFFE7F8F5),
              iconColor: const Color(0xFF1E9A86),
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
                fontWeight: FontWeight.w900,
                color: AppColors.textSub,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppColors.textMain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabHeroCard({
    required String eyebrow,
    required String title,
    required String description,
    required IconData icon,
    required Color accent,
    required Color iconColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: _homeCardDecoration(
        colors: const [
          Color(0xFFFDFEFC),
          Color(0xFFEFF8F1),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 34),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow.isNotEmpty) const SizedBox(height: 6),
                if (eyebrow.isNotEmpty)
                  Text(
                    eyebrow,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSub,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textMain,
                  ),
                ),
                if (description.isNotEmpty) const SizedBox(height: 8),
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: AppColors.textSub,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
        decoration: _homeCardDecoration(
          colors: const [
            Color(0xFFFFFFFF),
            Color(0xFFFAFCFA),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: AppColors.textSub,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ActivityVideoListScreen extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final Color iconColor;
  final List<ActivityVideoItem> videos;

  const ActivityVideoListScreen({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.iconColor,
    required this.videos,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 34),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          height: 1.2,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: AppColors.textSub,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ...videos.map(
            (video) => _ActivityVideoCard(
              title: video.title,
              youtubeUrl: video.youtubeUrl,
              accent: accent,
              iconColor: iconColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityVideoCard extends StatelessWidget {
  final String title;
  final String youtubeUrl;
  final Color accent;
  final Color iconColor;

  const _ActivityVideoCard({
    required this.title,
    required this.youtubeUrl,
    required this.accent,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExerciseVideoPlayerScreen(
              video: ExerciseVideoData(
                title: title,
                youtubeUrl: youtubeUrl,
              ),
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
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
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_circle_fill_rounded,
                color: iconColor,
                size: 34,
              ),
            ),
            const SizedBox(width: 16),
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
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ActivityVideoItem {
  final String title;
  final String youtubeUrl;

  const ActivityVideoItem({
    required this.title,
    required this.youtubeUrl,
  });
}

class BeginnerHikingScreen extends StatefulWidget {
  const BeginnerHikingScreen({super.key});

  @override
  State<BeginnerHikingScreen> createState() => _BeginnerHikingScreenState();
}

class _BeginnerHikingScreenState extends State<BeginnerHikingScreen> {
  static const List<BeginnerHikingCourse> _courses = [
    BeginnerHikingCourse(
      name: '남산',
      courseTitle: '남산 순환 초보 코스',
      summary: '계단이 많지 않고 산책하듯 걷기 좋아요.',
      difficulty: '쉬움',
      duration: '40분',
      location: '서울 중구',
      latLng: LatLng(37.5512, 126.9882),
    ),
    BeginnerHikingCourse(
      name: '아차산',
      courseTitle: '아차산 입구 초보 코스',
      summary: '짧게 오르기 좋고 전망 보는 재미가 있어요.',
      difficulty: '쉬움',
      duration: '50분',
      location: '서울 광진구',
      latLng: LatLng(37.5662, 127.1031),
    ),
    BeginnerHikingCourse(
      name: '인왕산',
      courseTitle: '인왕산 초입 완만 코스',
      summary: '완만한 구간 위주로 천천히 오르기 좋아요.',
      difficulty: '보통',
      duration: '60분',
      location: '서울 종로구',
      latLng: LatLng(37.5804, 126.9604),
    ),
  ];

  GoogleMapController? _mapController;
  int _selectedIndex = 0;

  BeginnerHikingCourse get _selectedCourse => _courses[_selectedIndex];

  Set<Marker> get _markers {
    return _courses
        .map(
          (course) => Marker(
            markerId: MarkerId(course.name),
            position: course.latLng,
            infoWindow: InfoWindow(
              title: course.name,
              snippet: course.courseTitle,
            ),
            onTap: () {
              final index = _courses.indexOf(course);
              if (index != -1) {
                _selectCourse(index);
              }
            },
          ),
        )
        .toSet();
  }

  Future<void> _selectCourse(int index) async {
    setState(() => _selectedIndex = index);
    final course = _courses[index];
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: course.latLng, zoom: 13.8),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCourse = _selectedCourse;

    return Scaffold(
      appBar: AppBar(
        title: const Text('초보자용 코스'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8FBF8),
              Color(0xFFF1F6F2),
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFE3ECE4)),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFFFFF),
                    Color(0xFFF1ECFF),
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF2ECFF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.terrain_rounded,
                      color: Color(0xFF7B57D1),
                      size: 34,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '초보자용 등산 코스',
                          style: TextStyle(
                            fontSize: 24,
                            height: 1.2,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textMain,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '가고 싶은 산을 고르면 지도와 코스를 함께 볼 수 있어요.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textSub,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _courses.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final course = _courses[index];
                  final selected = index == _selectedIndex;
                  return ChoiceChip(
                    selected: selected,
                    label: Text(
                      course.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: selected ? Colors.white : AppColors.textMain,
                      ),
                    ),
                    selectedColor: const Color(0xFF7B57D1),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onSelected: (_) => _selectCourse(index),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: SizedBox(
                height: 250,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: selectedCourse.latLng,
                    zoom: 13.2,
                  ),
                  markers: _markers,
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                  onMapCreated: (controller) => _mapController = controller,
                ),
              ),
            ),
            const SizedBox(height: 18),
            ...List.generate(
              _courses.length,
              (index) {
                final course = _courses[index];
                final selected = index == _selectedIndex;
                return _BeginnerHikingCourseCard(
                  course: course,
                  selected: selected,
                  onTap: () => _selectCourse(index),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BeginnerHikingCourseCard extends StatelessWidget {
  final BeginnerHikingCourse course;
  final bool selected;
  final VoidCallback onTap;

  const _BeginnerHikingCourseCard({
    required this.course,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: selected ? const Color(0xFF7B57D1) : const Color(0xFFE3ECE4),
          width: selected ? 2 : 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: selected
              ? const [
                  Color(0xFFFFFFFF),
                  Color(0xFFF4F0FF),
                ]
              : const [
                  Color(0xFFFFFFFF),
                  Color(0xFFFAFCFA),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFBCCDBF).withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
            child: Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFEDE5FF)
                        : const Color(0xFFF2ECFF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.landscape_rounded,
                    color: Color(0xFF7B57D1),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.courseTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        course.summary,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textSub,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _HikingInfoChip(label: course.location),
                          _HikingInfoChip(label: '난이도 ${course.difficulty}'),
                          _HikingInfoChip(label: '${course.duration} 코스'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFEDE5FF)
                        : const Color(0xFFF2ECFF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF7B57D1),
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

class _HikingInfoChip extends StatelessWidget {
  final String label;

  const _HikingInfoChip({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE3ECE4)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: AppColors.textSub,
        ),
      ),
    );
  }
}

class BeginnerHikingCourse {
  final String name;
  final String courseTitle;
  final String summary;
  final String difficulty;
  final String duration;
  final String location;
  final LatLng latLng;

  const BeginnerHikingCourse({
    required this.name,
    required this.courseTitle,
    required this.summary,
    required this.difficulty,
    required this.duration,
    required this.location,
    required this.latLng,
  });
}
