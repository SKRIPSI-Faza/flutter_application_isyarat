import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'deteksi_page.dart';
import 'providers/theme_provider.dart';

class CameraPreviewPage extends StatefulWidget {
  const CameraPreviewPage({super.key});

  @override
  State<CameraPreviewPage> createState() => _CameraPreviewPageState();
}

class _CameraPreviewPageState extends State<CameraPreviewPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    const Color lightBlue = Color(0xFF4FC3F7);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Persiapan Deteksi'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.06,
            vertical: screenHeight * 0.02,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Icon kamera
              Container(
                padding: EdgeInsets.all(screenWidth * 0.06),
                decoration: BoxDecoration(
                  color: lightBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  size: (screenWidth * 0.14).clamp(48.0, 72.0),
                  color: lightBlue,
                ),
              ),

              SizedBox(height: screenHeight * 0.03),

              // Judul
              Text(
                'Mulai Deteksi Gestur',
                style: TextStyle(
                  fontSize: (screenWidth * 0.055).clamp(20.0, 26.0),
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),

              SizedBox(height: screenHeight * 0.015),

              // Penjelasan singkat
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                child: Text(
                  'Aplikasi akan mengakses kamera untuk mendeteksi gestur tangan secara real-time.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: (screenWidth * 0.035).clamp(13.0, 16.0),
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    height: 1.5,
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // Tombol Mulai Deteksi
              SizedBox(
                width: double.infinity,
                height: (screenHeight * 0.065).clamp(50.0, 60.0),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _startDetection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: lightBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Mulai Deteksi',
                          style: TextStyle(
                            fontSize: (screenWidth * 0.042).clamp(16.0, 20.0),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              SizedBox(height: screenHeight * 0.015),

              // Teks izin kamera
              Text(
                'Kamera akan diaktifkan setelah Anda menekan tombol di atas',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: (screenWidth * 0.03).clamp(11.0, 13.0),
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                ),
              ),

              SizedBox(height: screenHeight * 0.04),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startDetection() async {
    setState(() => _isLoading = true);

    // Simulasi loading sebentar
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DeteksiPage()),
      );
    }
  }
}