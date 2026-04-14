import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/job_board_service.dart';
import 'location_picker_screen.dart';

class JobScreen extends StatefulWidget {
  final String? socialId;
  const JobScreen({super.key, this.socialId});

  @override
  State<JobScreen> createState() => _JobScreenState();
}

class _JobScreenState extends State<JobScreen> {
  final JobBoardService _jobBoardService = JobBoardService();
  final TextEditingController _searchController = TextEditingController();
  final List<String> _categories = ["전체", "돌봄", "청소", "주방", "운전", "사무보조", "기타"];
  String _selectedCategory = "전체";
  String _currentUserRole = "";
  String _currentUserPhone = "";
  String _currentUserName = "";

  @override
  void initState() {
    super.initState();
    _loadCurrentUserProfile();
  }

  Future<void> _loadCurrentUserProfile() async {
    if (widget.socialId == null) return;
    final profile = await _jobBoardService.getUserProfile(widget.socialId!);
    if (!mounted) return;
    setState(() {
      _currentUserRole = profile['role'] ?? '';
      _currentUserPhone = profile['phone'] ?? '';
      _currentUserName = profile['name'] ?? '';
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("일자리 찾기"),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(
            tooltip: "구인글 등록",
            icon: const Icon(Icons.edit_note_rounded),
            onPressed: _openCreateForm,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: "지역, 기관명, 일자리명 검색",
                  hintStyle: const TextStyle(fontSize: 17),
                  prefixIcon: const Icon(Icons.search, size: 28),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 54,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemBuilder: (_, index) {
                  final category = _categories[index];
                  final selected = _selectedCategory == category;
                  return ChoiceChip(
                    selected: selected,
                    label: Text(
                      category,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : Colors.black87,
                      ),
                    ),
                    selectedColor: Colors.green,
                    backgroundColor: Colors.grey.shade200,
                    onSelected: (_) => setState(() => _selectedCategory = category),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: _categories.length,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _jobBoardService.streamJobPosts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "게시글을 불러오지 못했어요.\n${snapshot.error}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 17),
                      ),
                    );
                  }

                  final docs = (snapshot.data?.docs ?? []).where((doc) {
                    final data = doc.data();
                    final categoryOk = _selectedCategory == "전체" || data["category"] == _selectedCategory;
                    final text = "${data["title"] ?? ""} ${data["company"] ?? ""} ${data["location"] ?? ""}".toLowerCase();
                    final keyword = _searchController.text.trim().toLowerCase();
                    return categoryOk && (keyword.isEmpty || text.contains(keyword));
                  }).toList();

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "조건에 맞는 구인글이 없어요.",
                        style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: docs.length,
                    itemBuilder: (_, index) {
                      final doc = docs[index];
                      final data = doc.data();
                      final isMine = widget.socialId != null && data["authorId"] == widget.socialId;
                      return _JobPostCard(
                        data: data,
                        dateText: _buildDateText(data["createdAt"]),
                        onTap: () => _showJobDetail(doc.id, data, isMine),
                        onMenuSelect: (value) {
                          if (value == "edit") _openEditForm(doc.id, data);
                          if (value == "delete") _confirmDelete(doc.id);
                        },
                        showManageMenu: isMine,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildDateText(dynamic createdAt) {
    if (createdAt is! Timestamp) return "방금";
    final diff = DateTime.now().difference(createdAt.toDate());
    if (diff.inMinutes < 1) return "방금";
    if (diff.inHours < 1) return "${diff.inMinutes}분 전";
    if (diff.inDays < 1) return "${diff.inHours}시간 전";
    return "${diff.inDays}일 전";
  }

  String _buildLocationText(String base, String detail) {
    final b = base.trim();
    final d = detail.trim();
    return d.isEmpty ? b : "$b $d";
  }

  void _showNeedLoginMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("로그인 후 구인글을 등록할 수 있어요.")),
    );
  }

  void _openCreateForm() {
    if (widget.socialId == null) {
      _showNeedLoginMessage();
      return;
    }
    if (_currentUserRole != "구인자") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("구인자만 구인글을 등록할 수 있어요.")),
      );
      return;
    }
    if (_currentUserPhone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("휴대폰 번호를 먼저 등록해 주세요.")),
      );
      return;
    }
    _openPostForm();
  }

  void _openEditForm(String docId, Map<String, dynamic> seed) => _openPostForm(docId: docId, seed: seed);

  Future<void> _openPostForm({String? docId, Map<String, dynamic>? seed}) async {
    final titleController = TextEditingController(text: seed?["title"]?.toString() ?? "");
    final companyController = TextEditingController(text: seed?["company"]?.toString() ?? "");
    String selectedLocationBase = seed?["locationBase"]?.toString() ?? seed?["location"]?.toString() ?? "";
    final locationDetailController = TextEditingController(text: seed?["locationDetail"]?.toString() ?? "");
    final dynamic seedLat = seed?["locationLat"];
    final dynamic seedLng = seed?["locationLng"];
    double? selectedLat = seedLat is num ? seedLat.toDouble() : double.tryParse("$seedLat");
    double? selectedLng = seedLng is num ? seedLng.toDouble() : double.tryParse("$seedLng");
    final payController = TextEditingController(text: seed?["pay"]?.toString() ?? "");
    final timeController = TextEditingController(text: seed?["time"]?.toString() ?? "");
    final descriptionController = TextEditingController(text: seed?["description"]?.toString() ?? "");
    String category = seed?["category"]?.toString() ?? "기타";
    final isEdit = docId != null;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(modalContext).viewInsets.bottom + 16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(isEdit ? "구인글 수정" : "구인글 등록", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    _formTextField(titleController, "제목"),
                    _formTextField(companyController, "기관/업체명"),
                    const Text("기관 위치", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              selectedLocationBase.isEmpty ? "지도 아이콘을 눌러 위치를 지정해 주세요." : selectedLocationBase,
                              style: TextStyle(fontSize: 16, color: selectedLocationBase.isEmpty ? Colors.grey.shade600 : Colors.black87),
                            ),
                          ),
                          IconButton(
                            tooltip: "지도에서 위치 선택",
                            onPressed: () async {
                              final result = await Navigator.of(modalContext).push<LocationPickerResult>(
                                MaterialPageRoute(
                                  builder: (_) => LocationPickerScreen(
                                    initialLat: selectedLat,
                                    initialLng: selectedLng,
                                    title: "기관 위치 선택",
                                  ),
                                ),
                              );
                              if (result != null) {
                                setModalState(() {
                                  selectedLocationBase = result.address;
                                  selectedLat = result.latitude;
                                  selectedLng = result.longitude;
                                });
                              }
                            },
                            icon: const Icon(Icons.location_on_rounded, color: Colors.green, size: 30),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: locationDetailController,
                      decoration: _formDecoration("상세 주소 (예: 103호, 뒷문)"),
                    ),
                    const SizedBox(height: 10),
                    _formTextField(payController, "급여"),
                    _formTextField(timeController, "근무 시간"),
                    DropdownButtonFormField<String>(
                      value: _categories.contains(category) ? category : "기타",
                      decoration: _formDecoration("직무 분류"),
                      items: _categories.where((e) => e != "전체").map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) {
                        if (v != null) setModalState(() => category = v);
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descriptionController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: _formDecoration("상세 설명"),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (widget.socialId == null) {
                            Navigator.pop(modalContext);
                            _showNeedLoginMessage();
                            return;
                          }
                          if (titleController.text.trim().isEmpty ||
                              companyController.text.trim().isEmpty ||
                              selectedLocationBase.trim().isEmpty ||
                              payController.text.trim().isEmpty ||
                              timeController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(modalContext).showSnackBar(
                              const SnackBar(content: Text("필수 항목을 입력해 주세요.")),
                            );
                            return;
                          }

                          final fullLocation = _buildLocationText(selectedLocationBase, locationDetailController.text);
                          try {
                            if (isEdit) {
                              await _jobBoardService.updateJobPost(
                                docId: docId!,
                                title: titleController.text.trim(),
                                company: companyController.text.trim(),
                                location: fullLocation,
                                locationBase: selectedLocationBase.trim(),
                                locationDetail: locationDetailController.text.trim(),
                                locationLat: selectedLat,
                                locationLng: selectedLng,
                                pay: payController.text.trim(),
                                workTime: timeController.text.trim(),
                                category: category,
                                description: descriptionController.text.trim(),
                              );
                            } else {
                              await _jobBoardService.createJobPost(
                                socialId: widget.socialId!,
                                title: titleController.text.trim(),
                                company: companyController.text.trim(),
                                location: fullLocation,
                                locationBase: selectedLocationBase.trim(),
                                locationDetail: locationDetailController.text.trim(),
                                locationLat: selectedLat,
                                locationLng: selectedLng,
                                pay: payController.text.trim(),
                                workTime: timeController.text.trim(),
                                category: category,
                                description: descriptionController.text.trim(),
                              );
                            }
                            if (mounted) {
                              Navigator.pop(modalContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(isEdit ? "구인글이 수정되었어요." : "구인글이 등록되었어요.")),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(modalContext).showSnackBar(
                              SnackBar(content: Text("저장 실패: $e")),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          isEdit ? "수정 완료" : "등록하기",
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _formDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Colors.green, width: 2),
      ),
    );
  }

  Widget _formTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(controller: controller, decoration: _formDecoration(label)),
    );
  }

  Future<void> _confirmDelete(String docId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("구인글 삭제"),
        content: const Text("이 글을 정말 삭제할까요?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("취소")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("삭제")),
        ],
      ),
    );
    if (shouldDelete == true) {
      await _jobBoardService.deleteJobPost(docId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("구인글이 삭제되었어요.")));
      }
    }
  }

  void _showJobDetail(String docId, Map<String, dynamic> data, bool isMine) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data["title"]?.toString() ?? "", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              _detailRow(Icons.business_outlined, data["company"]?.toString() ?? ""),
              _detailRow(Icons.location_on_outlined, data["location"]?.toString() ?? ""),
              _detailRow(Icons.payments_outlined, data["pay"]?.toString() ?? ""),
              _detailRow(Icons.schedule_outlined, data["time"]?.toString() ?? ""),
              _detailRow(Icons.person_outline, data["authorName"]?.toString() ?? ""),
              if (_currentUserRole == "어르신" || isMine)
                _detailRow(Icons.call_outlined, data["recruiterPhone"]?.toString().isNotEmpty == true ? data["recruiterPhone"].toString() : "등록된 연락처 없음"),
              const SizedBox(height: 12),
              Text(data["description"]?.toString() ?? "", style: const TextStyle(fontSize: 18, height: 1.5)),
              const SizedBox(height: 20),
              if (isMine)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showApplications(docId);
                        },
                        child: const Text(
                          "신청자",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _openEditForm(docId, data);
                        },
                        child: const Text(
                          "수정",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmDelete(docId);
                        },
                        child: const Text(
                          "삭제",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentUserRole != "어르신") {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("어르신만 지원할 수 있어요.")));
                        return;
                      }
                      Navigator.pop(context);
                      _openApplySheet(docId);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text("지원하기", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openApplySheet(String jobId) async {
    if (widget.socialId == null) {
      _showNeedLoginMessage();
      return;
    }
    final messageController = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (modalContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(modalContext).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("지원하기", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Text("지원자: ${_currentUserName.isEmpty ? '사용자' : _currentUserName}", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(controller: messageController, minLines: 2, maxLines: 4, decoration: _formDecoration("간단한 지원 메모 (선택)")),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await _jobBoardService.applyToJob(
                        jobId: jobId,
                        applicantId: widget.socialId!,
                        message: messageController.text.trim(),
                      );
                      if (mounted) {
                        Navigator.pop(modalContext);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("지원이 완료되었어요.")));
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(modalContext).showSnackBar(SnackBar(content: Text("지원 실패: $e")));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text("지원 완료", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showApplications(String jobId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("신청자 목록", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              SizedBox(
                height: 320,
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _jobBoardService.streamApplications(jobId),
                  builder: (context, snapshot) {
                    final docs = snapshot.data?.docs ?? [];
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (docs.isEmpty) {
                      return const Center(child: Text("아직 신청자가 없어요.", style: TextStyle(fontSize: 18)));
                    }
                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (_, index) {
                        final data = docs[index].data();
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 4),
                          title: Text(data["applicantName"]?.toString() ?? "이름 없음", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          subtitle: Text(
                            "연락처: ${data["applicantPhone"] ?? "-"}\n메모: ${data["message"] ?? "-"}",
                            style: const TextStyle(fontSize: 16, height: 1.4),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.green.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _JobPostCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String dateText;
  final VoidCallback onTap;
  final ValueChanged<String> onMenuSelect;
  final bool showManageMenu;

  const _JobPostCard({
    required this.data,
    required this.dateText,
    required this.onTap,
    required this.onMenuSelect,
    required this.showManageMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      data["title"]?.toString() ?? "",
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (showManageMenu)
                    PopupMenuButton<String>(
                      onSelected: onMenuSelect,
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: "edit", child: Text("수정")),
                        PopupMenuItem(value: "delete", child: Text("삭제")),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(data["company"]?.toString() ?? "", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text("${data["location"] ?? ""} · ${data["time"] ?? ""}", style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      data["pay"]?.toString() ?? "",
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.green),
                    ),
                  ),
                  const Spacer(),
                  Text(dateText, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
