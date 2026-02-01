import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_typography.dart';
import '../widgets/app_logo.dart';
import '../services/auth_service.dart';

/// Goodbye screen shown before logout
/// Displays animated logo and farewell message before signing out
class GoodbyeScreen extends StatefulWidget {
  const GoodbyeScreen({
    super.key,
    required this.displayName,
  });

  /// User's display name for personalized farewell
  final String displayName;

  @override
  State<GoodbyeScreen> createState() => _GoodbyeScreenState();
}

class _GoodbyeScreenState extends State<GoodbyeScreen>
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
    // Logo animation (0-400ms)
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOut,
      ),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOutBack,
      ),
    );

    // Text animation (400-800ms)
    _textController = AnimationController(
      duration: const Duration(milliseconds: 400),
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

    // Fade out animation
    _fadeOutController = AnimationController(
      duration: const Duration(milliseconds: 400),
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
    // Phase 1: Logo fade in + scale
    await _logoController.forward();

    // Phase 2: Text fade in
    await _textController.forward();

    // Phase 3: Hold
    await Future.delayed(const Duration(milliseconds: 800));

    // Phase 4: Fade out
    await _fadeOutController.forward();

    // Phase 5: Sign out
    await AuthService().signOut();

    // Phase 6: Restart app to go back to AuthWrapper
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
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
                    // Animated Goodbye Text
                    SlideTransition(
                      position: _textSlideAnimation,
                      child: FadeTransition(
                        opacity: _textFadeAnimation,
                        child: Column(
                          children: [
                            Text(
                              'Hoşça kal,',
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
                            const SizedBox(height: 16),
                            Text(
                              'Tekrar görüşmek üzere!',
                              style: AppTypography.body.copyWith(
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(flex: 2),
                    // Wave icon
                    AnimatedBuilder(
                      animation: _textController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _textFadeAnimation.value * 0.7,
                          child: const Icon(
                            Icons.waving_hand,
                            color: Colors.white,
                            size: 32,
                          ),
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
