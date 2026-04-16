import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'exercise_screen.dart';
import 'welfare_center_screen.dart';
import 'job_screen.dart';
import 'health_record_screen.dart';
import '../features/exercise_recommendation/exercise_recommendation_config.dart';
import '../utils/phone_utils.dart';

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
      final doc = await _firestore
          .collection('users')
          .doc(widget.socialId!)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (!mounted) return;
        setState(() {
          userName = _normalizeUserName(data?['name'], data?['displayName']);
          userRole = (data?['role'] ?? '').toString();
          userGender = (data?['gender'] ?? '').toString();
          userBirthDate = (data?['birthDate'] ?? '').toString();
          userPhone = PhoneUtils.formatKoreanPhone((data?['phone'] ?? '').toString());
          connectionCode = (data?['connectionCode'] ?? '').toString();
          connectedSeniorCode = (data?['connectedSeniorCode'] ?? '').toString();
          connectedSeniorName = (data?['connectedSeniorName'] ?? '').toString();
          connectedSeniorId = (data?['connectedSeniorId'] ?? '').toString();
          final rawRecommendation = data?['exerciseRecommendation'];
          if (rawRecommendation is Map) {
            exerciseRecommendation = Map<String, dynamic>.from(rawRecommendation);
          } else {
            exerciseRecommendation = null;
          }
          exerciseSurveyCompleted = (data?['exerciseSurveyCompleted'] == true) || exerciseRecommendation != null;
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
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSub,
        selectedFontSize: 16,
        unselectedFontSize: 14,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_run), label: '활동'),
          BottomNavigationBarItem(icon: Icon(Icons.work_outline), label: '구직'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '내 정보'),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    const int myPoint = 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '안녕하세요, $userName 님',
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
          _buildTodayExerciseCard(),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.stars_rounded,
                    color: AppColors.primary,
                    size: 32,
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
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$myPoint P',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '활동으로 포인트를 모아보세요.',
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
                iconColor: AppColors.primary,
                title: '운동 시작',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ExerciseScreen()),
                  );
                },
              ),
              _buildQuickMenuCard(
                icon: Icons.map_outlined,
                iconColor: AppColors.primary,
                title: '복지관 찾기',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WelfareCenterScreen()),
                  );
                },
              ),
              _buildQuickMenuCard(
                icon: Icons.work_outline,
                iconColor: AppColors.primaryDark,
                title: '일자리 찾기',
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
                icon: Icons.favorite_border,
                iconColor: AppColors.primaryDark,
                title: '건강 기록',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HealthRecordScreen()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodayExerciseCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: _handleTodayExerciseCardTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.health_and_safety_outlined, color: AppColors.primaryDark, size: 28),
                const SizedBox(width: 8),
                const Text(
                  '오늘의 추천 운동',
                  style: TextStyle(
                    fontSize: 21,
                    color: AppColors.textMain,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Icon(
                  exerciseSurveyCompleted ? Icons.check_circle : Icons.chevron_right_rounded,
                  color: exerciseSurveyCompleted ? AppColors.primary : AppColors.textSub,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _recommendationTitle(),
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _recommendationSummary(),
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSub,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              exerciseSurveyCompleted ? '눌러서 추천 운동과 영상을 확인하세요.' : '처음 3단계 문답으로 맞춤 운동을 추천해 드려요.',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSub,
                fontWeight: FontWeight.w600,
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

    _showExerciseRecommendationDialog(Map<String, dynamic>.from(exerciseRecommendation!));
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
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
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
                                        final recommendation = buildExerciseRecommendation(
                                          primary: primary ?? '전신 피로',
                                          detail: detail ?? '몸이 무겁고 무기력해요',
                                          severity: option,
                                        );
                                        await _saveExerciseRecommendation(recommendation);
                                        if (sheetContext.mounted) {
                                          Navigator.pop(sheetContext);
                                        }
                                        if (mounted) {
                                          _showExerciseRecommendationDialog(recommendation);
                                        }
                                      } catch (e) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('추천 저장 실패: $e')),
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
                            child: CircularProgressIndicator(color: AppColors.primary),
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

  Future<void> _saveExerciseRecommendation(Map<String, dynamic> recommendation) async {
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
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
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
            _profileInfoRow('생년월일', userBirthDate.trim().isEmpty ? '미등록' : userBirthDate),
            _profileInfoRow('성별', userGender.trim().isEmpty ? '미등록' : userGender),
            _profileInfoRow('전화번호', userPhone.trim().isEmpty ? '미등록' : userPhone),
            if (userRole == '어르신')
              _profileInfoRow('내 연결코드', connectionCode.trim().isEmpty ? '미등록' : connectionCode),
            if (userRole == '보호자')
              _profileInfoRow('연결된 코드', connectedSeniorCode.trim().isEmpty ? '미등록' : connectedSeniorCode),
            if (userRole == '보호자')
              _profileInfoRow('연결된 어르신', connectedSeniorName.trim().isEmpty ? '미등록' : connectedSeniorName),
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

      final seniorName = _normalizeUserName(seniorData['name'], seniorData['displayName']);

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
    if (connectedSeniorId.trim().isEmpty && connectedSeniorCode.trim().isEmpty) {
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
      final seniorPhone = PhoneUtils.formatKoreanPhone((data['phone'] ?? '').toString());
      final seniorConnectionCode = (data['connectionCode'] ?? '').toString();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('연결된 어르신 정보'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _profileInfoRow('이름', seniorName.isEmpty ? '미등록' : seniorName),
              _profileInfoRow('생년월일', seniorBirthDate.isEmpty ? '미등록' : seniorBirthDate),
              _profileInfoRow('성별', seniorGender.isEmpty ? '미등록' : seniorGender),
              _profileInfoRow('전화번호', seniorPhone.isEmpty ? '미등록' : seniorPhone),
              _profileInfoRow('연결코드', seniorConnectionCode.isEmpty ? '미등록' : seniorConnectionCode),
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
