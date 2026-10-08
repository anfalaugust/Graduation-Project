import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'settings_widgets.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SubPageHeader(title: 'About Saaf'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Column(
                  children: [
                    // App logo (shows a leaf icon if the image is missing)
                    Image.asset(
                      'assets/images/splash_palm.png',
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.eco,
                        size: 120,
                        color: AppColors.forest,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'saaf',
                      style: TextStyle(
                        color: AppColors.forest,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 22,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Saaf uses AI to analyze date palm leaf images, '
                        'identify possible diseases, and visually explain '
                        'its predictions.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.forest,
                          fontSize: 15,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
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