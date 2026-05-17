import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';

class GuidePage extends StatelessWidget {
  const GuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    const Color primaryBlue = Color(0xFF4FC3F7);
    final screenWidth = MediaQuery.of(context).size.width;

    final steps = [
      {
        'icon': Icons.touch_app_rounded,
        'title': 'Tekan "Mulai Deteksi"',
        'desc': 'Buka menu Deteksi dari halaman utama.',
      },
      {
        'icon': Icons.camera_alt_rounded,
        'title': 'Izinkan Akses Kamera',
        'desc': 'Berikan izin kamera saat diminta oleh sistem.',
      },
      {
        'icon': Icons.pan_tool_rounded,
        'title': 'Arahkan ke Gestur Tangan',
        'desc': 'Posisikan tangan di tengah frame kamera.',
      },
      {
        'icon': Icons.auto_awesome_rounded,
        'title': 'Hasil Otomatis',
        'desc': 'Hasil deteksi akan muncul secara real-time.',
      },
      {
        'icon': Icons.cameraswitch_rounded,
        'title': 'Ganti Kamera',
        'desc': 'Gunakan tombol switch untuk kamera depan/belakang.',
      },
    ];

    final tips = [
      {'icon': Icons.wb_sunny_rounded, 'text': 'Pastikan pencahayaan cukup terang'},
      {'icon': Icons.front_hand_rounded, 'text': 'Tangan harus terlihat jelas di frame'},
      {'icon': Icons.speed_rounded, 'text': 'Lakukan gestur secara perlahan'},
      {'icon': Icons.contrast_rounded, 'text': 'Hindari latar belakang yang terlalu ramai'},
    ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Panduan Deteksi'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05,
          vertical: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Cara Menggunakan',
              style: TextStyle(
                fontSize: (screenWidth * 0.055).clamp(20.0, 26.0),
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ikuti langkah-langkah berikut untuk memulai deteksi bahasa isyarat.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white54 : Colors.grey[600],
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            // Steps
            ...List.generate(steps.length, (index) {
              final step = steps[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nomor + garis
                    Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [primaryBlue, Color(0xFF0288D1)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        if (index < steps.length - 1)
                          Container(
                            width: 2,
                            height: 32,
                            color: primaryBlue.withOpacity(0.2),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Konten
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.06)
                                : Colors.grey.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              step['icon'] as IconData,
                              color: primaryBlue,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    step['title'] as String,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    step['desc'] as String,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.white38 : Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),

            // Tips section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.amber.withOpacity(0.06)
                    : Colors.amber.withOpacity(0.06),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.amber.withOpacity(0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_rounded, size: 18, color: Colors.amber[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Tips Agar Lebih Akurat',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...tips.map((tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Icon(
                          tip['icon'] as IconData,
                          size: 16,
                          color: isDark ? Colors.white38 : Colors.grey[500],
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            tip['text'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white54 : Colors.grey[600],
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
