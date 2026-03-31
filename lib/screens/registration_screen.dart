import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final int _totalSteps = 4;

  String _name = "";
  String _birthYear = "";
  String _gender = "";
  String _role = "";
  String _generatedCode = "";

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _generatedCode = (Random().nextInt(900000) + 100000).toString();
  }

  void _nextPage() {
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
        'birthYear': _birthYear,
        'gender': _gender,
        'role': _role,
        'connectionCode': _role == '어르신' ? _generatedCode : _codeController.text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
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
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildNameStep(),
          _buildBirthStep(),
          _buildGenderStep(),
          _buildRoleStep(),
          _buildFinalStep(),
        ],
      ),
      bottomNavigationBar: _buildNextButton(),
    );
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
    return _buildStepLayout(
      question: "몇 년도에\n태어나셨나요?",
      child: TextField(
        controller: _birthController,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(
          hintText: "예: 1955",
          border: InputBorder.none,
        ),
        onChanged: (val) => setState(() => _birthYear = val),
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
        ],
      ),
    );
  }

  Widget _buildFinalStep() {
    if (_role == "어르신") {
      return _buildStepLayout(
        question: "가입을 축하합니다!",
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("보호자에게 아래 번호를 알려주세요.", style: TextStyle(fontSize: 20, color: Colors.grey)),
            const SizedBox(height: 30),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.shade200, width: 2),
              ),
              child: Text(
                _generatedCode,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  letterSpacing: 12,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return _buildStepLayout(
        question: "연결할 어르신의\n코드를 입력해 주세요.",
        child: TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: 15),
          decoration: const InputDecoration(
            hintText: "000000",
            counterText: "",
            border: InputBorder.none,
          ),
        ),
      );
    }
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
    if (_currentPage == 1 && _birthYear.length == 4) canGoNext = true;
    if (_currentPage == 2 && _gender.isNotEmpty) canGoNext = true;
    if (_currentPage == 3 && _role.isNotEmpty) canGoNext = true;
    if (_currentPage == 4) canGoNext = true;

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