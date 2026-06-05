import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import '../core/app_constants.dart';

class DetectionService {
  static const String apiBaseUrl = AppConstants.apiBaseUrl;

  // Header wajib untuk ngrok free tier — tanpa ini ngrok serve HTML bukan JSON.
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  };

  static Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$apiBaseUrl/health'), headers: _headers)
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  bool _isInitialized = false;
  String? _initError;

  String? get initError => _initError;
  bool get isInitialized => _isInitialized;

  Future<String?> loadModel() async {
    try {
      final response = await http
          .get(Uri.parse('$apiBaseUrl/health'), headers: _headers)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw Exception('API timeout'),
          );

      if (response.statusCode == 200) {
        _isInitialized = true;
        _initError = null;
        debugPrint('✅ Connected to Flask API');
        return null;
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      _isInitialized = false;
      _initError = e.toString();
      debugPrint('❌ API connection error: $_initError');
      return _initError;
    }
  }

  /// Kirim satu frame ke server skeleton. Server mengelola siklus
  /// collect→predict→hold, jadi response berisi fase + hitung mundur.
  Future<Map<String, dynamic>> runInference(
    CameraImage image, {
    int sensorOrientation = 0,
    bool isFront = true,
  }) async {
    if (!_isInitialized) {
      return {'phase': 'error', 'label': 'API Not Ready', 'confidence': 0.0};
    }

    try {
      // Ekstrak ke _CameraData (plain Dart object) sebelum kirim ke isolate
      final data = _CameraData.fromCameraImage(
        image,
        sensorOrientation: sensorOrientation,
        isFront: isFront,
      );
      final jpegBytes = await compute(_convertDataToJpeg, data);
      if (jpegBytes == null) {
        return {'phase': 'error', 'label': 'Frame Error', 'confidence': 0.0};
      }

      final base64Image = base64Encode(jpegBytes);

      debugPrint(
        '[FRAME] Kirim frame | ukuran=${jpegBytes.length} bytes'
        ' | base64=${base64Image.length} chars',
      );

      final response = await http
          .post(
            Uri.parse('$apiBaseUrl/predict'),
            headers: _headers,
            body: json.encode({
              'frame': base64Image,
              'client_id': 'flutter_mobile',
            }),
          )
          .timeout(
            const Duration(seconds: 12),
            onTimeout: () => throw Exception('Request timeout'),
          );

      if (response.statusCode == 200) {
        final j = json.decode(response.body) as Map<String, dynamic>;
        debugPrint(
          '[RESP] phase=${j['phase']} | remaining=${j['remaining']} '
          '| pose_ok=${j['pose_ok']} | hands=${j['hands']} '
          '| frames=${j['frames']} | label=${j['label']}',
        );
        return {
          'phase': (j['phase'] ?? 'collect') as String,
          'remaining': ((j['remaining'] ?? 0.0) as num).toDouble(),
          'phaseDuration': ((j['phase_duration'] ?? 5.0) as num).toDouble(),
          'label': (j['label'] ?? '') as String,
          'confidence': ((j['confidence'] ?? 0.0) as num).toDouble() / 100.0,
          'top3': (j['top3'] as List?) ?? const [],
          'poseOk': (j['pose_ok'] ?? false) as bool,
          'hands': (j['hands'] ?? 0) as int,
          'frames': (j['frames'] ?? 0) as int,
          'handFrames': (j['hand_frames'] ?? 0) as int,
        };
      } else {
        return {'phase': 'error', 'label': 'Server Error', 'confidence': 0.0};
      }
    } catch (e) {
      debugPrint('Inference error: $e');
      return {'phase': 'error', 'label': 'Error', 'confidence': 0.0};
    }
  }

  /// Reset siklus deteksi di server (mulai fase collect dari awal).
  Future<void> resetCycle() async {
    if (!_isInitialized) return;
    try {
      await http
          .post(
            Uri.parse('$apiBaseUrl/reset'),
            headers: _headers,
            body: json.encode({'client_id': 'flutter_mobile'}),
          )
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('Reset error: $e');
    }
  }

  void dispose() {
    _isInitialized = false;
  }
}

// ── Data class yang aman dikirim ke isolate ──────────────────
class _CameraData {
  final List<Uint8List> planes;
  final List<int> bytesPerRow;
  final List<int> bytesPerPixel;
  final int width;
  final int height;
  final int formatGroupIndex;
  final int sensorOrientation;
  final bool isFront;

  _CameraData({
    required this.planes,
    required this.bytesPerRow,
    required this.bytesPerPixel,
    required this.width,
    required this.height,
    required this.formatGroupIndex,
    required this.sensorOrientation,
    required this.isFront,
  });

  factory _CameraData.fromCameraImage(
    CameraImage image, {
    required int sensorOrientation,
    required bool isFront,
  }) {
    return _CameraData(
      // Uint8List.fromList() menyalin bytes ke memori Dart murni
      planes: image.planes.map((p) => Uint8List.fromList(p.bytes)).toList(),
      bytesPerRow: image.planes.map((p) => p.bytesPerRow).toList(),
      bytesPerPixel:
          image.planes.map((p) => p.bytesPerPixel ?? 1).toList(),
      width: image.width,
      height: image.height,
      formatGroupIndex:
          ImageFormatGroup.values.indexOf(image.format.group),
      sensorOrientation: sensorOrientation,
      isFront: isFront,
    );
  }
}

/// Target sisi terpanjang gambar yang dikirim ke server.
/// 480px: cukup detail untuk MediaPipe mendeteksi tangan dengan akurat.
const int _kTargetLong = 480;

