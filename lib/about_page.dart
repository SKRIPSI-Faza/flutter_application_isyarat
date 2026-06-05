import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_colors.dart';
import 'providers/theme_provider.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    const Color primaryBlue = AppColors.primary;
    const Color darkBlue    = AppColors.primaryDark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: isDark ? Colors.white70 : AppColors.primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tentang Aplikasi',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.textDark,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [AppColors.bgDark1, AppColors.scaffoldDark]
                : [AppColors.bgLight, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.06,
          vertical: 24,
        ),
        child: Column(
          children: [
            // Logo
            Container(
              width: (screenWidth * 0.25).clamp(80.0, 120.0),
              height: (screenWidth * 0.25).clamp(80.0, 120.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primaryBlue, darkBlue],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: (screenWidth * 0.17).clamp(56.0, 84.0),
                  height: (screenWidth * 0.17).clamp(56.0, 84.0),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.bgDark2.withValues(alpha: 0.9)
                        : Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.back_hand_rounded,
                    size: (screenWidth * 0.1).clamp(32.0, 48.0),
                    color: primaryBlue,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Nama & versi
            Text(
              'SnapSign',
              style: TextStyle(
                fontSize: (screenWidth * 0.065).clamp(24.0, 32.0),
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.textDark,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'v1.0.0',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: primaryBlue,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Deskripsi
            _buildInfoCard(
              isDark: isDark,
              icon: Icons.info_outline_rounded,
              title: 'Deskripsi',
              content:
                  'Aplikasi deteksi gestur Bahasa Isyarat Indonesia secara real-time menggunakan kamera dengan Metode MobileNetV2 dan Temporal Shift Module.',
            ),

            const SizedBox(height: 14),

            // Teknologi
            _buildInfoCard(
              isDark: isDark,
              icon: Icons.memory_rounded,
              title: 'Teknologi',
              content:
                  'Flutter • MobileNetV2 • Temporal Shift Module (TSM) • Flask API',
            ),

            const SizedBox(height: 14),

            // Fitur
            _buildInfoCard(
              isDark: isDark,
              icon: Icons.star_rounded,
              title: 'Fitur Utama',
              content:
                  '• Deteksi gestur real-time\n• Mendukung 24 gesture BISINDO\n• Kamera depan & belakang\n• Mode gelap & terang',
            ),

            const SizedBox(height: 28),

            // Copyright
            Text(
              '© 2026 — All Rights Reserved',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white38 : Colors.grey[400],
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Made with ❤️ for accessibility',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white24 : Colors.grey[350],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildInfoCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : Colors.grey[600],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
