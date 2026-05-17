# TFLite Sign Detection API - Dokumentasi

## 📋 Daftar Isi
1. [Instalasi](#instalasi)
2. [Inisialisasi](#inisialisasi)
3. [Penggunaan Dasar](#penggunaan-dasar)
4. [API Reference](#api-reference)
5. [Contoh Implementasi](#contoh-implementasi)
6. [Troubleshooting](#troubleshooting)

---

## 🔧 Instalasi

### Step 1: Siapkan Model
```
flutter_application_isyarat/
├── assets/
│   └── models/
│       └── model_float16.tflite  ← Copy file model di sini
```

### Step 2: Update Dependencies
Dependencies sudah ditambahkan ke `pubspec.yaml`:
- `tflite_flutter: ^0.10.4` - TensorFlow Lite interpreter
- `image: ^4.0.0` - Image processing

Jalankan:
```bash
flutter pub get
```

---

## 🚀 Inisialisasi

### 1. Inisialisasi API (Singleton Pattern)
```dart
import 'services/sign_detection_api.dart';

// Inisialisasi satu kali saat app dimulai
await SignDetectionAPI().initialize(
  mode: DetectionMode.letter, // atau DetectionMode.word
  useTFLite: true, // gunakan TFLite model
);
```

### 2. Cleanup Saat Dispose
```dart
@override
void dispose() {
  SignDetectionAPI().dispose();
  super.dispose();
}
```

---

## 📖 Penggunaan Dasar

### Deteksi dari Camera Frame
```dart
void _startFrameProcessing() {
  _cameraController.startImageStream((CameraImage image) async {
    try {
      final result = await SignDetectionAPI().detectFrame(image);
      
      print('Label: ${result.label}');
      print('Accuracy: ${result.accuracy}%');
      
      setState(() {
        _lastDetection = result;
      });
    } catch (e) {
      print('Error: $e');
    }
  });
}
```

---

## 📚 API Reference

### `SignDetectionAPI` (Singleton)

#### Methods

**`initialize()`**
```dart
Future<void> initialize({
  required DetectionMode mode,      // letter atau word
  bool useTFLite = true,            // gunakan model atau dummy
})
```
Inisialisasi API dan load model.

**`detectFrame()`**
```dart
Future<SignDetectionResult> detectFrame(CameraImage image)
```
Process frame dari kamera dan return hasil deteksi.

**`dispose()`**
```dart
Future<void> dispose()
```
Cleanup dan release resources.

**`isInitialized`** (getter)
```dart
bool get isInitialized
```
Check apakah API sudah diinisialisasi.

---

### `SignDetectionResult`

```dart
class SignDetectionResult {
  final String label;         // Hasil deteksi (A, B, C, dll)
  final double accuracy;      // Confidence 0-100
  
  const SignDetectionResult({
    required this.label,
    required this.accuracy,
  });
}
```

---

### `DetectionMode` Enum

```dart
enum DetectionMode { 
  letter,  // Deteksi huruf (A-Z)
  word,    // Deteksi kata (MAKAN, MINUM, dll)
}
```

---

## 💡 Contoh Implementasi Lengkap

### Minimal Implementation
```dart
import 'package:camera/camera.dart';
import 'services/sign_detection_api.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class DetectionPage extends StatefulWidget {
  @override
  State<DetectionPage> createState() => _DetectionPageState();
}

class _DetectionPageState extends State<DetectionPage> {
  late CameraController _cameraController;
  SignDetectionResult? _result;

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.first;

    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController.initialize();

    // Inisialisasi API
    await SignDetectionAPI().initialize(
      mode: DetectionMode.letter,
      useTFLite: true,
    );

    // Start streaming
    _cameraController.startImageStream(_processFrame);

    setState(() {});
  }

  Future<void> _processFrame(CameraImage image) async {
    try {
      final result = await SignDetectionAPI().detectFrame(image);
      setState(() => _result = result);
    } catch (e) {
      print('Detection error: $e');
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    SignDetectionAPI().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CameraPreview(_cameraController),
          Positioned(
            top: 20,
            left: 20,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text('Label: ${_result?.label ?? '--'}'),
                    Text('Akurasi: ${_result?.accuracy.toStringAsFixed(1) ?? '--'}%'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 🛠️ Troubleshooting

### ❌ Model Not Found
**Error:** `AssetNotFound: assets/models/model_float16.tflite`

**Solusi:**
1. Copy file `model_float16.tflite` ke `assets/models/`
2. Pastikan sudah di-update di `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/models/model_float16.tflite
```
3. Jalankan `flutter pub get`

---

### ❌ TFLite Not Initialized
**Error:** `SignDetectionAPI not initialized. Call initialize() first.`

**Solusi:**
```dart
// Pastikan initialize() dipanggil sebelum detectFrame()
await SignDetectionAPI().initialize(
  mode: DetectionMode.letter,
  useTFLite: true,
);
```

---

### ❌ Out of Memory
**Error:** `Out of memory / ENOMEM`

**Solusi:**
- Reduce frame rate: Process setiap 2-3 frame, bukan semua frame
- Reduce resolution: Gunakan `ResolutionPreset.low` atau `medium`

```dart
void _processFrame(CameraImage image) async {
  if (_frameCount++ % 2 != 0) return; // Process setiap 2 frame
  
  try {
    final result = await SignDetectionAPI().detectFrame(image);
    setState(() => _result = result);
  } catch (e) {
    print('Detection error: $e');
  }
}
```

---

### ❌ GPU Delegate Issues (Optional)
Jika encounter masalah dengan GPU:

```dart
// Di TFLiteDetectionService.initialize()
InterpreterOptions()
  ..threads = 4
  ..useGpuDelegate = false  // Disable GPU
  ..useNnApiDelegate = false
```

---

## 📊 Konfigurasi Model

Edit di `lib/services/tflite_detection_service.dart`:

```dart
// Sesuaikan dengan model Anda
static const int modelInputSize = 224;        // Input image size
static const int modelOutputClasses = 22;     // Jumlah kelas output

// Update list label sesuai model Anda
static const List<String> letterLabels = [
  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'K',
  'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'V',
  'W', 'Y'
];
```

---

## 📱 Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Android  | ✅ Supported | Tested |
| iOS      | ✅ Supported | Tested |
| Web      | ❌ Not Supported | TFLite tidak support web |
| Windows  | ⚠️ Limited | Perlu konfigurasi tambahan |

---

## 🎯 Best Practices

1. **Inisialisasi satu kali**
   ```dart
   // ✅ Baik - Gunakan Singleton
   await SignDetectionAPI().initialize(...);
   
   // ❌ Jangan - Inisialisasi berkali-kali
   ```

2. **Handle frame rate**
   ```dart
   // Process hanya frame yang perlu
   if (_isDetecting) return;
   _isDetecting = true;
   // ... process frame
   _isDetecting = false;
   ```

3. **Error handling**
   ```dart
   try {
     final result = await SignDetectionAPI().detectFrame(image);
   } catch (e) {
     print('Detection failed: $e');
     // Fallback to dummy service or retry
   }
   ```

4. **Cleanup resources**
   ```dart
   @override
   void dispose() {
     SignDetectionAPI().dispose();  // Always cleanup
     super.dispose();
   }
   ```

---

## 🔗 Referensi
- [TensorFlow Lite Flutter](https://pub.dev/packages/tflite_flutter)
- [Camera Package](https://pub.dev/packages/camera)
- [Image Processing](https://pub.dev/packages/image)

---

**Dibuat untuk:** SkripsiIsyarat - Sign Language Detection  
**Last Updated:** April 2026