/// Hitung faktor downsample (step) agar sisi terpanjang ≈ _kTargetLong.
int _downsampleStep(int w, int h) {
  final int longSide = w >= h ? w : h;
  final int step = (longSide / _kTargetLong).round();
  return step < 1 ? 1 : step;
}

// ── Top-level function untuk compute() isolate ──────────────
Uint8List? _convertDataToJpeg(_CameraData data) {
  try {
    final formatGroup = ImageFormatGroup.values[data.formatGroupIndex];

    final img.Image rgbImage;
    if (formatGroup == ImageFormatGroup.yuv420) {
      rgbImage = _yuv420DataToImage(data);
    } else if (formatGroup == ImageFormatGroup.bgra8888) {
      rgbImage = _bgra8888DataToImage(data);
    } else if (formatGroup == ImageFormatGroup.nv21) {
      rgbImage = _nv21DataToImage(data);
    } else {
      rgbImage = _yuv420DataToImage(data);
    }

    // Putar agar tegak (gambar sudah kecil → rotasi murah). Byte mentah kamera
    // ada dalam orientasi sensor (landscape); tanpa rotasi orang tampak "tidur".
    img.Image upright = rgbImage;
    final int rot = ((data.sensorOrientation % 360) + 360) % 360;
    if (rot == 90) {
      upright = img.copyRotate(rgbImage, angle: 90);
    } else if (rot == 180) {
      upright = img.copyRotate(rgbImage, angle: 180);
    } else if (rot == 270) {
      upright = img.copyRotate(rgbImage, angle: 270);
    }

    // Front camera Android mengirim data sensor yang ter-mirror horizontal.
    // Flip agar orientasi kiri/kanan sama dengan webcam (data training).
    if (data.isFront) {
      upright = img.flipHorizontal(upright);
    }

    return Uint8List.fromList(img.encodeJpg(upright, quality: 90));
  } catch (e) {
    return null;
  }
}

/// YUV420 (Android standar) → RGB, langsung di-downsample (step).
img.Image _yuv420DataToImage(_CameraData data) {
  final int width = data.width;
  final int height = data.height;

  final yBytes = data.planes[0];
  final uBytes = data.planes[1];
  final vBytes = data.planes[2];

  final int yRowStride = data.bytesPerRow[0];
  final int uvRowStride = data.bytesPerRow[1];
  final int uvPixelStride = data.bytesPerPixel[1];

  final int step = _downsampleStep(width, height);
  final int outW = width ~/ step;
  final int outH = height ~/ step;
  final output = img.Image(width: outW, height: outH);

  for (int oy = 0; oy < outH; oy++) {
    final int y = oy * step;
    for (int ox = 0; ox < outW; ox++) {
      final int x = ox * step;
      final int yIndex = y * yRowStride + x;
      final int uvIndex = (y >> 1) * uvRowStride + (x >> 1) * uvPixelStride;

      final int yp = yBytes[yIndex];
      final int up = uBytes[uvIndex];
      final int vp = vBytes[uvIndex];

      // BT.601 YUV→RGB
      final int r = (yp + (vp - 128) * 1436 ~/ 1024).clamp(0, 255);
      final int g = (yp -
              (up - 128) * 46549 ~/ 131072 -
              (vp - 128) * 93604 ~/ 131072)
          .clamp(0, 255);
      final int b = (yp + (up - 128) * 1814 ~/ 1024).clamp(0, 255);

      output.setPixelRgb(ox, oy, r, g, b);
    }
  }

  return output;
}

/// NV21 (beberapa Android) → RGB, langsung di-downsample (step).
img.Image _nv21DataToImage(_CameraData data) {
  final int width = data.width;
  final int height = data.height;

  final yBytes = data.planes[0];
  final vuBytes = data.planes[1]; // NV21: V then U interleaved
  final int yRowStride = data.bytesPerRow[0];
  final int uvRowStride = data.bytesPerRow[1];

  final int step = _downsampleStep(width, height);
  final int outW = width ~/ step;
  final int outH = height ~/ step;
  final output = img.Image(width: outW, height: outH);

  for (int oy = 0; oy < outH; oy++) {
    final int y = oy * step;
    for (int ox = 0; ox < outW; ox++) {
      final int x = ox * step;
      final int yIndex = y * yRowStride + x;
      final int uvIndex = (y >> 1) * uvRowStride + (x & ~1);

      final int yp = yBytes[yIndex];
      final int vp = vuBytes[uvIndex]; // NV21: V first
      final int up = vuBytes[uvIndex + 1]; // then U

      final int r = (yp + (vp - 128) * 1436 ~/ 1024).clamp(0, 255);
      final int g = (yp -
              (up - 128) * 46549 ~/ 131072 -
              (vp - 128) * 93604 ~/ 131072)
          .clamp(0, 255);
      final int b = (yp + (up - 128) * 1814 ~/ 1024).clamp(0, 255);

      output.setPixelRgb(ox, oy, r, g, b);
    }
  }

  return output;
}

/// BGRA8888 (iOS) → RGB, lalu di-resize ke target.
img.Image _bgra8888DataToImage(_CameraData data) {
  final full = img.Image.fromBytes(
    width: data.width,
    height: data.height,
    bytes: data.planes[0].buffer,
    order: img.ChannelOrder.bgra,
  );
  final int longSide = full.width >= full.height ? full.width : full.height;
  if (longSide <= _kTargetLong) return full;
  return full.width >= full.height
      ? img.copyResize(full, width: _kTargetLong)
      : img.copyResize(full, height: _kTargetLong);
}
