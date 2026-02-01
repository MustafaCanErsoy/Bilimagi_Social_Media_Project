import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_typography.dart';
import '../widgets/app_logo.dart';

/// Welcome screen shown after successful login
/// Displays animated logo and personalized greeting before transitioning to main app
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    super.key,
    required this.displayName,
    required this.onComplete,
  });

  /// User's display name for personalized greeting
  final String displayName;

  /// Callback when welcome animation completes
  final VoidCallback onComplete;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _fadeOutController;

  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _fadeOutAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimationSequence();
  }

  void _setupAnimations() {
    // Logo animation (0-500ms)
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOut,
      ),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOutBack,
      ),
    );

    // Text animation (500-1000ms)
    _textController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOut,
      ),
    );

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Fade out animation (2000-2500ms)
    _fadeOutController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeOutAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _fadeOutController,
        curve: Curves.easeIn,
      ),
    );
  }

  void _startAnimationSequence() async {
    // Phase 1: Logo fade in + scale (0-500ms)
    await _logoController.forward();

    // Phase 2: Text fade in (500-1000ms)
    await _textController.forward();

    // Phase 3: Hold (1000-2000ms)
    await Future.delayed(const Duration(milliseconds: 1000));

    // Phase 4: Fade out (2000-2500ms)
    await _fadeOutController.forward();

    // Phase 5: Navigate to main screen
    widget.onComplete();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _fadeOutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _fadeOutController,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeOutAnimation.value,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: AppColors.splashGradient,
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    // Animated Logo
                    AnimatedBuilder(
                      animation: _logoController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _logoFadeAnimation.value,
                          child: Transform.scale(
                            scale: _logoScaleAnimation.value,
                            child: const AppLogo(
                              variant: LogoVariant.full,
                              showSlogan: false,
                              isDark: true,
                              size: 1.3,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 48),
                    // Animated Welcome Text
                    SlideTransition(
                      position: _textSlideAnimation,
                      child: FadeTransition(
                        opacity: _textFadeAnimation,
                        child: Column(
                          children: [
                            Text(
                              'Hoş geldin,',
                              style: AppTypography.h2.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.displayName,
                              style: AppTypography.h1.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(flex: 2),
                    // Subtle loading indicator
                    AnimatedBuilder(
                      animation: _textController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _textFadeAnimation.value * 0.5,
                          child: const _PulsingDots(),
                        );
                      },
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Pulsing dots loading indicator
class _PulsingDots extends StatefulWidget {
  const _PulsingDots();

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final value = (_controller.value - delay).clamp(0.0, 1.0);
            final opacity = (1 - (2 * value - 1).abs()).clamp(0.3, 1.0);

            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: opacity),
              ),
            );
          }),
        );
      },
    );
  }
}
