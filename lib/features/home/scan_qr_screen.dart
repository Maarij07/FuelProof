import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/text_styles.dart';
import '../../core/models/error_models.dart';
import '../../core/repositories/session_repository.dart';
import '../../core/services/api_client.dart';
import '../../core/services/app_logger.dart';
import '../../core/services/token_manager.dart';
import '../../shared/widgets/app_bottom_navigation_bar.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  MobileScannerController? scannerController;
  bool _isScanPermissionGranted = false;
  bool _isProcessingScan = false;
  String? _scannedCode;

  late final SessionRepository _sessionRepository;

  @override
  void initState() {
    super.initState();
    final tokenManager = TokenManager();
    final apiClient = ApiClient(tokenManager: tokenManager);
    _sessionRepository = SessionRepository(apiClient: apiClient);
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
        automaticallyImplyLeading: false,
        title: Text('Scan QR Code', style: AppTextStyles.sectionHeading),
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
      floatingActionButton: _isScanPermissionGranted
          ? FloatingActionButton.extended(
              onPressed: _isProcessingScan
                  ? null
                  : () => scannerController?.toggleTorch(),
              backgroundColor: AppColors.accentTeal,
              foregroundColor: AppColors.white,
              icon: const Icon(Icons.flashlight_on_rounded),
              label: Text(_isProcessingScan ? 'Scanning...' : 'Toggle Flash'),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
              'FuelGuard needs camera access to scan QR codes at fuel stations. Please enable camera permission.',
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
              ? Stack(
                  children: [
                    MobileScanner(
                      controller: scannerController!,
                      onDetect: (capture) {
                        if (_isProcessingScan) return;

                        for (final barcode in capture.barcodes) {
                          final value = barcode.rawValue;
                          if (value != null && value.trim().isNotEmpty) {
                            _handleQrCodeDetected(value.trim());
                            break;
                          }
                        }
                      },
                    ),
                    if (_isProcessingScan)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.45),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(),
                                SizedBox(height: AppSpacing.md),
                                Text(
                                  'Validating QR...',
                                  style: AppTextStyles.body.copyWith(
                                    color: AppColors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
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
    _processScan(code);
  }

  Future<void> _processScan(String qrValue) async {
    AppLogger.log('QR', 'Scanned value: $qrValue');

    // ── Device nozzle QR: fuelguard://nozzle/{nozzle_id} ────────────────────
    // Used with the ESP32 WiFi flow. Session is created on the backend while
    // the phone still has internet, then the user switches to FuelMonitor WiFi.
    if (qrValue.startsWith('fuelguard://nozzle/')) {
      // Parse as URI so query params (ssid=, pass=) are stripped automatically.
      final uri = Uri.tryParse(qrValue);
      final nozzleId = (uri != null && uri.pathSegments.isNotEmpty)
          ? uri.pathSegments.last.trim()
          : qrValue.replaceFirst('fuelguard://nozzle/', '').split('?').first.trim();
      AppLogger.log('QR', 'Nozzle QR detected — nozzle_id=$nozzleId');
      if (!mounted) return;
      final navigator = Navigator.of(context);
      await scannerController?.stop();
      if (!mounted) return;
      navigator.pushReplacementNamed(
        '/wifi-connect',
        arguments: {'nozzleId': nozzleId},
      );
      return;
    }

    // ── Old WiFi config QR — tell developer to update QR format ──────────────
    if (qrValue.startsWith('WIFI:')) {
      AppLogger.warn('QR', 'Old WiFi QR detected — nozzle_id cannot be determined');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please update the QR code on the device.\n'
              'The new format should be: fuelguard://nozzle/NZ001\n'
              '(replace NZ001 with the actual nozzle ID)',
            ),
            duration: Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
          ),
        );
        await scannerController?.start();
      }
      return;
    }

    // ── Guard against other unrecognised formats ──────────────────────────────
    if (!qrValue.startsWith('fuelguard://session/')) {
      AppLogger.warn('QR', 'Unrecognised QR format: $qrValue');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unrecognised QR code. Please scan the QR shown on the fuel dispenser.',
            ),
            duration: Duration(seconds: 4),
          ),
        );
        await scannerController?.start();
      }
      return;
    }

    setState(() {
      _isProcessingScan = true;
      _scannedCode = qrValue;
    });

    await scannerController?.stop();

    try {
      AppLogger.log('QR', 'Calling /sessions/scan ...');
      final result = await _sessionRepository.scanQrCode(qrValue);
      AppLogger.log('QR', 'Session OK — id=${result.sessionId} nozzle=${result.nozzleId}');

      if (!mounted) return;

      Navigator.of(context).pushReplacementNamed(
        '/live-session',
        arguments: {
          'sessionId': result.sessionId,
          'nozzleId': result.nozzleId,
        },
      );
    } catch (e) {
      AppLogger.error('QR', 'Scan failed: $e');
      if (!mounted) return;

      var message = 'Unable to scan QR code. Please try again.';
      if (e is AppError) {
        final detail = (e.detail ?? '').toLowerCase();
        if (detail.contains('invalid qr')) {
          message = 'This QR code is not valid. Please scan again.';
        } else if (detail.contains('expired')) {
          message =
              'This QR code has expired. Ask the attendant for a new one.';
        } else if (detail.contains('completed') || detail.contains('used')) {
          message = 'This session has already been used.';
        } else if (e.detail != null && e.detail!.trim().isNotEmpty) {
          message = e.detail!;
        }
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));

      setState(() {
        _isProcessingScan = false;
      });

      await scannerController?.start();
    }
  }
}
