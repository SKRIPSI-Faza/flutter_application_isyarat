import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dashboard_page.dart';
import 'providers/theme_provider.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _titleFade;
  late Animation<double> _taglineFade;
  late Animation<double> _buttonSlide;
  late Animation<double> _buttonFade;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
      ),
    );

    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.5, 0.75, curve: Curves.easeOut),
      ),
    );

    _buttonFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    _buttonSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    const Color lightBlue = Color(0xFF4FC3F7);
    const Color darkBlue = Color(0xFF0288D1);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Ukuran responsif
    final logoSize = screenWidth * 0.32;
    final logoInnerSize = logoSize * 0.7;
    final iconSize = logoSize * 0.37;
    final titleSize = screenWidth * 0.085;
    final taglineSize = screenWidth * 0.038;
    final buttonHeight = screenHeight * 0.065;
    final horizontalPadding = screenWidth * 0.1;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF0D1B2A),
                    const Color(0xFF1B2838),
                    const Color(0xFF0D1B2A),
                  ]
                : [
                    Colors.white,
                    const Color(0xFFF0F8FF),
                    Colors.white,
                  ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Dekorasi lingkaran atas
              Positioned(
                top: -60,
                right: -40,
                child: Container(
                  width: screenWidth * 0.45,
                  height: screenWidth * 0.45,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        lightBlue.withOpacity(isDark ? 0.15 : 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Dekorasi lingkaran bawah
              Positioned(
                bottom: -40,
                left: -30,
                child: Container(
                  width: screenWidth * 0.35,
                  height: screenWidth * 0.35,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        darkBlue.withOpacity(isDark ? 0.12 : 0.06),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Konten utama — pakai Flex agar responsive
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: screenHeight * 0.06),

                    // Logo
                    FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: child,
                            );
                          },
                          child: Container(
                            width: logoSize.clamp(100.0, 160.0),
                            height: logoSize.clamp(100.0, 160.0),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [lightBlue, darkBlue],
                              ),
                              borderRadius:
                                  BorderRadius.circular(logoSize * 0.25),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      lightBlue.withOpacity(isDark ? 0.4 : 0.3),
                                  blurRadius: 24,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Container(
                                width: logoInnerSize.clamp(70.0, 110.0),
                                height: logoInnerSize.clamp(70.0, 110.0),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1B2838).withOpacity(0.9)
                                      : Colors.white.withOpacity(0.92),
                                  borderRadius:
                                      BorderRadius.circular(logoSize * 0.18),
                                ),
                                child: Icon(
                                  Icons.back_hand_rounded,
                                  size: iconSize.clamp(36.0, 56.0),
                                  color: lightBlue,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.04),

                    // Nama aplikasi
                    FadeTransition(
                      opacity: _titleFade,
                      child: Text(
                        'SnapSign',
                        style: TextStyle(
                          fontSize: titleSize.clamp(28.0, 40.0),
                          fontWeight: FontWeight.w800,
                          color:
                              isDark ? Colors.white : const Color(0xFF1A1A2E),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.012),

                    // Tagline singkat
                    FadeTransition(
                      opacity: _taglineFade,
                      child: Text(
                        'Bahasa Isyarat Indonesia.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: taglineSize.clamp(14.0, 18.0),
                          fontWeight: FontWeight.w400,
                          color: isDark ? Colors.white54 : Colors.grey[500],
                          letterSpacing: 0.5,
                          height: 1.4,
                        ),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.08),

                    // Tombol Get Started
                    AnimatedBuilder(
                      animation: _mainController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _buttonFade.value,
                          child: Transform.translate(
                            offset: Offset(0, _buttonSlide.value),
                            child: child,
                          ),
                        );
                      },
                      child: SizedBox(
                        width: double.infinity,
                        height: buttonHeight.clamp(50.0, 62.0),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (_, __, ___) =>
                                    const DashboardPage(),
                                transitionsBuilder: (_, anim, __, child) {
                                  return FadeTransition(
                                    opacity: anim,
                                    child: child,
                                  );
                                },
                                transitionDuration:
                                    const Duration(milliseconds: 400),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: lightBlue,
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shadowColor: lightBlue.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Get Started',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.06),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
