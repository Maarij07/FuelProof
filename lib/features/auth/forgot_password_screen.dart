import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/spacing.dart';
import 'services/auth_service.dart';
import 'utils/auth_validators.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const String _backgroundAsset = 'assets/images/authimage.png';

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await AuthService.instance.sendPasswordResetLink(
        email: _emailController.text,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset link has been sent.')),
      );
      Navigator.of(context).pop();
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppColors.brandNavy,
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    'Forgot password',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.brandNavy,
                      fontWeight: FontWeight.w800,
                      fontSize: 30,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    'Enter your email to receive a reset link',
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
                          color: AppColors.white.withValues(
                            alpha: 0.22,
                          ), // UPDATED: Replaced withOpacity with withValues
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: AppColors.white.withValues(
                              alpha: 0.72,
                            ), // UPDATED: Replaced withOpacity with withValues
                          ),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.email],
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.mail_outline_rounded),
                                ),
                                validator: AuthValidators.validateEmail,
                                onFieldSubmitted: (_) => _submit(),
                              ),
                              SizedBox(height: AppSpacing.lg),
                              SizedBox(
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isSubmitting ? null : _submit,
                                  child: _isSubmitting
                                      ? SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.4,
                                            color: AppColors.white,
                                          ),
                                        )
                                      : const Text('Send reset link'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
