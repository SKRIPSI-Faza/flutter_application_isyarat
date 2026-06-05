import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/detection_service.dart';

class DetectionProvider extends ChangeNotifier with WidgetsBindingObserver {
  final DetectionService _service = DetectionService();

  // ── Kamera ──────────────────────────────────────────────────
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isPermissionDenied  = false;
  bool _isPermissionPermanent = false;
  String? _cameraError;
  bool _isFrontCamera      = true;
  bool _isSwitchingCamera  = false;

  // ── Deteksi (siklus collect → predict → hold dikelola server) ─
  bool _isModelReady = false;
  bool _isDetecting  = false;
  String _hasilDeteksi = 'Bersiap...';
  double _akurasi      = 0.0;
  Color  _feedbackColor = Colors.transparent;

  // ── Fase siklus dari server ──────────────────────────────────
  String _phase          = 'collect';   // 'collect' | 'hold' | 'error'
  double _remaining      = 0.0;          // detik tersisa di fase ini
  double _phaseDuration  = 5.0;          // durasi total fase berjalan
  bool   _poseOk         = false;        // pose terdeteksi di frame terakhir
  int    _hands          = 0;            // jumlah tangan terdeteksi
  int    _framesCollected = 0;           // frame terkumpul (fase collect)
  int    _handFrames     = 0;            // frame yang ada tangan (fase collect)
  List<dynamic> _top3    = const [];     // [[label, conf], ...]

  // ── FPS & timing ────────────────────────────────────────────
  DateTime _lastDetectionTime = DateTime.now();
  // Cooldown kecil → fase collect mengumpulkan lebih banyak frame.
  final Duration _detectionCooldown = const Duration(milliseconds: 120);
  int _fps        = 0;
  int _frameCount = 0;
  DateTime _lastFpsTime    = DateTime.now();
  int _inferenceTimeMs     = 0;

  // ── Getters ──────────────────────────────────────────────────
  CameraController? get cameraController    => _cameraController;
  List<CameraDescription>? get cameras      => _cameras;
  bool   get isCameraInitialized => _isCameraInitialized;
  bool   get isPermissionDenied  => _isPermissionDenied;
  bool   get isPermissionPermanentlyDenied => _isPermissionPermanent;
  String? get cameraError        => _cameraError;
  bool   get isFrontCamera       => _isFrontCamera;
  bool   get isSwitchingCamera   => _isSwitchingCamera;
  bool   get isModelReady        => _isModelReady;
  String get hasilDeteksi        => _hasilDeteksi;
  double get akurasi             => _akurasi;
  Color  get feedbackColor       => _feedbackColor;
  int    get fps                 => _fps;
  int    get inferenceTimeMs     => _inferenceTimeMs;
  String? get initError          => _service.initError;
  String get phase               => _phase;
  double get remaining           => _remaining;
  double get phaseDuration       => _phaseDuration;
  bool   get poseOk              => _poseOk;
  int    get hands               => _hands;
  int    get framesCollected     => _framesCollected;
  int    get handFrames          => _handFrames;
  List<dynamic> get top3         => _top3;
  bool   get isPreparing         => _phase == 'prepare';
  bool   get isCollecting        => _phase == 'collect';
  bool   get isHolding           => _phase == 'hold';
  bool   get isError             => _phase == 'error';

  DetectionProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

