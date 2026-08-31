import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/canal_colors.dart';
import '../theme/living_theme.dart';
import 'onboarding_screen.dart';
import 'splash_painter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Phase 1: Glow trace (0→1 over 1800ms)
  late final AnimationController _glowCtrl = AnimationController(
    duration: const Duration(milliseconds: 1800),
    vsync: this,
  );

  // Phase 2: Text fill solidify (0→1 over 500ms, starts at 1500ms)
  late final AnimationController _fillCtrl = AnimationController(
    duration: const Duration(milliseconds: 500),
    vsync: this,
  );

  // Phase 3: Bus icon entrance (0→1 over 600ms, starts at 2000ms)
  late final AnimationController _busCtrl = AnimationController(
    duration: const Duration(milliseconds: 600),
    vsync: this,
  );

  bool _textVisible = false;
  bool _busVisible = false;
  bool _navigating = false;

  TextPainter? _textPainter;

  @override
  void initState() {
    super.initState();
    _glowCtrl.addListener(() => setState(() {}));
    _fillCtrl.addListener(() => setState(() {}));
    _busCtrl.addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Build TextPainter for "Transita"
      _textPainter = TextPainter(
        text: TextSpan(
          text: 'Transita',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 56,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Check for reduced motion — skip animation
      final mq = MediaQuery.of(context);
      if (mq.accessibleNavigation || mq.disableAnimations) {
        _glowCtrl.value = 1.0;
        _fillCtrl.value = 1.0;
        _busCtrl.value = 1.0;
        _textVisible = true;
        _busVisible = true;
        _navigateToOnboarding();
        return;
      }

      // Start the glow trace
      _glowCtrl.forward();

      // Text fill begins at 1500ms
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        setState(() => _textVisible = true);
        _fillCtrl.forward();
      });

      // Bus icon appears at 2000ms
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (!mounted) return;
        setState(() => _busVisible = true);
        _busCtrl.forward();
      });

      // Navigate to onboarding at 3200ms
      _navigateToOnboarding();
    });
  }

  void _navigateToOnboarding() {
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (!mounted || _navigating) return;
      _navigating = true;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => OnboardingScreen(),
          transitionsBuilder: (_, a, _, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    });
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _fillCtrl.dispose();
    _busCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<LivingTheme>().isDark;
    final bg = isDark ? CanalColors.darkBackground : CanalColors.primary;

    // Glow progress drives the light trail
    final glowProgress = Curves.easeInOut.transform(_glowCtrl.value);

    // Fill opacity fades in after glow reaches ~60%
    final fillOpacity =
        _glowCtrl.value > 0.6 ? ((_glowCtrl.value - 0.6) / 0.4).clamp(0.0, 1.0) : 0.0;

    // Bus icon: fade + scale + slide up
    final busOpacity = _busCtrl.value;
    final busScale = 0.7 + 0.3 * Curves.easeOutBack.transform(_busCtrl.value);
    final busSlideY = 20 * (1 - Curves.easeOut.transform(_busCtrl.value));

    return Scaffold(
      body: Container(
        color: bg,
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // Subtle radial vignette
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.8,
                    colors: [
                      Colors.transparent,
                      (isDark ? Colors.black : const Color(0xFF003366))
                          .withValues(alpha: 0.2),
                    ],
                  ),
                ),
              ),
            ),

            // "Transita" text with light trail
            if (_textPainter != null)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _glowCtrl,
                  builder: (context, _) => CustomPaint(
                    painter: TransitaLightTrailPainter(
                      glowProgress: glowProgress,
                      textPainter: _textPainter!,
                      isDark: isDark,
                    ),
                  ),
                ),
              ),

            // Solid text overlay (fades in after glow)
            if (_textPainter != null && _textVisible)
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: fillOpacity,
                  duration: const Duration(milliseconds: 400),
                  child: Center(
                    child: Text(
                      'Transita',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 56,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),

            // Bus icon entrance
            if (_busVisible)
              Positioned.fill(
                child: Center(
                  child: Transform.translate(
                    offset: Offset(0, 60 + busSlideY),
                    child: Transform.scale(
                      scale: busScale,
                      child: AnimatedOpacity(
                        opacity: busOpacity,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.white.withValues(alpha: 0.15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.1),
                                blurRadius: 24,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.directions_bus_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
