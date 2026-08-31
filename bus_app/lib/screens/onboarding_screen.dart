import 'package:flutter/material.dart';
import '../theme/canal_colors.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  final _slides = [
    _OnboardingSlide(
      icon: Icons.directions_bus_rounded,
      title: 'Sabe exactamente\ncuándo llega tu bus',
      subtitle:
          'Ubicaciones GPS en tiempo real. No más suposiciones, no más esperas innecesarias.',
      color: CanalColors.primary,
    ),
    _OnboardingSlide(
      icon: Icons.people_rounded,
      title: 'Datos de\nla comunidad',
      subtitle:
          'Miles de usuarios comparten ubicación voluntariamente. Juntos construimos la red.',
      color: CanalColors.accent,
    ),
    _OnboardingSlide(
      icon: Icons.map_rounded,
      title: 'Navega\ncon confianza',
      subtitle:
          'Rutas optimizadas, alertas en vivo y la información más precisa para moverte en la ciudad.',
      color: CanalColors.secondary,
    ),
  ];

  void _goNext() {
    if (_currentPage < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CanalColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button (top-right)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_currentPage < _slides.length - 1)
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const HomeScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Omitir',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: CanalColors.lightTextMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // PageView slides
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _slides.length,
                itemBuilder: (_, i) => _buildSlide(_slides[i]),
              ),
            ),
            // Bottom bar: animated dots + next button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(_slides.length, (i) {
                      final isActive = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: isActive ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: isActive
                              ? CanalColors.primary
                              : CanalColors.lightBorder,
                        ),
                      );
                    }),
                  ),
                  ElevatedButton(
                    onPressed: _goNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CanalColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentPage < _slides.length - 1
                              ? 'Siguiente'
                              : 'Comenzar',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, size: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(_OnboardingSlide slide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 1),
          // Dark card with icon
          Container(
            height: 280,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: CanalColors.darkBackground,
            ),
            child: Center(
              child: Icon(
                slide.icon,
                size: 80,
                color: slide.color.withValues(alpha: 0.6),
              ),
            ),
          ),
          const Spacer(flex: 1),
          // Slide counter badge
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: slide.color.withValues(alpha: 0.12),
                ),
                child: Icon(slide.icon, size: 16, color: slide.color),
              ),
              const SizedBox(width: 10),
              Text(
                '${_currentPage + 1} de ${_slides.length}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: CanalColors.lightTextMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Title
          Text(
            slide.title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.15,
              color: CanalColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          // Subtitle
          Text(
            slide.subtitle,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: CanalColors.lightTextSecondary,
            ),
          ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }
}

class _OnboardingSlide {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}
