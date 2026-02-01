import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_typography.dart';

/// Logo variants for different use cases
enum LogoVariant {
  /// Full logo: icon + "BİLİMAĞI" + slogan
  full,

  /// Compact logo: icon + "BİLİMAĞI"
  compact,

  /// Icon only: biotech icon
  iconOnly,

  /// Text only: "BİLİMAĞI"
  textOnly,
}

/// Bilimagi branded logo widget
/// Supports multiple variants and color schemes
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.variant = LogoVariant.compact,
    this.size,
    this.color,
    this.showSlogan = false,
    this.isDark = false,
  });

  /// Logo variant to display
  final LogoVariant variant;

  /// Size multiplier (default: 1.0)
  /// Affects icon and text proportionally
  final double? size;

  /// Custom color override
  /// If null, uses primary color (light bg) or white (dark bg)
  final Color? color;

  /// Show slogan text (only for full variant)
  final bool showSlogan;

  /// Use dark mode styling (white text)
  final bool isDark;

  double get _scale => size ?? 1.0;

  Color get _logoColor {
    if (color != null) return color!;
    return isDark ? Colors.white : AppColors.primary;
  }

  Color get _sloganColor {
    if (color != null) return color!.withValues(alpha: 0.8);
    return isDark
        ? Colors.white.withValues(alpha: 0.8)
        : AppColors.lightTextSecondary;
  }

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case LogoVariant.full:
        return _buildFullLogo();
      case LogoVariant.compact:
        return _buildCompactLogo();
      case LogoVariant.iconOnly:
        return _buildIconOnly();
      case LogoVariant.textOnly:
        return _buildTextOnly();
    }
  }

  Widget _buildFullLogo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLogoIcon(64 * _scale),
        SizedBox(height: 16 * _scale),
        _buildLogoText(),
        if (showSlogan) ...[
          SizedBox(height: 8 * _scale),
          _buildSlogan(),
        ],
      ],
    );
  }

  Widget _buildCompactLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLogoIcon(40 * _scale),
        SizedBox(width: 12 * _scale),
        _buildLogoText(isSmall: true),
      ],
    );
  }

  Widget _buildIconOnly() {
    return _buildLogoIcon(48 * _scale);
  }

  Widget _buildTextOnly() {
    return _buildLogoText();
  }

  /// DNA/Biotech icon with gradient background
  Widget _buildLogoIcon(double iconSize) {
    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.2),
                  Colors.white.withValues(alpha: 0.1),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.secondary,
                ],
              ),
        borderRadius: BorderRadius.circular(iconSize * 0.25),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Icon(
        Icons.biotech,
        size: iconSize * 0.55,
        color: Colors.white,
      ),
    );
  }

  Widget _buildLogoText({bool isSmall = false}) {
    final baseFontSize = isSmall ? 28.0 : 36.0;

    return Text(
      'BİLİMAĞI',
      style: TextStyle(
        fontSize: baseFontSize * _scale,
        fontWeight: FontWeight.w800,
        color: _logoColor,
        letterSpacing: 3.0 * _scale,
        height: 1.0,
      ),
    );
  }

  Widget _buildSlogan() {
    return Text(
      'Bilimsel Tartışma',
      style: AppTypography.slogan.copyWith(
        color: _sloganColor,
        fontSize: (AppTypography.slogan.fontSize ?? 14) * _scale,
        letterSpacing: 1.0,
      ),
    );
  }
}

/// Animated logo for splash screen
class AnimatedAppLogo extends StatefulWidget {
  const AnimatedAppLogo({
    super.key,
    this.onAnimationComplete,
  });

  final VoidCallback? onAnimationComplete;

  @override
  State<AnimatedAppLogo> createState() => _AnimatedAppLogoState();
}

class _AnimatedAppLogoState extends State<AnimatedAppLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward().then((_) {
      widget.onAnimationComplete?.call();
    });
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
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: const AppLogo(
              variant: LogoVariant.full,
              showSlogan: true,
              isDark: true,
              size: 1.2,
            ),
          ),
        );
      },
    );
  }
}
