import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/text_styles.dart';
import '../../core/models/auth_models.dart';
import '../../core/models/error_models.dart';
import '../../core/models/transaction_models.dart';
import '../../core/repositories/auth_repository.dart';
import '../../core/repositories/transaction_repository.dart';
import '../../core/services/api_client.dart';
import '../../core/services/token_manager.dart';
import '../../main.dart';

class _SpendingSummary {
  final double totalSpent;
  final double totalLitres;
  final int totalTransactions;
  final int completedTransactions;

  const _SpendingSummary({
    required this.totalSpent,
    required this.totalLitres,
    required this.totalTransactions,
    required this.completedTransactions,
  });

  const _SpendingSummary.empty()
    : totalSpent = 0,
      totalLitres = 0,
      totalTransactions = 0,
      completedTransactions = 0;
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final AuthRepository _authRepository;
  late final TransactionRepository _transactionRepository;
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = true;
  bool _isUploadingAvatar = false;
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = AppThemeController.currentMode == ThemeMode.dark;
  String? _errorMessage;
  String? _spendingErrorMessage;

  User? _user;
  _SpendingSummary _spendingSummary = const _SpendingSummary.empty();

  @override
  void initState() {
    super.initState();
    _darkModeEnabled = AppThemeController.currentMode == ThemeMode.dark;
    AppThemeController.getThemeMode().addListener(_onThemeModeChanged);
    final tokenManager = TokenManager();
    final apiClient = ApiClient(tokenManager: tokenManager);
    _authRepository = AuthRepository(
      apiClient: apiClient,
      tokenManager: tokenManager,
    );
    _transactionRepository = TransactionRepository(apiClient: apiClient);
    _loadProfile();
  }

  void _onThemeModeChanged() {
    if (mounted) {
      setState(() {
        _darkModeEnabled = AppThemeController.currentMode == ThemeMode.dark;
      });
    }
  }

