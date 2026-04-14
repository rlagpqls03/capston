import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'main_screen.dart';

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
        child: CircularProgressIndicator(color: Colors.green),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
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
            color: Colors.green,
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

    return _buildStepLayout(
      question: "생년월일을\n선택해 주세요.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Text(
              "$selectedYear년 $selectedMonth월 $selectedDay일",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildDateStepper(
            label: "년",
            valueText: "$selectedYear",
            onDecrement: () {
              if (selectedYear <= 1900) return;
              final nextYear = selectedYear - 1;
              final clampedDay = _birthDate.day.clamp(1, DateUtils.getDaysInMonth(nextYear, _birthDate.month));
              setState(() => _birthDate = DateTime(nextYear, _birthDate.month, clampedDay));
            },
            onIncrement: () {
              final currentYear = DateTime.now().year;
              if (selectedYear >= currentYear) return;
              final nextYear = selectedYear + 1;
              final clampedDay = _birthDate.day.clamp(1, DateUtils.getDaysInMonth(nextYear, _birthDate.month));
              setState(() => _birthDate = DateTime(nextYear, _birthDate.month, clampedDay));
            },
          ),
          const SizedBox(height: 14),
          _buildDateStepper(
            label: "월",
            valueText: "$selectedMonth",
            onDecrement: () {
              final nextMonth = selectedMonth == 1 ? 12 : selectedMonth - 1;
              final nextYear = selectedMonth == 1 ? selectedYear - 1 : selectedYear;
              if (nextYear < 1900) return;
              final clampedDay = _birthDate.day.clamp(1, DateUtils.getDaysInMonth(nextYear, nextMonth));
              setState(() => _birthDate = DateTime(nextYear, nextMonth, clampedDay));
            },
            onIncrement: () {
              final nextMonth = selectedMonth == 12 ? 1 : selectedMonth + 1;
              final nextYear = selectedMonth == 12 ? selectedYear + 1 : selectedYear;
              if (nextYear > DateTime.now().year) return;
              final clampedDay = _birthDate.day.clamp(1, DateUtils.getDaysInMonth(nextYear, nextMonth));
              setState(() => _birthDate = DateTime(nextYear, nextMonth, clampedDay));
            },
          ),
          const SizedBox(height: 14),
          _buildDateStepper(
            label: "일",
            valueText: "$selectedDay",
            onDecrement: () {
              final minDate = DateTime(1900, 1, 1);
              final nextDate = _birthDate.subtract(const Duration(days: 1));
              if (nextDate.isBefore(minDate)) return;
              setState(() => _birthDate = nextDate);
            },
            onIncrement: () {
              final today = DateTime.now();
              final nextDate = _birthDate.add(const Duration(days: 1));
              if (nextDate.isAfter(DateTime(today.year, today.month, today.day))) return;
              setState(() => _birthDate = nextDate);
            },
          ),
        ],
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
          _selectionButton("직접 사용하는 어르신", _role == "어르신", () => setState(() => _role = "어르신")),
          const SizedBox(height: 16),
          _selectionButton("어르신을 돕는 보호자", _role == "보호자", () => setState(() => _role = "보호자")),
          const SizedBox(height: 16),
          _selectionButton("구인하려는 사람", _role == "구인자", () => setState(() => _role = "구인자")),
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
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(11),
        ],
        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          hintText: "예: 01012345678",
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.green.shade300, width: 2),
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
          color: Color(0xFF2E7D32),
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

  Widget _buildDateStepper({
    required String label,
    required String valueText,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200, width: 2),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          _buildCircleActionButton(
            icon: Icons.remove,
            onTap: onDecrement,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                valueText,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          _buildCircleActionButton(
            icon: Icons.add,
            onTap: onIncrement,
          ),
        ],
      ),
    );
  }

  Widget _buildCircleActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.green.shade600,
        ),
        child: Icon(icon, color: Colors.white, size: 30),
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
        color: isSelected ? Colors.green : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? Colors.green : Colors.grey.shade300, width: 2),
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
    if (_currentPage == 4 && _phone.length >= 10) canGoNext = true;
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
            backgroundColor: Colors.green,
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
