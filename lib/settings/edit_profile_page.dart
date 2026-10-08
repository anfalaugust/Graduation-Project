import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'settings_widgets.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  bool _isSaving = false;

  // Message shown in the green box (null = hidden)
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    // Start with the logged-in user's current data
    final user = _auth.currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    // Ignore extra taps while saving
    if (_isSaving) return;

    // Close the keyboard
    FocusScope.of(context).unfocus();

    // Stop if any field is invalid (shows the red error)
    if (!_formKey.currentState!.validate()) return;

    final user = _auth.currentUser;
    final oldEmail = user?.email ?? '';
    final newName = _nameController.text.trim();
    final newEmail = _emailController.text.trim();
    final nameChanged = newName != (user?.displayName ?? '');
    final emailChanged = newEmail != oldEmail;

    if (!nameChanged && !emailChanged) {
      _showError('No changes to save.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (nameChanged) await _auth.updateName(newName);
      if (emailChanged) await _auth.updateEmail(newEmail);
      if (!mounted) return;

      setState(() {
        _successMessage = emailChanged
            ? 'We sent a confirmation link to $newEmail. '
                'Your email will change after you open it.'
            : 'Profile updated successfully';

        // The email only changes after the link is opened,
        // so show the current email until then
        if (emailChanged) _emailController.text = oldEmail;
      });

      // Hide the message after a few seconds
      Future.delayed(const Duration(seconds: 6), () {
        if (mounted) setState(() => _successMessage = null);
      });
    } catch (e) {
      if (!mounted) return;
      _showError(AuthService.errorMessage(e));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required';
    if (!email.contains('@')) return 'Enter a valid email';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SubPageHeader(title: 'Edit Profile'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_successMessage != null) ...[
                        SuccessBanner(message: _successMessage!),
                        const SizedBox(height: 20),
                      ],

                      // Profile picture placeholder
                      Center(
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: const BoxDecoration(
                            color: AppColors.cream,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            size: 46,
                            color: AppColors.deepForest,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      SettingsTextField(
                        label: 'Name',
                        controller: _nameController,
                        validator: _validateName,
                      ),
                      const SizedBox(height: 20),

                      SettingsTextField(
                        label: 'Email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 48),

                      SaveButton(
                        label: _isSaving ? 'Saving...' : 'Save Changes',
                        onPressed: _saveChanges,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const SettingsSubPageNavBar(),
    );
  }
}