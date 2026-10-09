import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../main.dart' show LoginScreen;
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_bottom_nav.dart';
import 'about_page.dart';
import 'change_password_page.dart';
import 'edit_profile_page.dart';
import 'help_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const _SettingsHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  // Logged-in user's data (updates automatically)
                  StreamBuilder<User?>(
                    stream: AuthService().userChanges(),
                    builder: (context, snapshot) {
                      final user = snapshot.data;
                      final name = user?.displayName ?? '';
                      return _ProfileCard(
                        name: name.isEmpty ? 'User' : name,
                        email: user?.email ?? '',
                      );
                    },
                  ),
                  const SizedBox(height: 18),

                  SettingsTile(
                    icon: Icons.person_outline,
                    label: 'Edit Profile',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const EditProfilePage(),
                        ),
                      );
                    },
                  ),
                  SettingsTile(
                    icon: Icons.lock_outline,
                    label: 'Change Password',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const ChangePasswordPage(),
                        ),
                      );
                    },
                  ),
                  SettingsTile(
                    icon: Icons.info_outline,
                    label: 'About Saaf',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const AboutPage(),
                        ),
                      );
                    },
                  ),
                  SettingsTile(
                    icon: Icons.help_outline,
                    label: 'Help',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const HelpPage(),
                        ),
                      );
                    },
                  ),
                  SettingsTile(
                    icon: Icons.logout,
                    label: 'Log Out',
                    onTap: () async {
                      final confirmed = await showConfirmDialog(
                        context,
                        title: 'Log Out?',
                        message: 'Are you sure you want to log out?',
                        confirmLabel: 'Log Out',
                      );
                      if (!confirmed || !context.mounted) return;

                      await AuthService().logOut();
                      if (!context.mounted) return;
                      _goToLogin(context);
                    },
                  ),
                  SettingsTile(
                    icon: Icons.delete_outline,
                    label: 'Delete Account',
                    onTap: () async {
                      final confirmed = await showConfirmDialog(
                        context,
                        title: 'Delete Account?',
                        message:
                            'Are you sure you want to delete your account and data?',
                        confirmLabel: 'Delete',
                      );
                      if (!confirmed || !context.mounted) return;

                      try {
                        
                        await AuthService().deleteAccount();
                        if (!context.mounted) return;
                        _goToLogin(context);
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AuthService.errorMessage(e)),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavigationBar(current: NavTab.settings),
    );
  }
}

/// Page title at the top of the screen.
class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 56,
      child: Center(
        child: Text(
          'Settings',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Green card showing the user's name and email.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.name, required this.email});

  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.leafGreen,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: AppColors.cream,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline,
              color: AppColors.deepForest,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One row in the settings list: icon, label, and arrow.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(8),
        elevation: 1,
        shadowColor: const Color(0x22000000),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            child: Row(
              children: [
                Icon(icon, size: 22, color: AppColors.deepForest),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.deepForest,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens the Login page and removes all other pages,
/// so the back button can't return to the app.
void _goToLogin(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
    (route) => false,
  );
}

/// Popup asking the user to confirm an action.
/// Returns true if the user taps the confirm button.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textDark,
                      side: const BorderSide(color: AppColors.line),
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(confirmLabel),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );

  // Tapping outside the popup returns null, so treat it as Cancel
  return result ?? false;
}