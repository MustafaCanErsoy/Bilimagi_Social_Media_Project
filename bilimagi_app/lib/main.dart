import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/welcome_screen.dart';
import 'core/theme.dart';
import 'core/theme_provider.dart';
import 'core/app_colors.dart';
import 'widgets/app_logo.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider()..initialize(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Bilimagi',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: '/',
            routes: {
              '/': (context) => const AuthWrapper(),
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper>
    with SingleTickerProviderStateMixin {
  bool _showSplash = true;
  bool _showWelcome = false;
  String? _displayName;
  bool _needsWelcome = true; // Always show welcome on login

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() => _showSplash = false);
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleNewLogin(User user) async {
    // Get user's display name for welcome message
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final displayName =
          doc.data()?['displayName'] ?? user.displayName ?? 'Kullanıcı';

      if (mounted) {
        setState(() {
          _displayName = displayName;
          _showWelcome = true;
          _needsWelcome = false;
        });
      }
    } catch (e) {
      // If profile fetch fails, use fallback name
      if (mounted) {
        setState(() {
          _displayName = user.displayName ?? 'Kullanıcı';
          _showWelcome = true;
          _needsWelcome = false;
        });
      }
    }
  }

  void _onWelcomeComplete() {
    if (mounted) {
      setState(() {
        _showWelcome = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show splash while loading or during initial animation
        if (_showSplash || snapshot.connectionState == ConnectionState.waiting) {
          return _buildSplashScreen();
        }

        final user = snapshot.data;

        // User logged out - show login screen
        if (user == null) {
          return const LoginScreen();
        }

        // New login detected - show welcome screen
        if (_needsWelcome && !_showWelcome) {
          // Schedule the welcome screen setup
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _needsWelcome && !_showWelcome) {
              _handleNewLogin(user);
            }
          });

          // Show loading while fetching profile
          return _buildSplashScreen();
        }

        // Show welcome screen
        if (_showWelcome && _displayName != null) {
          return WelcomeScreen(
            displayName: _displayName!,
            onComplete: _onWelcomeComplete,
          );
        }

        return const MainNavigationScreen();
      },
    );
  }

  Widget _buildSplashScreen() {
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
              const Spacer(flex: 2),
              AnimatedBuilder(
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
                        size: 1.3,
                      ),
                    ),
                  );
                },
              ),
              const Spacer(flex: 2),
              AnimatedOpacity(
                opacity: _controller.isCompleted ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: const _LoadingIndicator(),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingIndicator extends StatefulWidget {
  const _LoadingIndicator();

  @override
  State<_LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<_LoadingIndicator>
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
