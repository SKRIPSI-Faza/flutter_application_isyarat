import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dashboard_page.dart';
import 'providers/theme_provider.dart';
import 'services/detection_service.dart';

class DeteksiPage extends StatefulWidget {
  const DeteksiPage({super.key});

  @override
  State<DeteksiPage> createState() => _DeteksiPageState();
}

class _DeteksiPageState extends State<DeteksiPage> with WidgetsBindingObserver {
  // ── Kamera ───────────────────────────────────────────────
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isPermissionDenied = false;
  String? _cameraError;
  bool _isFrontCamera = true;
  bool _isSwitchingCamera = false;

  // ── Deteksi API ──────────────────────────────────────────
  final DetectionService _detectionService = DetectionService();
  bool _isModelReady = false;
  bool _isDetecting = false;

  String _hasilDeteksi = 'Detecting...';
  double _akurasi = 0.0;
  Color _feedbackColor = Colors.transparent;

  // ── FPS dan Smoothing ────────────────────────────────────
  DateTime _lastDetectionTime = DateTime.now();
  final Duration _detectionCooldown = const Duration(milliseconds: 300);
  int _fps = 0;
  DateTime _lastFpsTime = DateTime.now();
  int _frameCount = 0;
  int _inferenceTimeMs = 0;

  // Buffer untuk majority voting
  final List<String> _predictionBuffer = [];
  final int _bufferSize = 5;
  final double _confidenceThreshold = 0.7;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeModelAndCamera();
  }

  Future<void> _initializeModelAndCamera() async {
    // 1. Load / ping model API
    final error = await _detectionService.loadModel();
    if (mounted) {
      setState(() {
        _isModelReady = _detectionService.isInitialized;
        if (error != null) {
          _hasilDeteksi = 'Detecting...'; // tetap tampil kamera walau API gagal
        }
      });
    }

    // 2. Initialize Camera
    await _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopAndDisposeCamera();
    _detectionService.dispose();
    super.dispose();
  }

  Future<void> _stopAndDisposeCamera() async {
    try {
      if (_cameraController != null) {
        if (_cameraController!.value.isStreamingImages) {
          await _cameraController!.stopImageStream();
        }
        await _cameraController!.dispose();
        _cameraController = null;
      }
    } catch (e) {
      debugPrint('Dispose camera error: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _stopAndDisposeCamera();
      if (mounted) setState(() => _isCameraInitialized = false);
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        if (mounted) {
          setState(() {
            _cameraError = 'Tidak ada kamera yang tersedia di perangkat ini.';
          });
        }
        return;
      }

      final targetDir =
          _isFrontCamera ? CameraLensDirection.front : CameraLensDirection.back;

      CameraDescription selectedCamera;
      try {
        selectedCamera =
            _cameras!.firstWhere((c) => c.lensDirection == targetDir);
      } catch (_) {
        selectedCamera = _cameras!.first;
      }

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.low,
        enableAudio: false,
        // Biarkan plugin pilih format terbaik per platform
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      _cameraController = controller;
      await _cameraController!.startImageStream(_processCameraImage);

      setState(() {
        _isCameraInitialized = true;
        _isPermissionDenied = false;
        _cameraError = null;
        _isSwitchingCamera = false;
      });
    } on CameraException catch (e) {
      debugPrint('CameraException: ${e.code} — ${e.description}');
      if (mounted) {
        final isPermission = e.code == 'CameraAccessDenied' ||
            e.code == 'CameraAccessDeniedWithoutPrompt' ||
            e.code == 'AudioAccessDenied';
        setState(() {
          _isPermissionDenied = isPermission;
          _cameraError =
              isPermission ? null : 'Kamera gagal dibuka: ${e.description}';
          _isCameraInitialized = false;
          _isSwitchingCamera = false;
        });
        if (isPermission) _showCameraPermissionDialog();
      }
    } catch (e) {
      debugPrint('Unknown camera error: $e');
      if (mounted) {
        setState(() {
          _cameraError = 'Terjadi kesalahan kamera.\n${e.toString()}';
          _isCameraInitialized = false;
          _isSwitchingCamera = false;
        });
      }
    }
  }

  void _showCameraPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.camera_alt, color: Color(0xFF4FC3F7)),
            SizedBox(width: 10),
            Text('Izin Kamera'),
          ],
        ),
        content: const Text(
          'Aplikasi membutuhkan izin kamera untuk mendeteksi bahasa isyarat.\n\n'
          'Buka Pengaturan → Aplikasi → SnapSign → Izin → Kamera, lalu aktifkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> _switchCamera() async {
    if (_isSwitchingCamera || _cameras == null || _cameras!.length < 2) return;
    setState(() {
      _isSwitchingCamera = true;
      _isCameraInitialized = false;
    });
    await _stopAndDisposeCamera();
    _isFrontCamera = !_isFrontCamera;
    await _initCamera();
  }

  void _processCameraImage(CameraImage image) {
    _frameCount++;
    final now = DateTime.now();

    // Hitung FPS
    if (now.difference(_lastFpsTime).inSeconds >= 1) {
      if (mounted) {
        setState(() {
          _fps = _frameCount;
          _frameCount = 0;
          _lastFpsTime = now;
        });
      }
    }

    if (!_isModelReady || _isDetecting) return;
    if (now.difference(_lastDetectionTime) < _detectionCooldown) return;

    _runDetection(image);
  }

  Future<void> _runDetection(CameraImage image) async {
    _isDetecting = true;
    _lastDetectionTime = DateTime.now();
    final stopwatch = Stopwatch()..start();

    try {
      final result = await _detectionService.runInference(image);
      stopwatch.stop();

      final label = result['label'] as String;
      final confidence = result['confidence'] as double;

      // Update Buffer untuk Majority Voting
      _predictionBuffer.add(label);
      if (_predictionBuffer.length > _bufferSize) {
        _predictionBuffer.removeAt(0);
      }

      final smoothedLabel = _getMajorityVote();

      if (mounted) {
        setState(() {
          _inferenceTimeMs = stopwatch.elapsedMilliseconds;
          _akurasi = confidence;

          if (confidence >= _confidenceThreshold) {
            _hasilDeteksi = smoothedLabel;
            _feedbackColor = Colors.green;
            HapticFeedback.lightImpact();
          } else {
            _hasilDeteksi = 'Detecting...';
            _feedbackColor = Colors.orange;
          }
        });

        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) setState(() => _feedbackColor = Colors.transparent);
        });
      }
    } catch (e) {
      debugPrint('Detection error: $e');
    } finally {
      _isDetecting = false;
    }
  }

  String _getMajorityVote() {
    if (_predictionBuffer.isEmpty) return 'Detecting...';

    final counts = <String, int>{};
    for (var l in _predictionBuffer) {
      counts[l] = (counts[l] ?? 0) + 1;
    }

    var majorityLabel = _predictionBuffer.last;
    var maxCount = 0;

    counts.forEach((key, value) {
      if (value > maxCount) {
        maxCount = value;
        majorityLabel = key;
      }
    });

    return majorityLabel;
  }

  // ── BUILD ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    const Color lightBlue = Color(0xFF4FC3F7);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: lightBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Deteksi Isyarat'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildResultPanel(isDark, lightBlue),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // ── Kamera / Status View ─────────────────
                    _buildCameraView(),

                    // ── Border feedback warna ────────────────
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _feedbackColor == Colors.green
                              ? Colors.green.withOpacity(0.8)
                              : _feedbackColor == Colors.red
                                  ? Colors.red.withOpacity(0.8)
                                  : Colors.transparent,
                          width: 4,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),

                    // ── Overlay & Stats ──────────────────────
                    if (_isCameraInitialized) ...[
                      _buildDetectionOverlay(),
                      _buildStatsOverlay(lightBlue),
                    ],

                    // ── Tombol ganti kamera ──────────────────
                    if (_isCameraInitialized &&
                        _cameras != null &&
                        _cameras!.length > 1)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: GestureDetector(
                          onTap: _switchCamera,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.2)),
                            ),
                            child: Icon(
                              _isFrontCamera
                                  ? Icons.camera_rear
                                  : Icons.camera_front,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),

                    // ── Overlay: API belum siap ──────────────
                    if (_isCameraInitialized && !_isModelReady)
                      _buildApiNotReadyOverlay(lightBlue),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const DashboardPage()),
                  );
                },
                icon: const Icon(Icons.home, size: 22),
                label: const Text(
                  'Kembali ke Dashboard',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: lightBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  /// Pilih widget kamera / error yang tepat
  Widget _buildCameraView() {
    if (_isCameraInitialized && _cameraController != null) {
      return CameraPreview(_cameraController!);
    }

    if (_isPermissionDenied) {
      return _buildStatusView(
        icon: Icons.no_photography_rounded,
        iconColor: Colors.red,
        title: 'Izin Kamera Ditolak',
        subtitle:
            'Aktifkan izin kamera di Pengaturan perangkat Anda, lalu kembali ke halaman ini.',
        actionLabel: 'Coba Lagi',
        onAction: () {
          setState(() {
            _isPermissionDenied = false;
            _cameraError = null;
          });
          _initCamera();
        },
      );
    }

    if (_cameraError != null) {
      return _buildStatusView(
        icon: Icons.error_outline_rounded,
        iconColor: Colors.orange,
        title: 'Kamera Error',
        subtitle: _cameraError!,
        actionLabel: 'Coba Lagi',
        onAction: () {
          setState(() => _cameraError = null);
          _initCamera();
        },
      );
    }

    // Loading
    return _buildLoadingView();
  }

  Widget _buildStatusView({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: iconColor),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4FC3F7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(actionLabel),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF4FC3F7)),
            SizedBox(height: 16),
            Text(
              'Menginisialisasi kamera...',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiNotReadyOverlay(Color lightBlue) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_detectionService.initError == null) ...[
                const CircularProgressIndicator(color: Color(0xFF4FC3F7)),
                const SizedBox(height: 12),
                const Text(
                  'Menghubungkan ke API...',
                  style: TextStyle(color: Colors.white),
                ),
              ] else ...[
                const Icon(Icons.wifi_off_rounded,
                    color: Colors.orange, size: 48),
                const SizedBox(height: 12),
                Text(
                  'API tidak terhubung:\n${_detectionService.initError}',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    setState(() => _isModelReady = false);
                    final err = await _detectionService.loadModel();
                    if (mounted) {
                      setState(() {
                        _isModelReady = _detectionService.isInitialized;
                        if (err == null) {
                          _hasilDeteksi = 'Detecting...';
                        }
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: lightBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Coba Reconnect'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultPanel(bool isDark, Color lightBlue) {
    bool isDetecting = _hasilDeteksi == 'Detecting...';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _feedbackColor != Colors.transparent
              ? _feedbackColor
              : lightBlue.withOpacity(0.25),
          width: _feedbackColor != Colors.transparent ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status',
                    style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[600])),
                Text(
                  isDetecting ? 'Menyesuaikan...' : 'Stabil',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDetecting ? Colors.orange : Colors.green,
                  ),
                ),
                Text(
                  'Confidence: ${(_akurasi * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDetecting
                    ? [Colors.orange.shade400, Colors.orange.shade600]
                    : [Colors.green.shade400, Colors.green.shade600],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    _hasilDeteksi,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withOpacity(0.25), width: 2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border:
                    Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  Positioned(top: 0, left: 0, child: _buildCorner()),
                  Positioned(
                      top: 0,
                      right: 0,
                      child: _buildCorner(rotated: true)),
                  Positioned(
                      bottom: 0,
                      left: 0,
                      child: _buildCorner(flipVertical: true)),
                  Positioned(
                      bottom: 0,
                      right: 0,
                      child: _buildCorner(rotated: true, flipVertical: true)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsOverlay(Color lightBlue) {
    return Positioned(
      bottom: 12,
      left: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('FPS: $_fps',
                style:
                    const TextStyle(color: Colors.white, fontSize: 10)),
            Text('Inference: ${_inferenceTimeMs}ms',
                style:
                    const TextStyle(color: Colors.white, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildCorner({bool rotated = false, bool flipVertical = false}) {
    return Transform(
      transform: Matrix4.identity()
        ..rotateZ(rotated ? 3.14159 / 2 : 0)
        ..scale(1.0, flipVertical ? -1.0 : 1.0),
      alignment: Alignment.center,
      child: Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white, width: 3),
            left: BorderSide(color: Colors.white, width: 3),
          ),
        ),
      ),
    );
  }
}
