import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'chatbot.dart';
import 'scan_page.dart';
import 'services/model_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'History.dart';

class AnalysisResultScreen extends StatelessWidget {
  final File imageFile;
  final ScanResult result;

  const AnalysisResultScreen({
    super.key,
    required this.imageFile,
    required this.result,
  });

  static const Color primaryGreen = Color(0xFF1F6B45);
  static const Color darkGreen = Color(0xFF17372A);
  static const Color backgroundColor = Color(0xFFF7F8F2);
  static const Color lightGreen = Color(0xFFEAF2E9);
  static const Color textGrey = Color(0xFF66756D);

  // Save scan to Firebase Storage and Firestore
  Future<void> _saveScan(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  String saveStage = 'Starting save';

  try {
    // 1. Check authentication
    saveStage = 'Checking user authentication';

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Please log in before saving a scan.');
    }

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Saving scan and uploading images...'),
      ),
    );

    // 2. Prepare Firestore document
    saveStage = 'Preparing Firestore document';

    final scans = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('scans');

    final scanDoc = scans.doc();

    final storage = FirebaseStorage.instance;
    final basePath = 'users/${user.uid}/scans/${scanDoc.id}';

    // 3. Generate XAI images if necessary
    ScanResult resultToSave = result;

    if (!result.isHealthy &&
        (result.heatmap == null || result.region == null)) {
      saveStage = 'Generating explanation images';

      resultToSave = await ModelService.explain(imageFile);
    }

    // 4. Prepare original image upload
    saveStage = 'Preparing original image';

    final extension = imageFile.path.split('.').last.toLowerCase();

    final safeExtension =
        ['jpg', 'jpeg', 'png', 'webp'].contains(extension)
            ? extension
            : 'jpg';

    final contentType = safeExtension == 'png'
        ? 'image/png'
        : safeExtension == 'webp'
            ? 'image/webp'
            : 'image/jpeg';

    final originalRef =
        storage.ref().child('$basePath/original.$safeExtension');

    // 5. Upload original image
    saveStage = 'Uploading original image';

    await originalRef.putFile(
      imageFile,
      SettableMetadata(contentType: contentType),
    );

    // 6. Get original image URL
    saveStage = 'Getting original image URL';

    final imageUrl = await originalRef.getDownloadURL();

    // 7. Upload Grad-CAM++ heatmap
    String? heatmapUrl;

    if (resultToSave.heatmap != null) {
      saveStage = 'Uploading Grad-CAM image';

      final heatmapRef = storage.ref().child('$basePath/gradcam.png');

      await heatmapRef.putData(
        resultToSave.heatmap!,
        SettableMetadata(contentType: 'image/png'),
      );

      saveStage = 'Getting Grad-CAM image URL';

      heatmapUrl = await heatmapRef.getDownloadURL();
    }

    // 8. Upload Region/Contours image
    String? regionUrl;

    if (resultToSave.region != null) {
      saveStage = 'Uploading Region image';

      final regionRef = storage.ref().child('$basePath/region.png');

      await regionRef.putData(
        resultToSave.region!,
        SettableMetadata(contentType: 'image/png'),
      );

      saveStage = 'Getting Region image URL';

      regionUrl = await regionRef.getDownloadURL();
    }

    // 9. Save scan information to Firestore
    saveStage = 'Saving Firestore document';

    await scanDoc.set({
      // Required by the current Firestore security rules.
      'label': result.diseaseName,
      'confidence': result.confidence,
      'isHealthy': result.isHealthy,
      'createdAt': FieldValue.serverTimestamp(),

      // Fields used by History.dart.
      'diseaseId': result.diseaseId,
      'diseaseName': result.diseaseName,
      'status': result.isHealthy ? 'healthy' : 'diseased',
      'predictions': result.toFirestore()['predictions'],

      // Uploaded image URLs.
      'imageUrl': imageUrl,
      'heatmapUrl': heatmapUrl,
      'regionUrl': regionUrl,
    });

    // 10. Navigate to History after successful save.
    if (!context.mounted) return;

    messenger.hideCurrentSnackBar();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const HistoryScreen(),
      ),
    );
  } on FirebaseException catch (e) {
    debugPrint('Failed stage: $saveStage');
    debugPrint('Firebase error code: ${e.code}');
    debugPrint('Firebase error message: ${e.message}');

    if (!context.mounted) return;

    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 8),
        content: Text(
          'Failed at: $saveStage\n'
          'Firebase error (${e.code}): ${e.message ?? "Unknown error"}',
        ),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('Failed stage: $saveStage');
    debugPrint('Save error: $e');
    debugPrintStack(stackTrace: stackTrace);

    if (!context.mounted) return;

    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 8),
        content: Text(
          'Failed at: $saveStage\nError: $e',
        ),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final isHealthy = result.isHealthy;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TOP BAR
              Row(
                children: [
                  _CircleIconButton(
                    icon: Icons.arrow_back_ios_new,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Analysis result',
                      style: TextStyle(
                        color: darkGreen,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ANALYZED IMAGE
              Container(
                height: 172,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: const Color(0xFFDDE7D9),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (result.heatmap != null)
                      Image.memory(
                        result.heatmap!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      )
                    else
                      Image.file(
                        imageFile,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: darkGreen.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 12,
                              color: Colors.white,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Analyzed just now',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // PREDICTION CARD
              _WhiteCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isHealthy
                                ? const Color(0xFFE4F2E5)
                                : const Color(0xFFFFF0DC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isHealthy
                                ? Icons.check_circle_outline
                                : Icons.priority_high_rounded,
                            color: isHealthy
                                ? primaryGreen
                                : const Color(0xFFF18B20),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PREDICTION',
                                style: TextStyle(
                                  color: textGrey,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                result.diseaseName,
                                style: const TextStyle(
                                  color: darkGreen,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Divider(color: Colors.grey.shade200, height: 1),
                    const SizedBox(height: 16),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'CONFIDENCE',
                                style: TextStyle(
                                  color: textGrey,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                result.confidenceText,
                                style: const TextStyle(
                                  color: darkGreen,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'SEVERITY',
                                style: TextStyle(
                                  color: textGrey,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: isHealthy
                                      ? const Color(0xFFE4F2E5)
                                      : const Color(0xFFFFEDD8),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isHealthy ? 'Healthy' : 'Needs assessment',
                                  style: TextStyle(
                                    color: isHealthy
                                        ? primaryGreen
                                        : const Color(0xFFD87518),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _ConfidenceCircle(
                          confidence: result.confidence,
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 49),
                              Text(
                                'PALM',
                                style: TextStyle(
                                  color: textGrey,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'New scan',
                                style: TextStyle(
                                  color: darkGreen,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (result.lowConfidence) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4DD),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'The model has low confidence in this prediction. '
                          'Try taking a clearer photo with better lighting.',
                          style: TextStyle(
                            color: Color(0xFF8A5A14),
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ABOUT THIS RESULT
              _WhiteCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(
                      title: isHealthy
                          ? 'About this result'
                          : 'About this disease',
                      icon: Icons.info_outline,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isHealthy
                          ? 'The model classified this image as a healthy '
                              'date palm leaf. Continue monitoring the palm '
                              'and scan it again if you notice any changes.'
                          : 'The AI model identified ${result.diseaseName} '
                              'in the submitted image. Review the palm '
                              'carefully and seek expert assessment to '
                              'confirm the diagnosis.',
                      style: const TextStyle(
                        color: textGrey,
                        fontSize: 11,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Model predictions',
                      style: TextStyle(
                        color: darkGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (result.predictions.isEmpty)
                      const Text(
                        'No additional predictions available.',
                        style: TextStyle(
                          color: textGrey,
                          fontSize: 11,
                        ),
                      )
                    else
                      ...result.predictions.take(3).map(
                        (prediction) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check,
                                color: primaryGreen,
                                size: 15,
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  prediction.name,
                                  style: const TextStyle(
                                    color: textGrey,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              Text(
                                prediction.scoreText,
                                style: const TextStyle(
                                  color: darkGreen,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // EFFECTS ON YOUR PALM
              _WhiteCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Effects on your palm',
                      style: TextStyle(
                        color: darkGreen,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isHealthy
                          ? 'No disease was identified by the model in this '
                              'image. Keep following good agricultural '
                              'practices and monitor new leaf growth.'
                          : 'The potential effects depend on the disease '
                              'and its severity. Monitor affected leaves '
                              'and other parts of the palm for changes.',
                      style: const TextStyle(
                        color: textGrey,
                        fontSize: 11,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // RECOMMENDED TREATMENT
              _WhiteCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recommended treatment & care',
                      style: TextStyle(
                        color: darkGreen,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _NumberedItem(
                      number: '1',
                      text: 'Inspect the palm leaves regularly.',
                    ),
                    _NumberedItem(
                      number: '2',
                      text: 'Take clear photos of any suspicious areas.',
                    ),
                    _NumberedItem(
                      number: '3',
                      text: 'Maintain appropriate irrigation and care.',
                    ),
                    _NumberedItem(
                      number: '4',
                      text: 'Seek agricultural expert advice if symptoms '
                          'persist or spread.',
                    ),
                    _NumberedItem(
                      number: '5',
                      text: 'Scan the palm again to monitor changes.',
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: lightGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            color: primaryGreen,
                            size: 15,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Recommended next step: monitor this palm '
                              'and scan it again if its condition changes.',
                              style: TextStyle(
                                color: primaryGreen,
                                fontSize: 10,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // DISCLAIMER
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    color: Color(0xFF9AA69E),
                    size: 14,
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'AI predictions are intended for preliminary '
                      'assessment and should not replace professional '
                      'agricultural diagnosis.',
                      style: TextStyle(
                        color: textGrey,
                        fontSize: 9,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // SAVE TO MY PALM
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => _saveScan(context),
                  icon: const Icon(
                    Icons.bookmark_border_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: const Text(
                    'Save to my palm',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ASK AI
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => ChatbotScreen(
                          diseaseId: result.diseaseId,
                          confidence: result.confidence,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: primaryGreen,
                    size: 19,
                  ),
                  label: const Text(
                    'Ask AI about this result',
                    style: TextStyle(
                      color: primaryGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey.shade200),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // SCAN AGAIN
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const ScanPage(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.camera_alt_outlined,
                    color: primaryGreen,
                    size: 19,
                  ),
                  label: const Text(
                    'Scan again',
                    style: TextStyle(
                      color: primaryGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey.shade200),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
}

// WHITE CARD
class _WhiteCard extends StatelessWidget {
  final Widget child;

  const _WhiteCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8ECE6),
        ),
      ),
      child: child,
    );
  }
}

// SECTION TITLE
class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AnalysisResultScreen.darkGreen,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Icon(
          icon,
          color: const Color(0xFF87938C),
          size: 17,
        ),
      ],
    );
  }
}

// NUMBERED ITEM
class _NumberedItem extends StatelessWidget {
  final String number;
  final String text;

  const _NumberedItem({
    required this.number,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0E8),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: AnalysisResultScreen.primaryGreen,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AnalysisResultScreen.textGrey,
                fontSize: 10,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// CONFIDENCE CIRCLE
class _ConfidenceCircle extends StatelessWidget {
  final double confidence;

  const _ConfidenceCircle({
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    final value = confidence.clamp(0.0, 1.0);

    return SizedBox(
      width: 58,
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 54,
            height: 54,
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: 5,
              backgroundColor: const Color(0xFFDDEBE0),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AnalysisResultScreen.primaryGreen,
              ),
            ),
          ),
          Text(
            '${(value * 100).round()}%',
            style: const TextStyle(
              color: AnalysisResultScreen.primaryGreen,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// CIRCLE ICON BUTTON
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFE3E8E1),
            ),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF5D6D64),
            size: 18,
          ),
        ),
      ),
    );
  }
}