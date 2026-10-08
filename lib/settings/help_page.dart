import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'settings_widgets.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SubPageHeader(title: 'Help'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                children: const [
                  // Add more sections here later if needed
                  HelpSection(
                    title: 'How to scan a date palm leaf',
                    steps: [
                      HelpStep(
                        title: 'Start a scan',
                        description:
                            'On the Home page, tap "Diagnose Now".',
                      ),
                      HelpStep(
                        title: 'Choose a photo',
                        description:
                            'Take a new photo or select one from your gallery. '
                            'Make sure the date palm leaf is clear and well lit.',
                      ),
                      HelpStep(
                        title: 'View the result',
                        description:
                            'Wait for the scan to finish. The result shows whether '
                            'the leaf is healthy or diseased. If it is diseased, '
                            'the result shows the predicted disease.',
                      ),
                      HelpStep(
                        title: 'View the visual explanation',
                        description:
                            'Tap "View Explanation" to see a heatmap. The highlighted '
                            'areas show which parts of the photo influenced the '
                            "model's prediction.",
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const SettingsSubPageNavBar(),
    );
  }
}

/// One step inside a help section.
class HelpStep {
  const HelpStep({required this.title, required this.description});

  final String title;
  final String description;
}

/// A question that opens and closes to show numbered steps.
class HelpSection extends StatefulWidget {
  const HelpSection({super.key, required this.title, required this.steps});

  final String title;
  final List<HelpStep> steps;

  @override
  State<HelpSection> createState() => _HelpSectionState();
}

class _HelpSectionState extends State<HelpSection> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Question row
        Material(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(8),
          elevation: 1,
          shadowColor: const Color(0x22000000),
          child: InkWell(
            onTap: () => setState(() => _isOpen = !_isOpen),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Arrow turns upside down when the section is open
                  AnimatedRotation(
                    turns: _isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.deepForest,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Steps box (only shown when open)
        if (_isOpen) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.leafGreen.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < widget.steps.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i == widget.steps.length - 1 ? 0 : 16,
                    ),
                    child: _StepItem(number: i + 1, step: widget.steps[i]),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Numbered circle, step title, and description.
class _StepItem extends StatelessWidget {
  const _StepItem({required this.number, required this.step});

  final int number;
  final HelpStep step;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.deepForest, width: 1.5),
              ),
              child: Text(
                '$number',
                style: const TextStyle(
                  color: AppColors.deepForest,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                step.title,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          step.description,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 12,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}