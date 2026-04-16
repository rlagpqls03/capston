import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../theme/app_theme.dart';
import 'main_screen.dart';

class KoreanPhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 11 ? digits.substring(0, 11) : digits;
    final formatted = _format(limited);

    final selectionDigits =
        newValue.selection.baseOffset.clamp(0, newValue.text.length).toInt();
    final digitsBeforeCursor = newValue.text
        .substring(0, selectionDigits)
        .replaceAll(RegExp(r'\D'), '')
        .length
        .clamp(0, limited.length)
        .toInt();
    final cursorOffset = _cursorOffsetForDigits(formatted, digitsBeforeCursor);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorOffset),
    );
  }

  static int _cursorOffsetForDigits(String formatted, int digitsCount) {
    if (digitsCount <= 0) return 0;
    var seen = 0;
    for (var i = 0; i < formatted.length; i++) {
      if (RegExp(r'\d').hasMatch(formatted[i])) {
        seen++;
        if (seen == digitsCount) {
          return i + 1;
        }
      }
    }
    return formatted.length;
  }

  static String _format(String digits) {
    if (digits.length <= 3) return digits;
    if (digits.length <= 7) {
      return '${digits.substring(0, 3)}-${digits.substring(3)}';
    }
    return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}';
  }
}

class RegistrationScreen extends StatefulWidget {
  // [수정] 로그인 화면에서 넘겨주는 고유 ID를 저장할 변수
  final String socialId;

  const RegistrationScreen({
    super.key,
    required this.socialId, // 필수값으로 설정
  });

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalSteps = 5;

