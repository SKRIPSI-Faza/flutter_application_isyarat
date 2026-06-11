import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'core/app_colors.dart';
import 'dashboard_page.dart';
import 'providers/detection_provider.dart';
import 'providers/theme_provider.dart';

class DeteksiPage extends StatefulWidget {
  const DeteksiPage({super.key});

  @override
  State<DeteksiPage> createState() => _DeteksiPageState();
}

class _DeteksiPageState extends State<DeteksiPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DetectionProvider>().initialize();
    });
  }

  // ── BUILD ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark   = context.watch<ThemeProvider>().isDarkMode;
    final provider = context.watch<DetectionProvider>();

    return Scaffold(
      backgroundColor: isDark ? AppColors.scaffoldDark : Colors.white,
      appBar: _buildAppBar(isDark),
      body: Column(
        children: [
          _buildResultPanel(provider, isDark),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildCameraView(provider),
                    _buildFeedbackBorder(provider),
                    if (provider.isCameraInitialized)
                      _buildDetectionIndicator(provider),
                    if (provider.isCameraInitialized)
                      _buildStatsOverlay(provider),
                    if (provider.isCameraInitialized &&
                        provider.cameras != null &&
                        provider.cameras!.length > 1)
                      _buildSwitchCameraButton(provider),
                    if (provider.isCameraInitialized && !provider.isModelReady)
                      _buildApiNotReadyOverlay(provider),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildBackButton(context),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ── AppBar ───────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios,
            color: isDark ? Colors.white70 : AppColors.primary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.back_hand_rounded,
                size: 14, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Text(
            'Deteksi Isyarat',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: isDark ? Colors.white : AppColors.textDark,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          tooltip: 'Ulangi siklus',
          icon: Icon(Icons.refresh_rounded,
              color: isDark ? Colors.white70 : AppColors.primary),
          onPressed: () => context.read<DetectionProvider>().restartCycle(),
        ),
      ],
    );
  }

  // ── Kamera ───────────────────────────────────────────────────

  Widget _buildCameraView(DetectionProvider provider) {
    if (provider.isCameraInitialized && provider.cameraController != null) {
      final controller = provider.cameraController!;
      // CameraPreview sudah menangani aspect-ratio & rotasi sendiri.
      // Cukup di-tengah-kan (Center) — JANGAN dipaksa isi penuh / ukuran tetap,
      // karena itu yang bikin preview gepeng / "ketarik ke atas".
      return Center(child: CameraPreview(controller));
    }
    if (provider.isPermissionDenied) {
      final permanent = provider.isPermissionPermanentlyDenied;
      return _buildStatusView(
        icon: Icons.no_photography_rounded,
        iconColor: Colors.red,
        title: 'Izin Kamera Ditolak',
        subtitle: permanent
            ? 'Izin kamera diblokir. Buka Pengaturan untuk mengizinkan akses kamera, lalu kembali ke halaman ini.'
            : 'Aplikasi perlu akses kamera untuk mendeteksi gestur. Izinkan kamera untuk melanjutkan.',
        actionLabel: permanent ? 'Buka Pengaturan' : 'Coba Lagi',
        onAction: permanent
            ? () => provider.openSettings()
            : () {
                provider.clearCameraError();
                provider.initCamera();
              },
      );
    }
    if (provider.cameraError != null) {
      return _buildStatusView(
        icon: Icons.error_outline_rounded,
        iconColor: Colors.orange,
        title: 'Kamera Error',
        subtitle: provider.cameraError!,
        actionLabel: 'Coba Lagi',
        onAction: () {
          provider.clearCameraError();
          provider.initCamera();
        },
      );
    }
    return _buildLoadingView();
  }

  Widget _buildFeedbackBorder(DetectionProvider provider) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        border: Border.all(
          color: provider.feedbackColor == Colors.green
              ? Colors.green.withValues(alpha: 0.8)
              : Colors.transparent,
          width: 4,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildSwitchCameraButton(DetectionProvider provider) {
    return Positioned(
      top: 12,
      right: 12,
      child: GestureDetector(
        onTap: provider.switchCamera,
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Icon(
            provider.isFrontCamera
                ? Icons.camera_rear
                : Icons.camera_front,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
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
                  color: Colors.white.withValues(alpha: 0.6),
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
                    backgroundColor: AppColors.primary,
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
            CircularProgressIndicator(color: AppColors.primary),
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

  Widget _buildApiNotReadyOverlay(DetectionProvider provider) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (provider.initError == null) ...[
                const CircularProgressIndicator(color: AppColors.primary),
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
                  'API tidak terhubung:\n${provider.initError}',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: provider.retryConnection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
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

  // ── Result panel ─────────────────────────────────────────────

  Widget _buildResultPanel(DetectionProvider provider, bool isDark) {
    final preparing  = provider.isPreparing;
    final collecting = provider.isCollecting;
    final isError    = provider.isError;

    // Progress fase: prepare & collect mengisi penuh, hold menyusut (hitung mundur).
    final double timeProgress = provider.phaseDuration <= 0
        ? 0.0
        : ((preparing || collecting)
            ? 1.0 - (provider.remaining / provider.phaseDuration)
            : provider.remaining / provider.phaseDuration);

    final Color accent = isError
        ? Colors.red
        : (preparing
            ? Colors.amber.shade700
            : (collecting
                ? (provider.poseOk ? Colors.blue : Colors.orange)
                : (provider.akurasi >= 0.6 ? Colors.green : Colors.orange)));

    final String phaseTitle = isError
        ? 'Koneksi'
        : (preparing
            ? 'Bersiap'
            : (collecting ? 'Rekam Gestur' : 'Hasil Prediksi'));
    final String headline = isError
        ? 'Tidak terhubung ke server'
        : (preparing
            ? 'Bersiap, angkat tangan...'
            : (collecting ? 'Lakukan gestur sekarang!' : 'Tahan sebentar'));
    final String subInfo = isError
        ? 'Cek server Flask & firewall (port 5000)'
        : (preparing
            ? 'Rekam mulai dalam ${provider.remaining.toStringAsFixed(1)}s'
            : (collecting
                ? '${provider.remaining.toStringAsFixed(1)}s  •  ${provider.framesCollected} frame'
                : 'Confidence: ${(provider.akurasi * 100).toStringAsFixed(1)}%  •  ${provider.remaining.toStringAsFixed(1)}s'));

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: provider.feedbackColor != Colors.transparent
              ? provider.feedbackColor
              : AppColors.primary.withValues(alpha: 0.25),
          width: provider.feedbackColor != Colors.transparent ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isError
                          ? Icons.wifi_off_rounded
                          : (preparing
                              ? Icons.hourglass_top_rounded
                              : (collecting
                                  ? Icons.fiber_manual_record
                                  : Icons.check_circle)),
                      size: 12,
                      color: accent,
                    ),
                    const SizedBox(width: 5),
                    Text(phaseTitle,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.grey[300]
                                : Colors.grey[700])),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  headline,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
                Text(subInfo, style: const TextStyle(fontSize: 11)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: timeProgress.clamp(0.0, 1.0),
                    backgroundColor: Colors.grey.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            constraints: const BoxConstraints(maxWidth: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent.withValues(alpha: 0.85), accent],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              isError
                  ? 'Offline'
                  : ((preparing || collecting)
                      ? '${provider.remaining.ceil()}'
                      : provider.hasilDeteksi),
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
    );
  }

  // ── Indikator deteksi hidup (pose + tangan) ───────────────────
  // Bukti real-time MediaPipe membaca tubuh & tangan, tanpa overlay
  // skeleton yang berat/lag. Update tiap frame dari response server.

  Widget _buildDetectionIndicator(DetectionProvider provider) {
    final poseOk    = provider.poseOk;
    final hands     = provider.hands;
    final handsOk   = hands > 0;
    final poseColor = poseOk ? Colors.greenAccent : Colors.orangeAccent;
    final handColor = handsOk ? Colors.greenAccent : Colors.white60;

    return Positioned(
      top: 12,
      left: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status pose
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(poseOk ? Icons.accessibility_new : Icons.person_off,
                    size: 13, color: poseColor),
                const SizedBox(width: 5),
                Text(
                  poseOk ? 'Tubuh terbaca' : 'Tubuh tdk terlihat',
                  style: TextStyle(
                      color: poseColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 3),
            // Status tangan (jumlah tangan terdeteksi live)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(handsOk ? Icons.front_hand : Icons.do_not_touch,
                    size: 13, color: handColor),
                const SizedBox(width: 5),
                Text(
                  handsOk ? 'Tangan: $hands' : 'Tangan tdk terlihat',
                  style: TextStyle(
                      color: handColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            // Saat fase rekam: bukti data tangan masuk ke model
            if (provider.isCollecting) ...[
              const SizedBox(height: 3),
              Text(
                '${provider.handFrames} frame tangan terekam',
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Stats overlay ─────────────────────────────────────────────

  Widget _buildStatsOverlay(DetectionProvider provider) {
    final fpsColor = provider.fps >= 20
        ? Colors.greenAccent
        : (provider.fps >= 10 ? Colors.orange : Colors.redAccent);
    return Positioned(
      bottom: 12,
      left: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'FPS: ${provider.fps}',
              style: TextStyle(
                color: fpsColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Inference: ${provider.inferenceTimeMs}ms',
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  // ── Back button ───────────────────────────────────────────────

  Widget _buildBackButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
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
            icon: const Icon(Icons.home_rounded, size: 20),
            label: Text(
              'Kembali ke Dashboard',
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ),
    );
  }
}
