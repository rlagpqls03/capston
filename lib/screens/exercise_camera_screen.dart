import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ExerciseCameraScreen extends StatefulWidget {
  final Map<String, dynamic> recommendation;

  const ExerciseCameraScreen({
    super.key,
    required this.recommendation,
  });

  @override
  State<ExerciseCameraScreen> createState() => _ExerciseCameraScreenState();
}

class _ExerciseCameraScreenState extends State<ExerciseCameraScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];

  bool _isLoading = true;
  bool _isCameraReady = false;
  bool _isFrontCamera = true;
  bool _isMirrored = true;
  String _cameraError = '';

  int _completedCount = 0;
  int _currentSet = 1;

  String get _title => (widget.recommendation['title'] ?? '오늘의 추천 운동').toString();
  String get _summary => (widget.recommendation['summary'] ?? '').toString();
  String get _movementHint => (widget.recommendation['movementHint'] ?? '').toString();
  String get _countingType => (widget.recommendation['countingType'] ?? 'repetition').toString();
  int get _targetCount => _toInt(widget.recommendation['targetCount'], fallback: 10);
  int get _targetSets => math.max(1, _toInt(widget.recommendation['targetSets'], fallback: 1));

  static int _toInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  @override
  void initState() {
    super.initState();
    _initializeCamera(preferFront: true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera({required bool preferFront}) async {
    setState(() {
      _isLoading = true;
      _cameraError = '';
    });

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw Exception('사용 가능한 카메라가 없습니다.');
      }

      final front = _cameras.where((c) => c.lensDirection == CameraLensDirection.front).toList();
      final back = _cameras.where((c) => c.lensDirection == CameraLensDirection.back).toList();

      CameraDescription selected;
      if (preferFront && front.isNotEmpty) {
        selected = front.first;
      } else if (!preferFront && back.isNotEmpty) {
        selected = back.first;
      } else {
        selected = _cameras.first;
      }

      await _controller?.dispose();

      final controller = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _isFrontCamera = selected.lensDirection == CameraLensDirection.front;
        if (!_isFrontCamera) _isMirrored = false;
        _isCameraReady = true;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCameraReady = false;
        _isLoading = false;
        _cameraError = '카메라를 열지 못했어요: $e';
      });
    }
  }

  Future<void> _switchCamera() async {
    await _initializeCamera(preferFront: !_isFrontCamera);
  }

  void _toggleMirror() {
    if (!_isFrontCamera) return;
    setState(() {
      _isMirrored = !_isMirrored;
    });
  }

  void _increaseCount() {
    setState(() {
      if (_completedCount < _targetCount) {
        _completedCount += 1;
      } else if (_currentSet < _targetSets) {
        _currentSet += 1;
        _completedCount = 1;
      }
    });
  }

  void _resetCurrentSet() {
    setState(() {
      _completedCount = 0;
    });
  }

  bool get _isSetComplete => _completedCount >= _targetCount;
  bool get _isAllComplete => _isSetComplete && _currentSet >= _targetSets;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          '운동 카메라',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _buildCameraLayer()),
          Positioned(
            left: 14,
            right: 14,
            top: 12,
            child: _buildTopOverlay(),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 20,
            child: _buildBottomOverlay(),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraLayer() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (!_isCameraReady || _controller == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            _cameraError.isEmpty ? '카메라를 사용할 수 없어요.' : _cameraError,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 17),
          ),
        ),
      );
    }

    Widget preview = CameraPreview(_controller!);
    if (_isFrontCamera && _isMirrored) {
      preview = Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
        child: preview,
      );
    }

    return preview;
  }

  Widget _buildTopOverlay() {
    final progressText = _countingType == 'duration'
        ? '${_completedCount}s / ${_targetCount}s'
        : '$_completedCount / $_targetCount회';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.44),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (_summary.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              _summary,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _isAllComplete ? const Color(0xFF1FC96E) : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _isAllComplete ? '완료됨' : progressText,
                  style: TextStyle(
                    color: _isAllComplete ? Colors.white : Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '세트 $_currentSet / $_targetSets',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (_movementHint.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _movementHint,
              style: const TextStyle(
                color: Color(0xFFE0E8E2),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomOverlay() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _switchCamera,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.cameraswitch_rounded),
                  label: Text(_isFrontCamera ? '후면 카메라' : '전면 카메라'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isFrontCamera ? _toggleMirror : null,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.flip_rounded),
                  label: const Text('반전'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetCurrentSet,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    '현재 세트 초기화',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _increaseCount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    '1회 완료',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
