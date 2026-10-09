import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'services/model_service.dart';

import 'theme/app_colors.dart';
import 'widgets/app_bottom_nav.dart';

import 'analysis_result_screen.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool _cameraMode = false;

  // The photo the user picked from the gallery (null = no photo yet)
  File? _selectedImage;

  final ImagePicker _picker = ImagePicker();

  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    // Wake the model server early so the first analysis is faster
    ModelService.wakeUp();
  }

    Future<void> _pickImage(ImageSource source) async {
           final XFile? picked = await _picker.pickImage(
         source: source,
         maxWidth: 600,
         imageQuality: 70,
       );

    // The user closed the gallery or camera without choosing a photo
    if (picked == null) return;

    setState(() => _selectedImage = File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Scan',
          style: TextStyle(
            color: AppColors.forest,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              const Text(
                'Scan a palm leaf',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: AppColors.forest,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Choose a photo from your device or take a new one',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 36),

              // Upload and Camera switch
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    _modeButton(
                      title: 'Upload',
                      selected: !_cameraMode,
                      onTap: () => setState(() => _cameraMode = false),
                    ),
                    _modeButton(
                      title: 'Camera',
                      selected: _cameraMode,
                      onTap: () => setState(() => _cameraMode = true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

                            // The large preview box changes with the selected mode
              Container(
                height: 340,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: _cameraMode
                      ? const Color(0xFF222222)
                      : const Color(0xFFF0F5EA),
                  borderRadius: BorderRadius.circular(28),
                  border: _cameraMode
                      ? null
                      : Border.all(color: AppColors.forest, width: 2),
                ),
                child: _buildPreview(),
              ),
              const SizedBox(height: 32),

              // These buttons are visual only for now
              SizedBox(
                height: 74,
                child: ElevatedButton.icon(
                                    // Open the camera or the gallery depending on the mode
                  onPressed: () => _pickImage(
                    _cameraMode ? ImageSource.camera : ImageSource.gallery,
                  ),
                  icon: Icon(
                    _cameraMode
                        ? Icons.camera_alt_outlined
                        : Icons.photo_library_outlined,
                  ),
                  label: Text(
                    _cameraMode ? 'Take a photo' : 'Browse files',
                    style: const TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forest,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

                            // Analyze button (only shown after choosing a photo)
              if (_selectedImage != null) ...[
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: _isAnalyzing ? null : _analyzeImage,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.orange.withValues(alpha: 0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: _isAnalyzing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Analyze',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // Photo tips
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Photo tips',
                      style: TextStyle(
                        color: AppColors.forest,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 14),
                    Text('• Take a clear photo of the leaf.'),
                    SizedBox(height: 6),
                    Text('• Make sure the lighting is good.'),
                    SizedBox(height: 6),
                    Text('• Make sure the whole leaf is visible in the photo.'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavigationBar(current: NavTab.scan),
    );
  }

    
Future<void> _analyzeImage() async {
  final image = _selectedImage;
  if (image == null || _isAnalyzing) return;

  setState(() => _isAnalyzing = true);

  try {
    // Get the real prediction from the existing model.
    final result = await ModelService.explain(
  image,
  method: XaiMethod.gradcamPP,
);

    if (!mounted) return;

    // Open the result screen with the selected image and prediction.
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => AnalysisResultScreen(
          imageFile: image,
          result: result,
        ),
      ),
    );
  } catch (e) {
    debugPrint('Analyze failed: $e');

    if (!mounted) return;

    _showMessage(
      'Could not analyze the photo. Please try again.',
    );
  } finally {
    if (mounted) {
      setState(() => _isAnalyzing = false);
    }
  }
}

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildPreview() {
       // A photo was picked or taken: show it
    if (_selectedImage != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(_selectedImage!, fit: BoxFit.cover),
          // Button to remove the photo
          Positioned(
            top: 10,
            right: 10,
            child: IconButton.filled(
              onPressed: () => setState(() => _selectedImage = null),
              icon: const Icon(Icons.close),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    // Otherwise: show the icon for the current mode
    return Center(
      child: Icon(
        _cameraMode ? Icons.photo_camera_outlined : Icons.cloud_upload_outlined,
        size: 70,
        color: _cameraMode ? Colors.white : AppColors.forest,
      ),
    );
  }

  Widget _modeButton({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 70,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.forest : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.forest,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}