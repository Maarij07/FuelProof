import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/spacing.dart';

class OtpVerifyScreen extends StatefulWidget {
  final String email;
  final String flow;

  const OtpVerifyScreen({super.key, this.email = '', this.flow = 'signup'});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  static const String _backgroundAsset = 'assets/images/authimage.png';

  final _otpController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    FocusScope.of(context).unfocus();

    // For signup flow, tokens are already saved — just continue to home.
    if (widget.flow == 'signup') {
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      return;
    }

    // reset_password flow: validate 6-digit code
    if (_otpController.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid 6-digit OTP code')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    await Future<void>.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    Navigator.of(context).pushReplacementNamed(
      '/reset-password',
      arguments: {'email': widget.email.trim()},
    );
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
                        ? 'Verify reset OTP'
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
                        ? 'Enter the 6-digit code sent to $emailText to reset your password'
                        : 'We sent a verification email to $emailText',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.secondaryText,
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
                            if (widget.flow == 'signup') ...[
                              // Signup: email verification sent, just continue
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
                                'A verification link has been sent to ${widget.email.trim().isEmpty ? 'your email' : widget.email.trim()}. Verify your email, then continue.',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppColors.secondaryText),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: AppSpacing.lg),
                            ] else ...[
                              // Reset password: need OTP input
                              TextFormField(
                                controller: _otpController,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'OTP Code',
                                  hintText: '123456',
                                  prefixIcon: Icon(Icons.verified_user_outlined),
                                  counterText: '',
                                ),
                              ),
                              SizedBox(height: AppSpacing.md),
                            ],
                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : _verifyOtp,
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
                                            : 'Verify OTP',
                                      ),
                              ),
                            ),
                            if (widget.flow == 'reset_password') ...[
                              SizedBox(height: AppSpacing.sm),
                              TextButton(
                                onPressed: () {},
                                child: const Text('Resend OTP'),
                              ),
                            ],
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
