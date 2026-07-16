import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/text_styles.dart';
import '../../core/constants/spacing.dart';
import '../../core/models/error_models.dart';
import '../../core/state/app_providers.dart';

class EvidenceCaptureScreen extends ConsumerStatefulWidget {
  final String? transactionId;

  const EvidenceCaptureScreen({super.key, this.transactionId});

  @override
  ConsumerState<EvidenceCaptureScreen> createState() =>
      _EvidenceCaptureScreenState();
}

class _EvidenceCaptureScreenState extends ConsumerState<EvidenceCaptureScreen> {
  final ImagePicker _picker = ImagePicker();

  XFile? _capturedFile;
  Uint8List? _imageBytes;
  bool _isSubmitting = false;
  String? _transactionId;
  final TextEditingController _descriptionController = TextEditingController();

  // Retention info
  static const int _retentionDays = 90;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_transactionId != null) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    final routeId = args is Map<String, dynamic>
        ? args['transactionId'] as String?
        : null;
    _transactionId = routeId ?? widget.transactionId;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _captureFromCamera() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 75,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _capturedFile = file;
        _imageBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Camera error: ${e.toString()}'),
          backgroundColor: AppColors.alert,
        ),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _capturedFile = file;
        _imageBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gallery error: ${e.toString()}'),
          backgroundColor: AppColors.alert,
        ),
      );
    }
  }

  void _retake() {
    setState(() {
      _capturedFile = null;
      _imageBytes = null;
    });
  }

  Future<void> _submitEvidence() async {
    if (_imageBytes == null || _capturedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please capture or select a photo first.'),
          backgroundColor: AppColors.alert,
        ),
      );
      return;
    }

    final transactionId = _transactionId;
    if (transactionId == null || transactionId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Transaction ID missing.'),
          backgroundColor: AppColors.alert,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(evidenceRepositoryProvider);
      final filename = _capturedFile!.name.isNotEmpty
          ? _capturedFile!.name
          : 'evidence_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await repo.uploadEvidence(
        transactionId: transactionId,
        imageBytes: _imageBytes!,
        filename: filename,
        captureTrigger: 'manual',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Evidence uploaded successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final msg = e is AppError && e.detail != null && e.detail!.isNotEmpty
          ? e.detail!
          : 'Upload failed. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.alert),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _imageBytes != null;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text('Capture Evidence', style: AppTextStyles.sectionHeading),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Container(
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.tealLight,
                borderRadius: BorderRadius.circular(AppBorderRadius.card),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.accentTeal,
                    size: 20,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Capture a clear photo of the receipt or fuel pump display. '
                      'Evidence is retained for $_retentionDays days.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.accentTeal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.lg),

            // Image preview area
            ClipRRect(
              borderRadius: BorderRadius.circular(AppBorderRadius.card),
              child: Container(
                height: 280,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.secondaryBackground,
                  border: Border.all(
                    color: hasImage ? AppColors.accentTeal : AppColors.softGray,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(AppBorderRadius.card),
                ),
                child: hasImage
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(_imageBytes!, fit: BoxFit.cover),
                          // Watermark overlay
                          Positioned(
                            top: AppSpacing.sm,
                            right: AppSpacing.sm,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.brandNavy.withValues(
                                  alpha: 0.75,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppBorderRadius.small,
                                ),
                              ),
                              child: Text(
                                'TXN: ${_transactionId ?? 'N/A'}',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: AppSpacing.sm,
                            left: AppSpacing.sm,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(
                                  AppBorderRadius.small,
                                ),
                              ),
                              child: Text(
                                DateTime.now()
                                    .toUtc()
                                    .toIso8601String()
                                    .substring(0, 19),
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_outlined,
                              size: 64,
                              color: AppColors.softGray,
                            ),
                            SizedBox(height: AppSpacing.md),
                            Text(
                              'No photo captured',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.secondaryText,
                              ),
                            ),
                            SizedBox(height: AppSpacing.xs),
                            Text(
                              'Tap a button below to add a photo',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.tertiaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            SizedBox(height: AppSpacing.lg),

            // Capture / Gallery / Retake buttons
            if (!hasImage) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _captureFromCamera,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentTeal,
                        foregroundColor: AppColors.white,
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppBorderRadius.button,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickFromGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.brandNavy,
                        side: BorderSide(color: AppColors.brandNavy),
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppBorderRadius.button,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _retake,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retake'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.brandNavy,
                        side: BorderSide(color: AppColors.brandNavy),
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppBorderRadius.button,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: AppSpacing.lg),

            // File metadata when image is selected
            if (hasImage) ...[
              Container(
                padding: EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppBorderRadius.card),
                  boxShadow: AppShadows.subtleList,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Capture Details', style: AppTextStyles.cardTitle),
                    SizedBox(height: AppSpacing.md),
                    _detailRow(
                      'File',
                      _capturedFile!.name.isNotEmpty
                          ? _capturedFile!.name
                          : 'evidence.jpg',
                    ),
                    _detailRow('Size', _formatFileSize(_imageBytes!.length)),
                    _detailRow('Transaction', _transactionId ?? 'N/A'),
                    _detailRow(
                      'Retention',
                      'Auto-deleted after $_retentionDays days',
                    ),
                    _detailRow(
                      'Timestamp',
                      '${DateTime.now().toUtc().toIso8601String().substring(0, 19)} UTC',
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.lg),
            ],

            // Optional description
            Text('Description (optional)', style: AppTextStyles.cardTitle),
            SizedBox(height: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppBorderRadius.input),
                boxShadow: AppShadows.subtleList,
              ),
              child: TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add any additional context or notes...',
                  hintStyle: AppTextStyles.body.copyWith(
                    color: AppColors.tertiaryText,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(AppSpacing.md),
                ),
                style: AppTextStyles.body,
              ),
            ),
            SizedBox(height: AppSpacing.xl),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isSubmitting || !hasImage)
                    ? null
                    : _submitEvidence,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.white,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md + 4),
                  elevation: 0,
                  disabledBackgroundColor: AppColors.softGray,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppBorderRadius.button),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_upload_outlined),
                          SizedBox(width: AppSpacing.sm),
                          Text(
                            'Upload Evidence',
                            style: AppTextStyles.cardTitle.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