  // ── Lifecycle ────────────────────────────────────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _stopAndDisposeCamera();
      _isCameraInitialized = false;
      notifyListeners();
    } else if (state == AppLifecycleState.resumed) {
      initCamera();
    }
  }

  // ── Inisialisasi ─────────────────────────────────────────────
  Future<void> initialize() async {
    final error = await _service.loadModel();
    _isModelReady = _service.isInitialized;
    if (error != null) _hasilDeteksi = 'Bersiap...';
    notifyListeners();
    await initCamera();
  }

  // ── Kamera ───────────────────────────────────────────────────
  Future<void> initCamera() async {
    try {
      // Minta izin kamera secara eksplisit → memunculkan dialog sistem.
      // Kalau ditolak permanen, OS tak akan menampilkan dialog lagi,
      // jadi kita tandai agar UI bisa mengarahkan ke Pengaturan.
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        _isPermissionDenied    = true;
        _isPermissionPermanent =
            status.isPermanentlyDenied || status.isRestricted;
        _isCameraInitialized   = false;
        _isSwitchingCamera     = false;
        notifyListeners();
        return;
      }

      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        _cameraError = 'Tidak ada kamera yang tersedia di perangkat ini.';
        notifyListeners();
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
        // medium (~480p) — cukup detail untuk MediaPipe deteksi tangan.
        // low (~240p) bikin tangan terlalu kecil → tidak terdeteksi.
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();
      _cameraController = controller;
      await _cameraController!.startImageStream(_processCameraImage);

      _isCameraInitialized   = true;
      _isPermissionDenied    = false;
      _isPermissionPermanent = false;
      _cameraError           = null;
      _isSwitchingCamera     = false;
      notifyListeners();
    } on CameraException catch (e) {
      final isPermission = e.code == 'CameraAccessDenied' ||
          e.code == 'CameraAccessDeniedWithoutPrompt' ||
          e.code == 'AudioAccessDenied';
      _isPermissionDenied  = isPermission;
      // Tanpa prompt = sudah ditolak permanen → arahkan ke Pengaturan.
      if (e.code == 'CameraAccessDeniedWithoutPrompt') {
        _isPermissionPermanent = true;
      }
      _cameraError         = isPermission ? null : 'Kamera gagal dibuka: ${e.description}';
      _isCameraInitialized = false;
      _isSwitchingCamera   = false;
      notifyListeners();
    } catch (e) {
      _cameraError         = 'Terjadi kesalahan kamera.\n${e.toString()}';
      _isCameraInitialized = false;
      _isSwitchingCamera   = false;
      notifyListeners();
    }
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

  Future<void> switchCamera() async {
    if (_isSwitchingCamera || _cameras == null || _cameras!.length < 2) return;
    _isSwitchingCamera   = true;
    _isCameraInitialized = false;
    notifyListeners();
    await _stopAndDisposeCamera();
    _isFrontCamera = !_isFrontCamera;
    await initCamera();
  }

  void clearCameraError() {
    _isPermissionDenied    = false;
    _isPermissionPermanent = false;
    _cameraError           = null;
    notifyListeners();
  }

  // Buka halaman pengaturan izin aplikasi (saat izin ditolak permanen).
  Future<void> openSettings() async {
    await openAppSettings();
  }

  // ── Image stream & deteksi ───────────────────────────────────
  void _processCameraImage(CameraImage image) {
    _frameCount++;
    final now = DateTime.now();

    if (now.difference(_lastFpsTime).inSeconds >= 1) {
      _fps        = _frameCount;
      _frameCount = 0;
      _lastFpsTime = now;
      notifyListeners();
    }

    if (!_isModelReady || _isDetecting) return;
    if (now.difference(_lastDetectionTime) < _detectionCooldown) return;

    _runDetection(image);
  }

  // Lacak transisi fase untuk haptic sekali per hasil baru.
  String _prevPhase = 'collect';

  Future<void> _runDetection(CameraImage image) async {
    _isDetecting        = true;
    _lastDetectionTime  = DateTime.now();
    final stopwatch     = Stopwatch()..start();

    try {
      final result = await _service.runInference(
        image,
        sensorOrientation:
            _cameraController?.description.sensorOrientation ?? 0,
        isFront: _isFrontCamera,
      );
      stopwatch.stop();
      _inferenceTimeMs = stopwatch.elapsedMilliseconds;

      _phase          = (result['phase'] ?? 'collect') as String;
      _remaining      = (result['remaining'] ?? 0.0) as double;
      _phaseDuration  = (result['phaseDuration'] ?? 5.0) as double;
      _poseOk         = (result['poseOk'] ?? false) as bool;
      _hands          = (result['hands'] ?? 0) as int;
      _framesCollected = (result['frames'] ?? 0) as int;
      _handFrames     = (result['handFrames'] ?? 0) as int;
      _top3           = (result['top3'] ?? const []) as List<dynamic>;
      _akurasi        = (result['confidence'] ?? 0.0) as double;

      if (_phase == 'hold') {
        final label    = (result['label'] ?? '') as String;
        _hasilDeteksi  = label.isEmpty ? 'Tidak terdeteksi' : label;
        _feedbackColor = _akurasi >= 0.6 ? Colors.green : Colors.orange;
        // Haptic sekali saat baru masuk fase hasil.
        if (_prevPhase != 'hold') HapticFeedback.mediumImpact();
      } else if (_phase == 'prepare') {
        _hasilDeteksi  = 'Bersiap...';
        _feedbackColor = Colors.amber;
        // Getar pelan tiap detik aba-aba (saat angka berubah).
        if (_prevPhase != 'prepare') HapticFeedback.selectionClick();
      } else if (_phase == 'collect') {
        _hasilDeteksi  = _poseOk ? 'Merekam gestur...' : 'Posisikan tubuh di kamera';
        _feedbackColor = _poseOk ? Colors.blue : Colors.orange;
      } else {
        _hasilDeteksi  = (result['label'] ?? 'Error') as String;
        _feedbackColor = Colors.red;
      }

      _prevPhase = _phase;
      notifyListeners();
    } catch (e) {
      debugPrint('Detection error: $e');
    } finally {
      _isDetecting = false;
    }
  }

  /// Mulai ulang siklus deteksi (fase collect dari awal) di server.
  Future<void> restartCycle() async {
    await _service.resetCycle();
    _phase           = 'prepare';
    _hasilDeteksi    = 'Bersiap...';
    _akurasi         = 0.0;
    _handFrames      = 0;
    _framesCollected = 0;
    _top3            = const [];
    _feedbackColor   = Colors.transparent;
    notifyListeners();
  }

  // ── Reconnect API ─────────────────────────────────────────────
  Future<void> retryConnection() async {
    _isModelReady = false;
    notifyListeners();
    final err     = await _service.loadModel();
    _isModelReady = _service.isInitialized;
    if (err == null) _hasilDeteksi = 'Bersiap...';
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopAndDisposeCamera();
    _service.dispose();
    super.dispose();
  }
}
