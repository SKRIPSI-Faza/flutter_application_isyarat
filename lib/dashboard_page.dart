import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'camera_preview_page.dart';
import 'settings_page.dart';
import 'dictionary_page.dart';
import 'providers/theme_provider.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    const Color primaryBlue = Color(0xFF4FC3F7);
    const Color darkBlue = Color(0xFF0288D1);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0D1B2A), const Color(0xFF1B2838)]
                : [const Color(0xFFF0F8FF), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header dengan logo & settings
              _buildHeader(context, primaryBlue, darkBlue, isDark),

              // Konten utama
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // Greeting card
                      _buildGreetingCard(isDark, primaryBlue),

                      const SizedBox(height: 20),

                      // Grid menu utama (2x2)
                      _buildMainMenu(context, isDark, primaryBlue, darkBlue),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, Color primaryBlue, Color darkBlue, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      child: Row(
        children: [
          // Logo kecil
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryBlue, darkBlue],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1B2838).withOpacity(0.9)
                      : Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.back_hand_rounded,
                  size: 18,
                  color: Color(0xFF4FC3F7),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Nama aplikasi
          Text(
            'SnapSign',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              letterSpacing: 0.8,
            ),
          ),

          const Spacer(),

          // Settings button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsPage(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.settings_rounded,
                  size: 22,
                  color: isDark ? Colors.white54 : Colors.grey[600],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingCard(bool isDark, Color primaryBlue) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryBlue.withOpacity(isDark ? 0.15 : 0.1),
            primaryBlue.withOpacity(isDark ? 0.05 : 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryBlue.withOpacity(isDark ? 0.15 : 0.1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat Datang! 👋',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Deteksi bahasa isyarat Indonesia secara real-time dengan kamera.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.grey[600],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(isDark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.sign_language_rounded,
              size: 36,
              color: primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainMenu(
      BuildContext context, bool isDark, Color primaryBlue, Color darkBlue) {
    return Column(
      children: [
        // Card Deteksi — besar & menonjol
        _buildDetectionCard(context, isDark, primaryBlue, darkBlue),

        const SizedBox(height: 16),

        // Label seksi
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Fitur Lainnya',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: isDark ? Colors.white38 : Colors.grey[500],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // 2 menu card besar berdampingan
        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                context,
                icon: Icons.menu_book_rounded,
                title: 'Kamus Isyarat',
                subtitle: 'Jelajahi koleksi\ngestur BISINDO',
                color: const Color(0xFFFF8A65),
                isDark: isDark,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DictionaryPage(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildFeatureCard(
                context,
                icon: Icons.lightbulb_rounded,
                title: 'Panduan',
                subtitle: 'Cara menggunakan\naplikasi ini',
                color: const Color(0xFFFFB300),
                isDark: isDark,
                onTap: () => _showPanduanDialog(context, isDark),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetectionCard(
      BuildContext context, bool isDark, Color primaryBlue, Color darkBlue) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CameraPreviewPage(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: screenWidth * 0.07,
            horizontal: screenWidth * 0.06,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryBlue, darkBlue],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withOpacity(isDark ? 0.35 : 0.3),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: (screenWidth * 0.09).clamp(32.0, 44.0),
                ),
              ),
              SizedBox(width: screenWidth * 0.04),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mulai Deteksi',
                      style: TextStyle(
                        fontSize: (screenWidth * 0.055).clamp(20.0, 26.0),
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Arahkan kamera ke gestur tangan',
                      style: TextStyle(
                        fontSize: (screenWidth * 0.032).clamp(12.0, 15.0),
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withOpacity(0.7),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withOpacity(isDark ? 0.2 : 0.15),
            ),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(isDark ? 0.18 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.5,
                  color: isDark ? Colors.white38 : Colors.grey[500],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Buka',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 14, color: color),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPanduanDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lightbulb_rounded, color: Color(0xFFFFB300)),
            SizedBox(width: 10),
            Expanded(
              child: Text('Panduan Deteksi'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPanduanStep('1', 'Tekan tombol "Mulai Deteksi"'),
            const SizedBox(height: 10),
            _buildPanduanStep('2', 'Izinkan akses kamera jika diminta'),
            const SizedBox(height: 10),
            _buildPanduanStep(
                '3', 'Arahkan kamera ke tangan yang sedang berisyarat'),
            const SizedBox(height: 10),
            _buildPanduanStep('4', 'Hasil deteksi akan muncul secara otomatis'),
            const SizedBox(height: 10),
            _buildPanduanStep(
                '5', 'Gunakan tombol switch untuk ganti kamera depan/belakang'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  Widget _buildPanduanStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFFFFB300).withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFB300),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
        ),
      ],
    );
  }

}
