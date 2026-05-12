import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:hand_landmarker/hand_landmarker.dart';

import '../theme/app_theme.dart';

enum _HandRepPhase { waitingClose, waitingOpen }
enum _HandShape { unknown, close, open }

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
  HandLandmarkerPlugin? _handPlugin;
  List<CameraDescription> _cameras = const [];

  bool _isLoading = true;
  bool _isCameraReady = false;
  bool _isFrontCamera = true;
  bool _isMirrored = true;
  String _cameraError = '';

  bool _isDetecting = false;
  int _streamSessionId = 0;
  DateTime _lastDetectAt = DateTime.fromMillisecondsSinceEpoch(0);

  _HandRepPhase _repPhase = _HandRepPhase.waitingClose;
  String _gestureGuide = '손을 카메라에 보여주세요.';

  double _smoothRatio = 0;
  double _minObservedRatio = double.infinity;
  double _maxObservedRatio = 0;

  int _completedCount = 0;
  int _currentSet = 1;

  String get _title =>
      (widget.recommendation['title'] ?? '오늘의 추천 운동').toString();
  String get _summary => (widget.recommendation['summary'] ?? '').toString();
  String get _countingType =>
      (widget.recommendation['countingType'] ?? 'repetition').toString();
  int get _targetCount =>
      _toInt(widget.recommendation['targetCount'], fallback: 10);
  int get _targetSets =>
      math.max(1, _toInt(widget.recommendation['targetSets'], fallback: 1));

  String get _movementHint {
    final raw = (widget.recommendation['movementHint'] ?? '').toString().trim();
    if (raw.isNotEmpty) return raw;
    return '손을 오므렸다가(주먹) 펴면(손바닥) 1회로 자동 카운트합니다.';
  }

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
    _streamSessionId += 1;
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      if (controller.value.isStreamingImages) {
        controller.stopImageStream();
      }
      controller.dispose();
    }
    _handPlugin?.dispose();
    _handPlugin = null;
    super.dispose();
  }

  Future<void> _initializeCamera({required bool preferFront}) async {
    final int newSessionId = ++_streamSessionId;

    setState(() {
      _isLoading = true;
      _cameraError = '';
      _gestureGuide = '카메라를 준비하고 있어요...';
    });

    try {
      _handPlugin ??= HandLandmarkerPlugin.create(
        numHands: 1,
        minHandDetectionConfidence: 0.4,
        delegate: HandLandmarkerDelegate.CPU,
      );

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw Exception('사용 가능한 카메라가 없습니다.');
      }

      final front = _cameras
          .where((c) => c.lensDirection == CameraLensDirection.front)
          .toList();
      final back = _cameras
          .where((c) => c.lensDirection == CameraLensDirection.back)
          .toList();

      CameraDescription selected;
      if (preferFront && front.isNotEmpty) {
        selected = front.first;
      } else if (!preferFront && back.isNotEmpty) {
        selected = back.first;
      } else {
        selected = _cameras.first;
      }

      if (_controller != null) {
        if (_controller!.value.isStreamingImages) {
          await _controller!.stopImageStream();
        }
        await _controller!.dispose();
      }

      final controller = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await controller.initialize();
      if (!mounted || _streamSessionId != newSessionId) {
        await controller.dispose();
        return;
      }

      _isDetecting = false;
      _lastDetectAt = DateTime.fromMillisecondsSinceEpoch(0);
      _repPhase = _HandRepPhase.waitingClose;
      _smoothRatio = 0;
      _minObservedRatio = double.infinity;
      _maxObservedRatio = 0;

      await controller.startImageStream(
        (image) => _processCameraImage(image, newSessionId),
      );

      if (!mounted || _streamSessionId != newSessionId) {
        if (controller.value.isStreamingImages) {
          await controller.stopImageStream();
        }
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _isFrontCamera = selected.lensDirection == CameraLensDirection.front;
        if (!_isFrontCamera) _isMirrored = false;
        _isCameraReady = true;
        _isLoading = false;
        _gestureGuide = '주먹을 만들어 주세요.';
      });
    } catch (e) {
      if (!mounted || _streamSessionId != newSessionId) return;
      setState(() {
        _isCameraReady = false;
        _isLoading = false;
        _cameraError = '카메라를 열지 못했어요: $e';
      });
    }
  }

  void _processCameraImage(CameraImage image, int sessionId) {
    if (!mounted ||
        sessionId != _streamSessionId ||
        _isDetecting ||
        _handPlugin == null ||
        _controller == null) {
      return;
    }

    final now = DateTime.now();
    if (now.difference(_lastDetectAt).inMilliseconds < 220) {
      return;
    }

    _isDetecting = true;
    _lastDetectAt = now;
    try {
      final hands = _handPlugin!.detect(
        image,
        _controller!.description.sensorOrientation,
      );

      if (!mounted || sessionId != _streamSessionId) return;
      if (hands.isEmpty) {
        _updateGuide('손을 카메라 중앙에 보여주세요.');
        return;
      }

      final shape = _classifyHandShape(hands.first);
      _updateByHandShape(shape);
    } catch (_) {
      // 프레임 처리 예외는 무시하고 다음 프레임에서 재시도.
    } finally {
      _isDetecting = false;
    }
  }

  _HandShape _classifyHandShape(Hand hand) {
    final landmarks = hand.landmarks;
    if (landmarks.length < 21) return _HandShape.unknown;

    final wrist = landmarks[0];
    final middleMcp = landmarks[9];
    final mcpBase = [landmarks[5], landmarks[9], landmarks[13], landmarks[17]];
    final tips = [
      landmarks[4],
      landmarks[8],
      landmarks[12],
      landmarks[16],
      landmarks[20],
    ];

    double palmBaseSum = 0;
    for (final base in mcpBase) {
      palmBaseSum += _distance(wrist.x, wrist.y, base.x, base.y);
    }
    final palmScale = palmBaseSum / mcpBase.length;
    if (palmScale <= 0.0001) return _HandShape.unknown;

    final extendedFingers = _countExtendedFingers(landmarks);
    if (extendedFingers >= 4) return _HandShape.open;
    if (extendedFingers <= 1) return _HandShape.close;

    double tipsSum = 0;
    for (final tip in tips) {
      tipsSum += _distance(wrist.x, wrist.y, tip.x, tip.y);
    }
    final ratio = (tipsSum / tips.length) / palmScale;

    if (_smoothRatio == 0) {
      _smoothRatio = ratio;
    } else {
      _smoothRatio = (_smoothRatio * 0.75) + (ratio * 0.25);
    }

    if (_smoothRatio < _minObservedRatio) _minObservedRatio = _smoothRatio;
    if (_smoothRatio > _maxObservedRatio) _maxObservedRatio = _smoothRatio;

    final spread = _maxObservedRatio - _minObservedRatio;
    if (spread > 0.45) {
      final normalized =
          (_smoothRatio - _minObservedRatio) / (spread + 0.00001);
      if (normalized <= 0.25) return _HandShape.close;
      if (normalized >= 0.75) return _HandShape.open;
      return _HandShape.unknown;
    }

    if (_smoothRatio <= 1.95) return _HandShape.close;
    if (_smoothRatio >= 2.55) return _HandShape.open;
    return _HandShape.unknown;
  }

  int _countExtendedFingers(List<Landmark> lm) {
    final wrist = lm[0];
    int count = 0;

    bool isExtended(int tipIdx, int pipIdx, {double gain = 1.12}) {
      final tip = lm[tipIdx];
      final pip = lm[pipIdx];
      final tipDist = _distance(wrist.x, wrist.y, tip.x, tip.y);
      final pipDist = _distance(wrist.x, wrist.y, pip.x, pip.y);
      return tipDist > (pipDist * gain);
    }

    // Thumb: tip(4), ip(3)
    if (isExtended(4, 3, gain: 1.08)) count += 1;
    // Index: tip(8), pip(6)
    if (isExtended(8, 6)) count += 1;
    // Middle: tip(12), pip(10)
    if (isExtended(12, 10)) count += 1;
    // Ring: tip(16), pip(14)
    if (isExtended(16, 14)) count += 1;
    // Pinky: tip(20), pip(18)
    if (isExtended(20, 18)) count += 1;

    return count;
  }

  double _distance(double x1, double y1, double x2, double y2) {
    final dx = x1 - x2;
    final dy = y1 - y2;
    return math.sqrt((dx * dx) + (dy * dy));
  }

  void _updateByHandShape(_HandShape shape) {
    if (!mounted) return;

    if (shape == _HandShape.close) {
      if (_repPhase != _HandRepPhase.waitingOpen) {
        setState(() {
          _repPhase = _HandRepPhase.waitingOpen;
          _gestureGuide = '좋아요. 이제 손을 활짝 펴주세요.';
        });
      }
      return;
    }

    if (shape == _HandShape.open) {
      if (_repPhase == _HandRepPhase.waitingOpen) {
        setState(() {
          _repPhase = _HandRepPhase.waitingClose;
          _gestureGuide = '1회 완료! 다시 주먹을 만들어 주세요.';
          _increaseCountInternal();
        });
      } else {
        _updateGuide('주먹을 먼저 만들어 주세요.');
      }
      return;
    }

    if (_repPhase == _HandRepPhase.waitingOpen) {
      _updateGuide('손을 활짝 펴면 1회로 인정해요.');
    } else {
      _updateGuide('주먹을 만들어 시작해 주세요.');
    }
  }

  void _increaseCountInternal() {
    if (_completedCount < _targetCount) {
      _completedCount += 1;
      return;
    }

    if (_currentSet < _targetSets) {
      _currentSet += 1;
      _completedCount = 1;
    }
  }

  void _updateGuide(String guide) {
    if (!mounted || _gestureGuide == guide) return;
    setState(() {
      _gestureGuide = guide;
    });
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

  void _resetCurrentSet() {
    setState(() {
      _completedCount = 0;
      _repPhase = _HandRepPhase.waitingClose;
      _gestureGuide = '주먹을 만들어 시작해 주세요.';
      _minObservedRatio = double.infinity;
      _maxObservedRatio = 0;
      _smoothRatio = 0;
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
          Positioned(left: 14, right: 14, top: 12, child: _buildTopOverlay()),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          const SizedBox(height: 8),
          Text(
            _gestureGuide,
            style: const TextStyle(
              color: Color(0xFFE0E8E2),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (_movementHint.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              _movementHint,
              style: const TextStyle(
                color: Color(0xFFD2DBD4),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.flip_rounded),
                  label: const Text('반전'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _resetCurrentSet,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                '현재 세트 초기화',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
