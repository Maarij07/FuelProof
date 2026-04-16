import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/spacing.dart';
import '../../core/models/error_models.dart';
import '../../core/repositories/auth_repository.dart';
import '../../core/services/api_client.dart';
import '../../core/services/token_manager.dart';

class OtpVerifyScreen extends StatefulWidget {
  final String email;
  final String flow;

  const OtpVerifyScreen({super.key, this.email = '', this.flow = 'signup'});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  static const String _backgroundAsset = 'assets/images/authimage.png';

  late final AuthRepository _authRepository;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final tokenManager = TokenManager();
    _authRepository = AuthRepository(
      apiClient: ApiClient(tokenManager: tokenManager),
      tokenManager: tokenManager,
    );
  }

  Future<void> _continue() async {
    FocusScope.of(context).unfocus();

    if (widget.flow == 'signup') {
      setState(() => _isSubmitting = true);

      try {
        final isVerified = await _authRepository.isAccountVerified();

        if (!mounted) return;
        setState(() => _isSubmitting = false);

        if (isVerified) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/home', (route) => false);
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please verify your email first, then tap Continue to App.',
            ),
          ),
        );
      } catch (error) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);

        final message =
            error is AppError &&
                error.detail != null &&
                error.detail!.trim().isNotEmpty
            ? error.detail!
            : 'Could not verify account status. Please try again.';

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }

      return;
    }

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).pushReplacementNamed('/sign-in');
  }

  @override
  Widget build(BuildContext context) {
    final emailText = widget.email.trim().isEmpty
        ? 'your registered email'
        : widget.email.trim();

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _backgroundAsset,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x88FFFDF7),
                  Color(0x44FFFFFF),
                  Color(0x66F7F9FC),
                ],
                stops: [0.0, 0.42, 1.0],
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x1F000000),
                  Color(0x2B000000),
                  Color(0x47000000),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.lg,
                bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: AppSpacing.md),
                  Text(
                    widget.flow == 'reset_password'
                        ? 'Check your email'
                        : 'Verify your email',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.brandNavy,
                      fontWeight: FontWeight.w800,
                      fontSize: 30,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    widget.flow == 'reset_password'
                        ? 'A password reset verification link has been sent to $emailText'
                        : 'We sent a verification email to $emailText',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primaryText.withValues(alpha: 0.88),
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxl),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.44),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.97),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.white.withValues(alpha: 0.30),
                              blurRadius: 22,
                              offset: const Offset(0, -4),
                            ),
                            BoxShadow(
                              color: AppColors.brandNavy.withValues(
                                alpha: 0.14,
                              ),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Icon(
                              Icons.mark_email_read_outlined,
                              size: 48,
                              color: AppColors.accentTeal,
                            ),
                            SizedBox(height: AppSpacing.md),
                            Text(
                              'Check your inbox',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: AppSpacing.sm),
                            Text(
                              widget.flow == 'signup'
                                  ? 'A verification link has been sent to ${widget.email.trim().isEmpty ? 'your email' : widget.email.trim()}. Verify your email, then continue.'
                                  : 'Use the link in your email to continue resetting your password.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.secondaryText),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: AppSpacing.lg),
                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : _continue,
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        widget.flow == 'signup'
                                            ? 'Continue to App'
                                            : 'Done',
                                      ),
                              ),
                            ),
                          ],
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
    );
  }
}
