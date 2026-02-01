import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../core/app_colors.dart';
import '../core/app_typography.dart';
import '../widgets/app_logo.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _error;

  // Animation controllers
  late AnimationController _logoController;
  late AnimationController _formController;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<Offset> _formSlideAnimation;
  late Animation<double> _formFadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    // Logo animation
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOut,
      ),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOutBack,
      ),
    );

    // Form animation
    _formController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _formSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _formController,
        curve: Curves.easeOutCubic,
      ),
    );

    _formFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _formController,
        curve: Curves.easeOut,
      ),
    );

    // Start animations
    _logoController.forward().then((_) {
      _formController.forward();
    });
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _authService.signUp(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );
      if (mounted) {
        // Show success message and navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hoş geldin, ${_nameController.text.trim()}!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _getErrorMessage(e.toString());
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('email-already-in-use')) {
      return 'Bu e-posta adresi zaten kullanılıyor';
    }
    if (error.contains('weak-password')) {
      return 'Şifre çok zayıf. En az 6 karakter kullanın';
    }
    if (error.contains('invalid-email')) {
      return 'Geçersiz e-posta adresi';
    }
    return 'Kayıt başarısız. Lütfen tekrar deneyin';
  }

  @override
  void dispose() {
    _logoController.dispose();
    _formController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.splashGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Kayıt Ol',
                      style: AppTypography.h3.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        // Animated Logo
                        AnimatedBuilder(
                          animation: _logoController,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _logoFadeAnimation.value,
                              child: Transform.scale(
                                scale: _logoScaleAnimation.value,
                                child: const AppLogo(
                                  variant: LogoVariant.compact,
                                  isDark: true,
                                  size: 1.0,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                        // Animated Form
                        SlideTransition(
                          position: _formSlideAnimation,
                          child: FadeTransition(
                            opacity: _formFadeAnimation,
                            child: _buildRegisterForm(),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Name Field
          _buildFloatingTextField(
            controller: _nameController,
            hintText: 'Kullanıcı Adı',
            icon: Icons.person_outlined,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Kullanıcı adı gerekli';
              }
              if (value.length < 2) {
                return 'Kullanıcı adı en az 2 karakter olmalı';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Email Field
          _buildFloatingTextField(
            controller: _emailController,
            hintText: 'E-posta',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'E-posta gerekli';
              }
              if (!value.contains('@') || !value.contains('.')) {
                return 'Geçerli bir e-posta girin';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Password Field
          _buildFloatingTextField(
            controller: _passwordController,
            hintText: 'Şifre',
            icon: Icons.lock_outlined,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.white70,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Şifre gerekli';
              }
              if (value.length < 6) {
                return 'Şifre en az 6 karakter olmalı';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Confirm Password Field
          _buildFloatingTextField(
            controller: _confirmPasswordController,
            hintText: 'Şifre Tekrar',
            icon: Icons.lock_outlined,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _register(),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.white70,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Şifre tekrarı gerekli';
              }
              if (value != _passwordController.text) {
                return 'Şifreler eşleşmiyor';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          // Error Message
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Register Button
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primary.withValues(alpha: 0.7),
                      ),
                    )
                  : Text(
                      'Kayıt Ol',
                      style: AppTypography.button.copyWith(
                        color: AppColors.primary,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          // Login Link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Zaten hesabın var mı?',
                style: AppTypography.body.copyWith(
                  color: Colors.white70,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'Giriş Yap',
                  style: AppTypography.button.copyWith(
                    color: Colors.white,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onFieldSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        textCapitalization: textCapitalization,
        obscureText: obscureText,
        onFieldSubmitted: onFieldSubmitted,
        style: AppTypography.body.copyWith(color: Colors.white),
        cursorColor: Colors.white,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTypography.body.copyWith(
            color: Colors.white60,
          ),
          prefixIcon: Icon(icon, color: Colors.white70),
          suffixIcon: suffixIcon,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          errorStyle: AppTypography.bodySmall.copyWith(
            color: Colors.white,
          ),
        ),
        validator: validator,
      ),
    );
  }
}
