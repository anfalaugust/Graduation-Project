import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'settings_widgets.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();

  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isSaving = false;
  bool _showSuccess = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    // Ignore extra taps while saving
    if (_isSaving) return;

    // Close the keyboard
    FocusScope.of(context).unfocus();

    // Stop if any field is invalid (shows the red error)
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _auth.changePassword(
        currentPassword: _currentController.text,
        newPassword: _newController.text,
      );
      if (!mounted) return;

      // Clear the fields after a successful change
      _currentController.clear();
      _newController.clear();
      _confirmController.clear();

      setState(() => _showSuccess = true);

      // Hide the success message after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showSuccess = false);
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      // Firebase returns one of these when the current password is wrong
      final wrongPassword =
          e.code == 'wrong-password' || e.code == 'invalid-credential';
      _showError(
        wrongPassword
            ? 'Current password is incorrect.'
            : AuthService.errorMessage(e),
      );
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

  String? _validateCurrent(String? value) {
    if (value == null || value.isEmpty) {
      return 'Current password is required';
    }
    return null;
  }

  String? _validateNew(String? value) {
    if (value == null || value.isEmpty) return 'New password is required';
    // Firebase requires at least 6 characters
    if (value.length < 6) return 'Password must be at least 6 characters';
    if (value == _currentController.text) {
      return 'New password must be different';
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != _newController.text) return 'Passwords do not match';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SubPageHeader(title: 'Change Password'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_showSuccess) ...[
                        const SuccessBanner(
                          message: 'Password changed successfully',
                        ),
                        const SizedBox(height: 20),
                      ] else
                        const SizedBox(height: 40),

                      SettingsTextField(
                        label: 'Current Password',
                        controller: _currentController,
                        obscureText: true,
                        validator: _validateCurrent,
                      ),
                      const SizedBox(height: 20),

                      SettingsTextField(
                        label: 'New Password',
                        controller: _newController,
                        obscureText: true,
                        validator: _validateNew,
                      ),
                      const SizedBox(height: 20),

                      SettingsTextField(
                        label: 'Confirm New Password',
                        controller: _confirmController,
                        obscureText: true,
                        validator: _validateConfirm,
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