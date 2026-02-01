import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme.dart';
import '../core/theme_provider.dart';
import '../services/auth_service.dart';
import 'goodbye_screen.dart';

/// v4.0: Settings screen for user preferences
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: ListView(
        children: [
          // Theme Section
          _buildSectionHeader(context, 'Görünüm'),
          _buildThemeSelector(context, themeProvider),

          const SizedBox(height: 24),

          // Account Section
          _buildSectionHeader(context, 'Hesap'),
          _buildAccountInfo(context, authService),

          const SizedBox(height: 24),

          // App Info Section
          _buildSectionHeader(context, 'Uygulama'),
          _buildAppInfo(context),

          const SizedBox(height: 24),

          // Logout Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () => _showLogoutDialog(context, authService),
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                'Çıkış Yap',
                style: TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, ThemeProvider themeProvider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildThemeOption(
            context,
            themeProvider,
            ThemeMode.light,
            'Açık Tema',
            Icons.light_mode,
          ),
          const Divider(height: 1),
          _buildThemeOption(
            context,
            themeProvider,
            ThemeMode.dark,
            'Koyu Tema',
            Icons.dark_mode,
          ),
          const Divider(height: 1),
          _buildThemeOption(
            context,
            themeProvider,
            ThemeMode.system,
            'Sistem Ayarı',
            Icons.brightness_auto,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ThemeProvider themeProvider,
    ThemeMode mode,
    String title,
    IconData icon,
  ) {
    final isSelected = themeProvider.themeMode == mode;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppTheme.primaryColor : AppTheme.getTextSecondary(context),
      ),
      title: Text(title),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: AppTheme.primaryColor)
          : null,
      onTap: () => themeProvider.setThemeMode(mode),
    );
  }

  Widget _buildAccountInfo(BuildContext context, AuthService authService) {
    final user = authService.currentUser;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor,
          child: Text(
            user?.email?.substring(0, 1).toUpperCase() ?? '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(user?.email ?? 'Bilinmiyor'),
        subtitle: Text(
          'UID: ${user?.uid.substring(0, 8)}...',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.getTextTertiary(context),
          ),
        ),
      ),
    );
  }

  Widget _buildAppInfo(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.info_outline,
              color: AppTheme.getTextSecondary(context),
            ),
            title: const Text('Versiyon'),
            trailing: Text(
              'v7.1',
              style: TextStyle(color: AppTheme.getTextSecondary(context)),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.code,
              color: AppTheme.getTextSecondary(context),
            ),
            title: const Text('Flutter + Firebase'),
            trailing: Icon(
              Icons.check_circle,
              color: AppTheme.secondaryColor,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              // Get user display name before logout
              final user = authService.currentUser;
              String displayName = 'Kullanıcı';

              if (user != null) {
                try {
                  final doc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .get();
                  displayName = doc.data()?['displayName'] ??
                      user.displayName ??
                      'Kullanıcı';
                } catch (e) {
                  displayName = user.displayName ?? 'Kullanıcı';
                }
              }

              // Navigate to goodbye screen
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => GoodbyeScreen(displayName: displayName),
                  ),
                  (route) => false,
                );
              }
            },
            child: const Text(
              'Çıkış Yap',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
