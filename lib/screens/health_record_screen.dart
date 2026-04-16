import 'package:flutter/material.dart';
import 'health_result_screen.dart';
import '../theme/app_theme.dart';

class HealthRecordScreen extends StatefulWidget {
  const HealthRecordScreen({super.key});

  @override
  State<HealthRecordScreen> createState() => _HealthRecordScreenState();
}

class _HealthRecordScreenState extends State<HealthRecordScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> symptomData = [
    {
      "title": "허리가 아파요",
      "department": "정형외과 / 재활의학과",
      "description": "허리 통증은 자세 불균형이나 근육 약화와 관련될 수 있어요.",
      "routines": [
        "고양이-소 자세 스트레칭",
        "허리 돌리기 스트레칭",
        "누워서 무릎 당기기 운동",
      ],
      "icon": Icons.accessibility_new,
    },
    {
      "title": "무릎이 아파요",
      "department": "정형외과",
      "description": "무릎 통증은 관절 부담이나 근력 저하와 관련될 수 있어요.",
      "routines": [
        "의자에 앉아 다리 펴기",
        "무릎 관절 가볍게 굽혔다 펴기",
        "허벅지 근육 강화 운동",
      ],
      "icon": Icons.directions_walk,
    },
    {
      "title": "어깨가 결려요",
      "department": "정형외과 / 재활의학과",
      "description": "어깨 결림은 근육 긴장과 혈액순환 저하로 생길 수 있어요.",
      "routines": [
        "어깨 돌리기",
        "양팔 위로 올려 스트레칭",
        "벽 짚고 가슴 펴기 운동",
      ],
      "icon": Icons.refresh,
    },
    {
      "title": "소화가 안 돼요",
      "department": "소화기내과",
      "description": "소화 불편은 식습관이나 활동량 부족과 연관될 수 있어요.",
      "routines": [
        "식후 가벼운 걷기",
        "복부 호흡 운동",
        "허리 곧게 펴고 앉기",
      ],
      "icon": Icons.favorite,
    },
    {
      "title": "걷기가 힘들어요",
      "department": "재활의학과 / 정형외과",
      "description": "보행 불편은 다리 근력 저하나 균형 감각 문제와 관련될 수 있어요.",
      "routines": [
        "제자리 발 들기 운동",
        "의자 잡고 균형 잡기",
        "종아리 들어올리기 운동",
      ],
      "icon": Icons.elderly,
    },
    {
      "title": "목이 뻐근해요",
      "department": "정형외과 / 재활의학과",
      "description": "목 뻐근함은 자세 문제나 장시간 같은 자세와 관련될 수 있어요.",
      "routines": [
        "목 좌우 기울이기",
        "턱 당기기 자세 교정",
        "목 뒤 스트레칭",
      ],
      "icon": Icons.accessibility,
    },
  ];

  List<Map<String, dynamic>> get filteredSymptoms {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return symptomData;

    final Map<String, List<String>> keywordMap = {
      "허리가 아파요": ["허리", "요통", "허리통증", "허리 아픔", "허리 뻐근"],
      "무릎이 아파요": ["무릎", "무릎통증", "관절", "다리관절", "무릎 시림"],
      "어깨가 결려요": ["어깨", "어깨통증", "어깨 결림", "결림", "어깨 뻐근"],
      "소화가 안 돼요": ["소화", "소화불량", "속이 불편", "더부룩", "배가 불편"],
      "걷기가 힘들어요": ["걷기", "보행", "걷기 힘듦", "걷기 불편", "다리 힘이 없음"],
      "목이 뻐근해요": ["목", "목통증", "목 뻐근", "목 결림", "거북목"],
    };

    return symptomData.where((item) {
      final title = item["title"].toString();
      final department = item["department"].toString().toLowerCase();

      if (title.toLowerCase().contains(query) || department.contains(query)) {
        return true;
      }

      final keywords = keywordMap[title] ?? [];
      return keywords.any(
            (keyword) =>
        keyword.toLowerCase().contains(query) ||
            query.contains(keyword.toLowerCase()),
      );
    }).toList();
  }

  void _openDetail(Map<String, dynamic> symptom) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HealthResultScreen(symptom: symptom),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final symptoms = filteredSymptoms;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "건강 기록",
          style: TextStyle(
            color: AppColors.textMain,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  "어디가 불편하신가요?",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
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
                child: const Text(
                  "불편한 부위를 누르거나 검색하면\n추천 진료과와 운동 루틴을 알려드려요.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.5,
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  hintText: "예: 허리, 요통, 무릎통증, 소화불량",
                  hintStyle: const TextStyle(fontSize: 17),
                  prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              symptoms.isEmpty
                  ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  "검색 결과가 없어요.\n허리, 무릎, 어깨, 소화, 걷기 같은 단어로 다시 검색해보세요.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
              )
                  : GridView.builder(
                itemCount: symptoms.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.05,
                ),
                itemBuilder: (context, index) {
                  final symptom = symptoms[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => _openDetail(symptom),
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
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              symptom["icon"] as IconData,
                              size: 42,
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              symptom["title"].toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
