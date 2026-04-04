import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/text_styles.dart';
import '../../shared/widgets/app_bottom_navigation_bar.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  MobileScannerController? scannerController;
  bool _isScanPermissionGranted = false;
  String? _scannedCode;

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermission();
  }

  Future<void> _checkAndRequestPermission() async {
    try {
      final status = await Permission.camera.status;
      developer.log('[Camera Permission] Current status: $status');

      if (status.isGranted) {
        developer.log('[Camera Permission] Permission already granted');
        setState(() {
          _isScanPermissionGranted = true;
        });
        _initScanner();
      } else if (status.isDenied) {
        developer.log('[Camera Permission] Permission denied, requesting...');
        await _requestPermission();
      } else if (status.isPermanentlyDenied) {
        developer.log('[Camera Permission] Permission permanently denied');
        if (mounted) {
          _showPermanentlyDeniedDialog();
        }
      }
    } catch (e) {
      developer.log('[Camera Permission] Error checking status: $e');
    }
  }

  Future<void> _requestPermission() async {
    try {
      developer.log('[Camera Permission] Requesting camera permission...');
      final status = await Permission.camera.request();
      developer.log('[Camera Permission] Request result: $status');

      if (status.isGranted) {
        developer.log('[Camera Permission] Permission granted!');
        setState(() {
          _isScanPermissionGranted = true;
        });
        _initScanner();
      } else if (status.isDenied) {
        developer.log('[Camera Permission] Permission was denied');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera permission is required to scan QR codes'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else if (status.isPermanentlyDenied) {
        developer.log('[Camera Permission] Permission permanently denied');
        if (mounted) {
          _showPermanentlyDeniedDialog();
        }
      }
    } catch (e) {
      developer.log('[Camera Permission] Error requesting permission: $e');
    }
  }

  void _initScanner() {
    if (mounted && scannerController == null) {
      scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
      );
      developer.log('[Scanner] Initialized successfully');
    }
  }

  void _showPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text(
          'Camera permission is permanently denied. Please enable it in app settings to use QR scanning.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    scannerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      bottomNavigationBar: const AppBottomNavigationBar(currentIndex: 0),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.white,
        title: Text('Scan QR Code', style: AppTextStyles.sectionHeading),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isScanPermissionGranted)
            IconButton(
              icon: const Icon(Icons.flashlight_on_rounded),
              onPressed: () => scannerController?.toggleTorch(),
            ),
        ],
      ),
      body: SafeArea(
        child: !_isScanPermissionGranted
            ? _buildPermissionDeniedView()
            : SingleChildScrollView(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: AppSpacing.md),
                    Text(
                      'Point camera at fuel station QR code',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.secondaryText,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: AppSpacing.lg),
                    _buildScannerPreview(),
                    SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.accentTeal.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(
                          AppBorderRadius.card,
                        ),
                        border: Border.all(
                          color: AppColors.accentTeal.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.accentTeal,
                            size: 24,
                          ),
                          SizedBox(height: AppSpacing.md),
                          Text(
                            'Make sure the QR code is clearly visible and well-lit',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.accentTeal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_scannedCode != null) ...[
                      SizedBox(height: AppSpacing.lg),
                      Container(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppBorderRadius.card,
                          ),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.success,
                              size: 24,
                            ),
                            SizedBox(height: AppSpacing.md),
                            Text(
                              'QR Code Detected',
                              style: AppTextStyles.cardTitle.copyWith(
                                color: AppColors.success,
                              ),
                            ),
                            SizedBox(height: AppSpacing.sm),
                            Text(
                              _scannedCode!,
                              style: AppTextStyles.caption,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildPermissionDeniedView() {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_rounded, size: 64, color: AppColors.softGray),
            SizedBox(height: AppSpacing.lg),
            Text(
              'Camera Permission Required',
              style: AppTextStyles.sectionHeading,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'FuelProof needs camera access to scan QR codes at fuel stations. Please enable camera permission.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentTeal,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                onPressed: _requestPermission,
                child: Text(
                  'Enable Camera',
                  style: AppTextStyles.cardTitle.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerPreview() {
    return Center(
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppBorderRadius.card),
          boxShadow: AppShadows.lightList,
          border: Border.all(
            color: AppColors.accentTeal.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppBorderRadius.card),
          child: _isScanPermissionGranted && scannerController != null
              ? MobileScanner(
                  controller: scannerController!,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      setState(() {
                        _scannedCode = barcode.rawValue;
                      });
                      if (barcode.rawValue != null) {
                        _handleQrCodeDetected(barcode.rawValue!);
                      }
                    }
                  },
                )
              : Container(
                  color: AppColors.lightGray,
                  child: Center(
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: AppColors.accentTeal,
                      size: 48,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  void _handleQrCodeDetected(String code) {
    // Handle successful QR code scan
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Code Scanned'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Code:'),
            SizedBox(height: AppSpacing.sm),
            SelectableText(
              code,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Continue scanning
              setState(() {
                _scannedCode = null;
              });
            },
            child: const Text('Scan Again'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to home
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class AppBorderRadius {
  static const double card = 12.0;
}

class AppShadows {
  static const List<BoxShadow> lightList = [
    BoxShadow(
      color: Color.fromARGB(8, 0, 0, 0),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
}
