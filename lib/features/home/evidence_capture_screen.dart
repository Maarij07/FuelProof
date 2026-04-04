import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/app_constants.dart';

class EvidenceID {
  final String id;
  final String type;
  final DateTime timestamp;
  final String? description;

  EvidenceID({
    required this.id,
    required this.type,
    required this.timestamp,
    this.description,
  });
}

class EvidenceCaptureScreen extends StatefulWidget {
  const EvidenceCaptureScreen({super.key});

  @override
  State<EvidenceCaptureScreen> createState() => _EvidenceCaptureScreenState();
}

class _EvidenceCaptureScreenState extends State<EvidenceCaptureScreen> {
  bool _hasCapture = false;
  late TextEditingController _descriptionController;
  late EvidenceID _currentEvidence;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _currentEvidence = EvidenceID(
      id: 'EV-${DateTime.now().millisecondsSinceEpoch}',
      type: 'Receipt',
      timestamp: DateTime.now(),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _capturePhoto() {
    setState(() {
      _hasCapture = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Photo captured successfully'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _retakePhoto() {
    setState(() {
      _hasCapture = false;
      _descriptionController.clear();
    });
  }

  void _submitEvidence() {
    if (!_hasCapture) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please capture a photo first'),
          backgroundColor: AppColors.alert,
        ),
      );
      return;
    }

    final evidence = EvidenceID(
      id: _currentEvidence.id,
      type: _currentEvidence.type,
      timestamp: _currentEvidence.timestamp,
      description: _descriptionController.text.isNotEmpty
          ? _descriptionController.text
          : null,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Evidence submitted successfully'),
        backgroundColor: AppColors.success,
      ),
    );

    Navigator.pop(context, evidence);
  }

  String _formatTimestamp(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Capture Evidence', style: AppTextStyles.sectionHeading),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.tealLight,
                  borderRadius: BorderRadius.circular(AppBorderRadius.card),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: AppColors.accentTeal, size: 20),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Take a clear photo of the receipt or fuel pump display',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.accentTeal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: AppColors.secondaryBackground,
                  borderRadius: BorderRadius.circular(AppBorderRadius.card),
                  boxShadow: AppShadows.subtleList,
                  border: Border.all(
                    color: _hasCapture
                        ? AppColors.accentTeal
                        : AppColors.softGray,
                    width: 2,
                  ),
                ),
                child: Stack(
                  children: [
                    if (!_hasCapture)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 64,
                              color: AppColors.softGray,
                            ),
                            SizedBox(height: AppSpacing.md),
                            Text(
                              'Ready to Capture',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Center(
                        child: Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: AppColors.lightGray,
                          child: Stack(
                            children: [
                              Center(
                                child: Icon(
                                  Icons.image,
                                  size: 80,
                                  color: AppColors.mediumGray,
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  margin: EdgeInsets.all(AppSpacing.md),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: AppSpacing.xs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.brandNavy.withValues(
                                      alpha: 0.8,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppBorderRadius.small,
                                    ),
                                  ),
                                  child: Text(
                                    _formatTimestamp(
                                      _currentEvidence.timestamp,
                                    ),
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: EdgeInsets.all(AppSpacing.md),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        AppColors.brandNavy.withValues(
                                          alpha: 0.8,
                                        ),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                  child: Text(
                                    'Receipt Captured',
                                    style: AppTextStyles.body.copyWith(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
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
              SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _hasCapture ? _retakePhoto : null,
                    icon: Icon(Icons.refresh),
                    label: Text('Retake'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _hasCapture
                          ? AppColors.brandNavy
                          : AppColors.softGray,
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppBorderRadius.button,
                        ),
                      ),
                      elevation: 0,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _hasCapture ? null : _capturePhoto,
                    icon: Icon(Icons.camera),
                    label: Text('Capture'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentTeal,
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppBorderRadius.button,
                        ),
                      ),
                      elevation: 0,
                      disabledBackgroundColor: AppColors.softGray,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.lg),
              if (_hasCapture) ...[
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
                      Text('Evidence Details', style: AppTextStyles.cardTitle),
                      SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ID',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.secondaryText,
                            ),
                          ),
                          Text(
                            _currentEvidence.id,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.accentTeal,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Type',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.secondaryText,
                            ),
                          ),
                          Text(
                            _currentEvidence.type,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryText,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Captured At',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.secondaryText,
                            ),
                          ),
                          Text(
                            _formatTimestamp(_currentEvidence.timestamp),
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.lg),
              ],
              Text('Optional Description', style: AppTextStyles.cardTitle),
              SizedBox(height: AppSpacing.md),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppBorderRadius.input),
                  boxShadow: AppShadows.subtleList,
                ),
                child: TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Add any additional notes...',
                    hintStyle: AppTextStyles.body.copyWith(
                      color: AppColors.tertiaryText,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(AppSpacing.md),
                  ),
                  style: AppTextStyles.body,
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitEvidence,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppBorderRadius.button,
                      ),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: AppColors.softGray,
                  ),
                  child: Text(
                    'Submit Evidence',
                    style: AppTextStyles.cardTitle.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