  String _name = "";
  DateTime _birthDate = DateTime(DateTime.now().year - 65, 1, 1);
  String _gender = "";
  String _role = "";
  String _phone = "";
  String _generatedCode = "";

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _generatedCode = (Random().nextInt(900000) + 100000).toString();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    final currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }
  }

  void _nextPage() {
    _dismissKeyboard();
    if (_currentPage < _totalSteps) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
    } else {
      _submitData();
    }
  }

  Future<void> _submitData() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      // [핵심] 이제 무작위 UID가 아니라 전달받은 socialId를 문서 ID로 사용합니다.
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.socialId)
          .set({
        'uid': widget.socialId,
        'name': _name,
        'birthDate': _formatBirthDate(_birthDate),
        'birthYear': _birthDate.year.toString(),
        'gender': _gender,
        'role': _role,
        'phone': _phone,
        'connectionCode': _role == '어르신' ? _generatedCode : '',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pop(context);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => MainScreen(socialId: widget.socialId),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      print("데이터 저장 실패: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: _currentPage > 0
            ? IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 30),
          onPressed: () {
            _dismissKeyboard();
            _pageController.previousPage(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
            setState(() => _currentPage--);
          },
        )
            : null,
        title: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: (_currentPage + 1) / (_totalSteps + 1),
            minHeight: 10,
            backgroundColor: Colors.grey.shade200,
            color: AppColors.primary,
          ),
        ),
      ),
      body: GestureDetector(
        onTap: _dismissKeyboard,
        behavior: HitTestBehavior.opaque,
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildNameStep(),
            _buildBirthStep(),
            _buildGenderStep(),
            _buildRoleStep(),
            _buildPhoneStep(),
            _buildFinalStep(),
          ],
        ),
      ),
      bottomNavigationBar: _buildNextButton(),
    );
  }

  String _formatBirthDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _phoneDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

  // --- 가독성을 위해 분리된 UI 위젯들 ---
  Widget _buildNameStep() {
    return _buildStepLayout(
      question: "성함이 어떻게\n되시나요?",
      child: TextField(
        controller: _nameController,
        autofocus: true,
        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(
          hintText: "성함 입력",
          border: InputBorder.none,
        ),
        onChanged: (val) => setState(() => _name = val),
      ),
    );
  }

  Widget _buildBirthStep() {
    final int selectedYear = _birthDate.year;
    final int selectedMonth = _birthDate.month;
    final int selectedDay = _birthDate.day;
    final dateText =
        '$selectedYear.${selectedMonth.toString().padLeft(2, '0')}.${selectedDay.toString().padLeft(2, '0')}';

    return _buildStepLayout(
      question: "생년월일을\n입력해 주세요.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              dateText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildBirthSelectCard(
                  label: '년',
                  value: '$selectedYear',
                  onTap: () {
                    final currentYear = DateTime.now().year;
                    _showBirthPickerSheet(
                      title: '출생 연도 선택',
                      values: List.generate(currentYear - 1899, (i) => 1900 + i).reversed.toList(),
                      selected: selectedYear,
                      onSelected: (value) => _setBirthDate(year: value),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildBirthSelectCard(
                  label: '월',
                  value: '$selectedMonth',
                  onTap: () {
                    final maxMonth = _maxSelectableMonth(selectedYear);
                    _showBirthPickerSheet(
                      title: '출생 월 선택',
                      values: List.generate(maxMonth, (i) => i + 1),
                      selected: selectedMonth,
                      onSelected: (value) => _setBirthDate(month: value),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildBirthSelectCard(
                  label: '일',
                  value: '$selectedDay',
                  onTap: () {
                    final maxDay = _maxSelectableDay(selectedYear, selectedMonth);
                    _showBirthPickerSheet(
                      title: '출생 일 선택',
                      values: List.generate(maxDay, (i) => i + 1),
                      selected: selectedDay,
                      onSelected: (value) => _setBirthDate(day: value),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "연, 월, 일을 눌러서 선택해 주세요.",
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSub,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  int _maxSelectableMonth(int year) {
    final today = DateTime.now();
    return year == today.year ? today.month : 12;
  }

  int _maxSelectableDay(int year, int month) {
    final today = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    if (year == today.year && month == today.month) {
      return today.day;
    }
    return daysInMonth;
  }

  void _setBirthDate({int? year, int? month, int? day}) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    int nextYear = year ?? _birthDate.year;
    nextYear = nextYear.clamp(1900, today.year).toInt();

    int nextMonth = month ?? _birthDate.month;
    nextMonth = nextMonth.clamp(1, _maxSelectableMonth(nextYear)).toInt();

    int nextDay = day ?? _birthDate.day;
    nextDay = nextDay.clamp(1, _maxSelectableDay(nextYear, nextMonth)).toInt();

    DateTime candidate = DateTime(nextYear, nextMonth, nextDay);
    if (candidate.isAfter(todayDate)) {
      candidate = todayDate;
    }

    setState(() => _birthDate = candidate);
  }

  Future<void> _showBirthPickerSheet({
    required String title,
    required List<int> values,
    required int selected,
    required ValueChanged<int> onSelected,
  }) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: 420,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textMain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    itemCount: values.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final value = values[index];
                      final isSelected = value == selected;
                      return ListTile(
                        onTap: () => Navigator.pop(sheetContext, value),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        title: Text(
                          '$value',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? AppColors.primaryDark : AppColors.textMain,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: AppColors.primary, size: 28)
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (picked != null) {
      onSelected(picked);
    }
  }

  Widget _buildBirthSelectCard({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSub,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppColors.textMain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderStep() {
    return _buildStepLayout(
      question: "성별을\n선택해 주세요.",
      child: Row(
        children: [
          _selectionButton("남성", _gender == "남성", () => setState(() => _gender = "남성")),
          const SizedBox(width: 16),
          _selectionButton("여성", _gender == "여성", () => setState(() => _gender = "여성")),
        ],
      ),
    );
  }

  Widget _buildRoleStep() {
    return _buildStepLayout(
      question: "누가 이 앱을\n사용하시나요?",
      child: Column(
        children: [
          _selectionButton("어르신", _role == "어르신", () => setState(() => _role = "어르신")),
          const SizedBox(height: 16),
          _selectionButton("보호자", _role == "보호자", () => setState(() => _role = "보호자")),
          const SizedBox(height: 16),
          _selectionButton("구인자", _role == "구인자", () => setState(() => _role = "구인자")),
        ],
      ),
    );
  }

  Widget _buildPhoneStep() {
    return _buildStepLayout(
      question: "휴대폰 번호를\n입력해 주세요.",
      child: TextField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d-]')),
          KoreanPhoneNumberFormatter(),
        ],
        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          hintText: "예: 010-1234-5678",
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        onChanged: (val) => setState(() => _phone = val.trim()),
      ),
    );
  }

  Widget _buildFinalStep() {
    return const Center(
      child: Text(
        "환영합니다",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 56,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          color: AppColors.primaryDark,
          shadows: [
            Shadow(
              color: Color(0x22000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepLayout({required String question, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, height: 1.3),
          ),
          const SizedBox(height: 50),
          child,
        ],
      ),
    );
  }

  Widget _selectionButton(String title, bool isSelected, VoidCallback onTap) {
    bool isWide = title.length > 2;
    Widget content = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 25),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade300, width: 2),
      ),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
    return isWide ? InkWell(onTap: onTap, child: content) : Expanded(child: InkWell(onTap: onTap, child: content));
  }

  Widget _buildNextButton() {
    bool canGoNext = false;
    if (_currentPage == 0 && _name.trim().isNotEmpty) canGoNext = true;
    if (_currentPage == 1) canGoNext = true;
    if (_currentPage == 2 && _gender.isNotEmpty) canGoNext = true;
    if (_currentPage == 3 && _role.isNotEmpty) canGoNext = true;
    if (_currentPage == 4 && _phoneDigits(_phone).length == 11) canGoNext = true;
    if (_currentPage == 5) canGoNext = true;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 75,
        child: ElevatedButton(
          onPressed: canGoNext ? _nextPage : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: Colors.grey.shade300,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: Text(
            _currentPage == _totalSteps ? "시작하기" : "다음",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