  @override
  void dispose() {
    AppThemeController.getThemeMode().removeListener(_onThemeModeChanged);
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _spendingErrorMessage = null;
    });

    try {
      final user = await _authRepository.getCurrentUser();
      _SpendingSummary summary = const _SpendingSummary.empty();
      String? spendingError;

      try {
        summary = await _fetchSpendingSummary();
      } catch (e) {
        spendingError = _resolveAppErrorMessage(
          e,
          'Unable to load spending summary right now.',
        );
      }

      if (!mounted) return;
      setState(() {
        _user = user;
        _spendingSummary = summary;
        _spendingErrorMessage = spendingError;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final message = _resolveAppErrorMessage(
        e,
        'Unable to load profile data right now.',
      );
      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    }
  }

  Future<_SpendingSummary> _fetchSpendingSummary() async {
    const limit = 100;
    var offset = 0;
    var totalTransactions = 0;
    var totalSpent = 0.0;
    var totalLitres = 0.0;
    var completedTransactions = 0;
    var safetyCounter = 0;

    while (safetyCounter < 30) {
      final page = await _transactionRepository.getMyTransactions(
        limit: limit,
        offset: offset,
      );

      if (totalTransactions == 0) {
        totalTransactions = page.total;
      }

      if (page.items.isEmpty) {
        break;
      }

      for (final transaction in page.items) {
        if (transaction.status == TransactionStatus.completed) {
          totalSpent += transaction.totalAmount;
          totalLitres += transaction.litresDispensed;
          completedTransactions += 1;
        }
      }

      offset += page.items.length;
      safetyCounter += 1;

      if (offset >= page.total || page.items.length < limit) {
        break;
      }
    }

    return _SpendingSummary(
      totalSpent: totalSpent,
      totalLitres: totalLitres,
      totalTransactions: totalTransactions,
      completedTransactions: completedTransactions,
    );
  }

  String _resolveAppErrorMessage(Object error, String fallback) {
    if (error is AppError) {
      final detail = error.detail?.trim();
      if (detail != null && detail.isNotEmpty) {
        return detail;
      }
    }
    return fallback;
  }

  void _toggleDarkMode(bool value) {
    setState(() => _darkModeEnabled = value);
    AppThemeController.toggleDarkMode(value);
  }

  String _formatJoinedDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate).toLocal();
      return DateFormat('MMMM yyyy').format(date);
    } catch (_) {
      return 'Recently joined';
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'en_PK',
      symbol: 'PKR ',
      decimalDigits: 2,
    ).format(amount);
  }

  String _formatInitials(String? name) {
    final value = name?.trim() ?? '';
    if (value.isEmpty) return 'FP';
    final parts = value
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'FP';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Uint8List? _decodeAvatarData(String? avatarUrl) {
    if (avatarUrl == null || !avatarUrl.startsWith('data:image/')) {
      return null;
    }
    final commaIndex = avatarUrl.indexOf(',');
    if (commaIndex == -1 || commaIndex >= avatarUrl.length - 1) {
      return null;
    }
    try {
      return base64Decode(avatarUrl.substring(commaIndex + 1));
    } catch (_) {
      return null;
    }
  }

  Future<void> _showPermissionSettingsDialog(String permissionLabel) async {
    if (!mounted) return;
    final openSettings = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permissionLabel Permission Required'),
        content: Text(
          'Please allow $permissionLabel permission from app settings to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
    if (openSettings == true) {
      await openAppSettings();
    }
  }

  Future<void> _showPickerChannelErrorDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Image Picker Channel Error'),
        content: Text(
          kIsWeb
              ? 'Browser image picker channel failed to initialize. Please hard refresh the page and try again.'
              : 'Native image picker channel failed to initialize. Please restart the app and try again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<ImageSource?> _pickAvatarSource() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _pickImageAsDataUrl(ImageSource source) async {
    Future<XFile?> pick() {
      return _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
      );
    }

    try {
      // Prevent transition collisions right after bottom sheet dismissal.
      await Future<void>.delayed(const Duration(milliseconds: 180));

      var picked = await pick();

      // Some devices return transient "already active" picker errors.
      if (picked == null) {
        await Future<void>.delayed(const Duration(milliseconds: 120));
        picked = await pick();
      }

      if (picked == null) return null;

      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) return null;
      final encoded = base64Encode(bytes);
      return 'data:image/jpeg;base64,$encoded';
    } on PlatformException catch (e) {
      final code = e.code.toLowerCase();
      final message = (e.message ?? '').toLowerCase();
      final channelError =
          code.contains('channel') || message.contains('channel');
      final denied =
          code.contains('denied') ||
          code.contains('access') ||
          code.contains('permission');

      final transientPickerIssue =
          code.contains('already') ||
          code.contains('active') ||
          code.contains('in_progress') ||
          code.contains('multiple_request');

      if (transientPickerIssue) {
        try {
          await Future<void>.delayed(const Duration(milliseconds: 260));
          final retryPicked = await pick();
          if (retryPicked == null) return null;

          final retryBytes = await retryPicked.readAsBytes();
          if (retryBytes.isEmpty) return null;
          final retryEncoded = base64Encode(retryBytes);
          return 'data:image/jpeg;base64,$retryEncoded';
        } on PlatformException {
          // Fall through to generic handling below.
        }
      }

      if (denied) {
        await _showPermissionSettingsDialog(
          source == ImageSource.camera ? 'Camera' : 'Photo Library',
        );
        return null;
      }

      if (channelError) {
        await _showPickerChannelErrorDialog();
        return null;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to open image picker ($code). Please try again.',
            ),
          ),
        );
      }
      return null;
    } on MissingPluginException {
      await _showPickerChannelErrorDialog();
      return null;
    }
  }

  Future<void> _changeProfilePictureQuick() async {
    // Step 1: Show modal to choose source
    final source = await _pickAvatarSource();
    if (source == null) return;

    // Step 2: Pick image (this handles permission request internally)
    setState(() {
      _isUploadingAvatar = true;
    });

    try {
      final avatarDataUrl = await _pickImageAsDataUrl(source);
      if (avatarDataUrl == null) {
        setState(() {
          _isUploadingAvatar = false;
        });
        return;
      }

      final updated = await _authRepository.updateProfile(
        avatarUrl: avatarDataUrl,
      );
      if (!mounted) return;
      setState(() {
        _user = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      final message = _resolveAppErrorMessage(
        e,
        'Unable to update profile picture right now',
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  double get _completionValue {
    if (_user == null) return 0.5;
    var score = 0.45;
    if ((_user!.fullName).trim().isNotEmpty) score += 0.2;
    if ((_user!.phone ?? '').trim().isNotEmpty) score += 0.2;
    if ((_user!.avatarUrl ?? '').trim().isNotEmpty) score += 0.15;
    return score.clamp(0.0, 1.0);
  }

  Future<void> _openEditProfileSheet() async {
    final user = _user;
    if (user == null) return;

    final nameController = TextEditingController(text: user.fullName);
    final phoneController = TextEditingController(text: user.phone ?? '');
    var avatarDataUrl = user.avatarUrl;
    bool submitting = false;
    bool uploadingAvatar = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return FractionallySizedBox(
              heightFactor: 0.92,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  MediaQuery.of(context).viewInsets.bottom +
                      MediaQuery.of(context).viewPadding.bottom +
                      AppSpacing.lg,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppBorderRadius.card),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Edit Profile', style: AppTextStyles.sectionHeading),
                      SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                        ),
                      ),
                      SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                        ),
                      ),
                      SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          _buildProfileAvatar(
                            size: 56,
                            fullName: nameController.text,
                            avatarUrl: avatarDataUrl,
                          ),
                          SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: uploadingAvatar
                                  ? null
                                  : () async {
                                      final source = await _pickAvatarSource();
                                      if (source == null) return;

                                      setModalState(() {
                                        uploadingAvatar = true;
                                      });

                                      final selected =
                                          await _pickImageAsDataUrl(source);

                                      if (!context.mounted) return;
                                      setModalState(() {
                                        if (selected != null) {
                                          avatarDataUrl = selected;
                                        }
                                        uploadingAvatar = false;
                                      });
                                    },
                              icon: uploadingAvatar
                                  ? SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.accentTeal,
                                      ),
                                    )
                                  : const Icon(Icons.camera_alt_outlined),
                              label: Text(
                                uploadingAvatar
                                    ? 'Uploading...'
                                    : 'Change Profile Picture',
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: submitting
                              ? null
                              : () async {
                                  final fullName = nameController.text.trim();
                                  final phone = phoneController.text.trim();

                                  if (fullName.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Full name is required'),
                                      ),
                                    );
                                    return;
                                  }

                                  setModalState(() {
                                    submitting = true;
                                  });

                                  try {
                                    final updated = await _authRepository
                                        .updateProfile(
                                          fullName: fullName,
                                          phone: phone.isEmpty ? null : phone,
                                          avatarUrl: avatarDataUrl,
                                        );
                                    if (!context.mounted) return;
                                    setState(() {
                                      _user = updated;
                                    });
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Profile updated successfully',
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    setModalState(() {
                                      submitting = false;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          _resolveAppErrorMessage(
                                            e,
                                            'Unable to update profile right now',
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                },
                          child: Text(
                            submitting ? 'Saving...' : 'Save Changes',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openChangePasswordSheet() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool submitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppBorderRadius.card),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Change Password',
                      style: AppTextStyles.sectionHeading,
                    ),
                    SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: currentPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Current Password',
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New Password',
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm New Password',
                      ),
                    ),
                    SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: submitting
                            ? null
                            : () async {
                                final currentPassword =
                                    currentPasswordController.text.trim();
                                final newPassword = newPasswordController.text
                                    .trim();
                                final confirmPassword =
                                    confirmPasswordController.text.trim();

                                if (currentPassword.isEmpty ||
                                    newPassword.isEmpty ||
                                    confirmPassword.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'All password fields are required',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                if (newPassword != confirmPassword) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'New passwords do not match',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                if (newPassword.length < 8) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'New password must be at least 8 characters',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                setModalState(() {
                                  submitting = true;
                                });

                                try {
                                  await _authRepository.changePassword(
                                    currentPassword: currentPassword,
                                    newPassword: newPassword,
                                  );
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Password updated successfully',
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  setModalState(() {
                                    submitting = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        _resolveAppErrorMessage(
                                          e,
                                          'Unable to change password right now',
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              },
                        child: Text(
                          submitting ? 'Updating...' : 'Change Password',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout from FuelGuard?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              Navigator.pop(dialogContext);
              try {
                await _authRepository.logout();
                if (!context.mounted) return;
                navigator.pushNamedAndRemoveUntil('/auth', (route) => false);
              } catch (_) {
                if (!context.mounted) return;
                navigator.pushNamedAndRemoveUntil('/auth', (route) => false);
              }
            },
            child: Text('Logout', style: TextStyle(color: AppColors.alert)),
          ),
        ],
      ),
    );
  }

  void _showInfoBottomSheet({
    required String title,
    required List<MapEntry<String, String>> sections,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.86,
          child: Container(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              MediaQuery.of(context).viewPadding.bottom + AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppBorderRadius.card),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    margin: EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.lightGray,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Text(title, style: AppTextStyles.sectionHeading),
                SizedBox(height: AppSpacing.md),
                Expanded(
                  child: ListView.separated(
                    itemCount: sections.length,
                    separatorBuilder: (_, _) => SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final section = sections[index];
                      return Container(
                        padding: EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBackground,
                          borderRadius: BorderRadius.circular(
                            AppBorderRadius.card,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(section.key, style: AppTextStyles.cardTitle),
                            SizedBox(height: AppSpacing.xs),
                            Text(
                              section.value,
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.secondaryText,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('Profile', style: AppTextStyles.sectionHeading),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadProfile,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 56,
                      color: AppColors.alert,
                    ),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body,
                    ),
                    SizedBox(height: AppSpacing.md),
                    ElevatedButton(
                      onPressed: _loadProfile,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(user),
                    SizedBox(height: AppSpacing.xl),
                    _buildSectionTitle('Fuel Summary'),
                    SizedBox(height: AppSpacing.md),
                    _buildSpendingSummaryCard(),
                    SizedBox(height: AppSpacing.xl),
                    _buildSectionTitle('Settings'),
                    SizedBox(height: AppSpacing.md),
                    _buildSettingItem(
                      icon: Icons.notifications_active_rounded,
                      title: 'Notifications',
                      subtitle: 'Alerts for transactions and reminders',
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() => _notificationsEnabled = value);
                      },
                    ),
                    SizedBox(height: AppSpacing.md),
                    _buildSettingItem(
                      icon: Icons.dark_mode_rounded,
                      title: 'Dark Mode',
                      subtitle: 'Use dark appearance throughout the app',
                      value: _darkModeEnabled,
                      onChanged: _toggleDarkMode,
                    ),
                    SizedBox(height: AppSpacing.xl),
                    _buildSectionTitle('Security'),
                    SizedBox(height: AppSpacing.md),
                    _buildMenuOption(
                      icon: Icons.password_rounded,
                      title: 'Change Password',
                      subtitle: 'Update your account password securely',
                      iconBackgroundColor: AppColors.alertLight,
                      iconColor: AppColors.alert,
                      onTap: _openChangePasswordSheet,
                    ),
                    SizedBox(height: AppSpacing.xl),
                    _buildSectionTitle('Support & Information'),
                    SizedBox(height: AppSpacing.md),
                    _buildMenuOption(
                      icon: Icons.headset_mic_rounded,
                      title: 'Help & Support',
                      subtitle: 'Get assistance and contact our support team',
                      iconBackgroundColor: AppColors.navyLight,
                      iconColor: AppColors.brandNavy,
                      onTap: () {
                        _showInfoBottomSheet(
                          title: 'Help & Support',
                          sections: [
                            const MapEntry(
                              'Support Channels',
                              'Email: support@fuelguard.app\nPhone: +92 300 0000000\nWorking hours: Monday to Saturday, 9:00 AM to 8:00 PM',
                            ),
                            const MapEntry(
                              'What We Can Help With',
                              'Account access, profile updates, QR scan issues, session disputes, and payment verification concerns.',
                            ),
                            const MapEntry(
                              'Response Time',
                              'Most issues are resolved within 24 hours. Priority safety and fraud reports are handled immediately.',
                            ),
                          ],
                        );
                      },
                    ),
                    _buildMenuOption(
                      icon: Icons.shield_rounded,
                      title: 'Privacy Policy',
                      subtitle: 'Read how we handle your data',
                      iconBackgroundColor: AppColors.successLight,
                      iconColor: AppColors.success,
                      onTap: () {
                        _showInfoBottomSheet(
                          title: 'Privacy Policy',
                          sections: [
                            const MapEntry(
                              'Data We Collect',
                              'We collect your profile details, session activity, location during active scans, and uploaded evidence for fraud prevention.',
                            ),
                            const MapEntry(
                              'How Data Is Used',
                              'Your data is used to verify transactions, improve fraud detection, personalize recommendations, and provide customer support.',
                            ),
                            const MapEntry(
                              'Data Protection',
                              'FuelGuard applies secure storage, encrypted transport, and access controls. You can request data deletion through support.',
                            ),
                          ],
                        );
                      },
                    ),
                    _buildMenuOption(
                      icon: Icons.menu_book_rounded,
                      title: 'Terms & Conditions',
                      subtitle: 'Review app terms and usage guidelines',
                      iconBackgroundColor: AppColors.warningLight,
                      iconColor: AppColors.warning,
                      onTap: () {
                        _showInfoBottomSheet(
                          title: 'Terms & Conditions',
                          sections: [
                            const MapEntry(
                              'Account Responsibility',
                              'You are responsible for maintaining account security and ensuring the accuracy of submitted profile and transaction information.',
                            ),
                            const MapEntry(
                              'Fair Usage',
                              'Abuse, fraudulent submissions, or misuse of QR sessions may result in account restriction or permanent suspension.',
                            ),
                            const MapEntry(
                              'Service Availability',
                              'FuelGuard services may change, pause, or update without prior notice while we improve reliability and security.',
                            ),
                          ],
                        );
                      },
                    ),
                    _buildMenuOption(
                      icon: Icons.info_outline_rounded,
                      title: 'About FuelGuard',
                      subtitle: 'Version, licenses, and app information',
                      iconBackgroundColor: AppColors.lightGray,
                      iconColor: AppColors.tertiaryText,
                      onTap: () {
                        _showInfoBottomSheet(
                          title: 'About FuelGuard',
                          sections: [
                            const MapEntry(
                              'Our Mission',
                              'FuelGuard helps drivers and stations build trust through secure QR verification, transparent records, and fraud-resistant fuel sessions.',
                            ),
                            const MapEntry(
                              'App Version',
                              'FuelGuard v1.0.0\nBuild: Debug configuration\nPlatform support: Android, iOS, and Web',
                            ),
                            const MapEntry(
                              'Core Features',
                              'Live session verification, transaction history, evidence reporting, profile management, and security controls for account protection.',
                            ),
                          ],
                        );
                      },
                    ),
                    SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showLogoutConfirmation,
                        icon: Icon(
                          Icons.logout_rounded,
                          color: AppColors.white,
                        ),
                        label: Text(
                          'Logout',
                          style: AppTextStyles.cardTitle.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.alert,
                          padding: EdgeInsets.symmetric(
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
                    ),
                    SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSpendingSummaryCard() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        boxShadow: AppShadows.subtleList,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryMetric(
                  label: 'Total Spent',
                  value: _formatCurrency(_spendingSummary.totalSpent),
                  accentColor: AppColors.accentTeal,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildSummaryMetric(
                  label: 'Fuel Used',
                  value: '${_spendingSummary.totalLitres.toStringAsFixed(1)} L',
                  accentColor: AppColors.brandNavy,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildSummaryMetric(
                  label: 'Transactions',
                  value: _spendingSummary.totalTransactions.toString(),
                  accentColor: AppColors.warning,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildSummaryMetric(
                  label: 'Completed',
                  value: _spendingSummary.completedTransactions.toString(),
                  accentColor: AppColors.success,
                ),
              ),
            ],
          ),
          if (_spendingErrorMessage != null) ...[
            SizedBox(height: AppSpacing.md),
            Text(
              _spendingErrorMessage!,
              style: AppTextStyles.caption.copyWith(color: AppColors.alert),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryMetric({
    required String label,
    required String value,
    required Color accentColor,
  }) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppBorderRadius.input),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.cardTitle.copyWith(color: accentColor),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(User? user) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayName = user?.fullName.trim().isNotEmpty == true
        ? user!.fullName.trim()
        : 'FuelGuard Member';
    final email = user?.email ?? 'your@email.com';
    final role = user?.role.trim().isNotEmpty == true
        ? user!.role[0].toUpperCase() + user.role.substring(1).toLowerCase()
        : 'Customer';
    final joinedSince = user != null
        ? _formatJoinedDate(user.createdAt)
        : 'Recently joined';
    final completion = (_completionValue * 100).round();

    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        boxShadow: AppShadows.subtleList,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileAvatar(
                size: 84,
                fullName: user?.fullName,
                avatarUrl: user?.avatarUrl,
                onTap: _isUploadingAvatar ? null : _changeProfilePictureQuick,
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: AppTextStyles.sectionHeading.copyWith(
                        fontSize: 24,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      email,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentTeal.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(
                              AppBorderRadius.pill,
                            ),
                          ),
                          child: Text(
                            role,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.accentTeal,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(
                              AppBorderRadius.pill,
                            ),
                          ),
                          child: Text(
                            joinedSince,
                            style: AppTextStyles.caption.copyWith(
                              color: colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            'Profile Completion',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppBorderRadius.pill),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: _completionValue,
              backgroundColor: AppColors.lightGray,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentTeal),
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            '$completion% complete',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.tertiaryText,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _openEditProfileSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentTeal,
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.button),
                ),
              ),
              child: Text(
                'Edit Profile',
                style: AppTextStyles.cardTitle.copyWith(color: AppColors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar({
    required double size,
    required String? fullName,
    required String? avatarUrl,
    VoidCallback? onTap,
  }) {
    final bytes = _decodeAvatarData(avatarUrl);
    final hasNetworkAvatar =
        avatarUrl != null &&
        avatarUrl.trim().isNotEmpty &&
        !avatarUrl.startsWith('data:image/');

    Widget avatarChild;
    if (bytes != null) {
      avatarChild = ClipOval(
        child: Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    } else if (hasNetworkAvatar) {
      avatarChild = ClipOval(
        child: Image.network(
          avatarUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _avatarFallback(size, fullName),
        ),
      );
    } else {
      avatarChild = _avatarFallback(size, fullName);
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatarChild,
          Positioned(
            right: -2,
            bottom: -2,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.accentTeal,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 2),
                  ),
                  child: _isUploadingAvatar
                      ? Padding(
                          padding: const EdgeInsets.all(7),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.white,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.camera_alt_rounded,
                          size: 14,
                          color: AppColors.white,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback(double size, String? fullName) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accentTeal.withValues(alpha: 0.28),
            AppColors.brandNavy.withValues(alpha: 0.28),
          ],
        ),
        boxShadow: AppShadows.lightList,
      ),
      child: Center(
        child: Text(
          _formatInitials(fullName),
          style: AppTextStyles.sectionHeading.copyWith(
            color: AppColors.accentTeal,
            fontSize: size * 0.31,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTextStyles.cardTitle);
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        boxShadow: AppShadows.subtleList,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.accentTeal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppBorderRadius.small),
            ),
            child: Icon(icon, color: AppColors.accentTeal, size: 20),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.body),
                SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.accentTeal,
            inactiveThumbColor: AppColors.softGray,
            inactiveTrackColor: AppColors.lightGray,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconBackgroundColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppBorderRadius.card),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppBorderRadius.card),
              boxShadow: AppShadows.subtleList,
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: iconBackgroundColor,
                    borderRadius: BorderRadius.circular(AppBorderRadius.small),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.body),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.secondaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.tertiaryText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
