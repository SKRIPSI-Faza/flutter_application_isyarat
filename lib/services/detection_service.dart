import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

class DetectionService {
  // ── Ganti dengan IP Flask server Anda ───────────────────
  // Contoh: 'http://192.168.1.100:5000'
  static const String apiBaseUrl = 'http://192.168.1.100:5000';

  bool _isInitialized = false;
  String? _initError;

  String? get initError => _initError;
  bool get isInitialized => _isInitialized;

  // ── Health check / ping API ──────────────────────────────
  Future<String?> loadModel() async {
    try {
      final response = await http
          .get(Uri.parse('$apiBaseUrl/health'))
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

  // ── Inference ────────────────────────────────────────────
  Future<Map<String, dynamic>> runInference(CameraImage image) async {
    if (!_isInitialized) {
      return {'label': 'API Not Ready', 'confidence': 0.0};
    }

    try {
      // Konversi CameraImage → JPEG di isolate terpisah agar tidak block UI
      final jpegBytes = await compute(_convertImageToJpegIsolate, image);
      if (jpegBytes == null) {
        return {'label': 'Frame Error', 'confidence': 0.0};
      }

      final base64Image = base64Encode(jpegBytes);

      final response = await http
          .post(
            Uri.parse('$apiBaseUrl/predict'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'frame': base64Image,
              'client_id': 'flutter_mobile',
            }),
          )
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw Exception('Request timeout'),
          );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return {
          'label': jsonResponse['label'] ?? 'Unknown',
          'confidence':
              ((jsonResponse['confidence'] ?? 0.0) / 100.0).toDouble(),
        };
      } else {
        return {'label': 'Server Error', 'confidence': 0.0};
      }
    } catch (e) {
      debugPrint('Inference error: $e');
      return {'label': 'Error', 'confidence': 0.0};
    }
  }

  void dispose() {
    _isInitialized = false;
  }
}

// ── Top-level function untuk compute() isolate ──────────────
// Harus top-level (bukan method) agar bisa dijalankan di isolate terpisah.
Uint8List? _convertImageToJpegIsolate(CameraImage image) {
  try {
    img.Image? rgbImage;

    if (image.format.group == ImageFormatGroup.yuv420) {
      rgbImage = _yuv420ToImage(image);
    } else if (image.format.group == ImageFormatGroup.bgra8888) {
      rgbImage = _bgra8888ToImage(image);
    } else if (image.format.group == ImageFormatGroup.nv21) {
      rgbImage = _nv21ToImage(image);
    }

    if (rgbImage == null) return null;

    // Resize ke 224×224 untuk model
    final resized = img.copyResize(rgbImage, width: 224, height: 224);
    return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
  } catch (e) {
    return null;
  }
}

/// YUV420 (Android biasa) → RGB
img.Image _yuv420ToImage(CameraImage image) {
  final int width = image.width;
  final int height = image.height;

  final yPlane = image.planes[0];
  final uPlane = image.planes[1];
  final vPlane = image.planes[2];

  final yBytes = yPlane.bytes;
  final uBytes = uPlane.bytes;
  final vBytes = vPlane.bytes;

  final int yRowStride = yPlane.bytesPerRow;
  final int uvRowStride = uPlane.bytesPerRow;
  final int uvPixelStride = uPlane.bytesPerPixel ?? 1;

  final output = img.Image(width: width, height: height);

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
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

      output.setPixelRgb(x, y, r, g, b);
    }
  }

  return output;
}

/// NV21 (beberapa Android) → RGB
img.Image _nv21ToImage(CameraImage image) {
  final int width = image.width;
  final int height = image.height;

  final yBytes = image.planes[0].bytes;
  final vuBytes = image.planes[1].bytes; // NV21: V then U interleaved
  final int yRowStride = image.planes[0].bytesPerRow;
  final int uvRowStride = image.planes[1].bytesPerRow;

  final output = img.Image(width: width, height: height);

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final int yIndex = y * yRowStride + x;
      final int uvIndex = (y >> 1) * uvRowStride + (x & ~1);

      final int yp = yBytes[yIndex];
      final int vp = vuBytes[uvIndex];       // NV21: V first
      final int up = vuBytes[uvIndex + 1];   // then U

      final int r = (yp + (vp - 128) * 1436 ~/ 1024).clamp(0, 255);
      final int g = (yp -
              (up - 128) * 46549 ~/ 131072 -
              (vp - 128) * 93604 ~/ 131072)
          .clamp(0, 255);
      final int b = (yp + (up - 128) * 1814 ~/ 1024).clamp(0, 255);

      output.setPixelRgb(x, y, r, g, b);
    }
  }

  return output;
}

/// BGRA8888 (iOS) → RGB
img.Image _bgra8888ToImage(CameraImage image) {
  return img.Image.fromBytes(
    width: image.width,
    height: image.height,
    bytes: image.planes[0].bytes.buffer,
    order: img.ChannelOrder.bgra,
  );
}
