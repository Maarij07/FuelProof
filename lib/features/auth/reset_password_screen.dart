import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/spacing.dart';
import '../../core/models/error_models.dart';
import '../../core/repositories/auth_repository.dart';
import '../../core/services/api_client.dart';
import '../../core/services/firebase_auth_service.dart';
import '../../core/services/token_manager.dart';
import 'utils/auth_validators.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, this.email = ''});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  static const String _backgroundAsset = 'assets/images/authimage.png';

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late final AuthRepository _authRepository;
  late final FirebaseAuthService _firebaseAuthService;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.email;

    final tokenManager = TokenManager();
    _authRepository = AuthRepository(
      apiClient: ApiClient(tokenManager: tokenManager),
      tokenManager: tokenManager,
    );
    _firebaseAuthService = FirebaseAuthService();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
      final firebaseIdToken = await _firebaseAuthService.signInAndGetIdToken(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      await _authRepository.resetPassword(
        firebaseIdToken: firebaseIdToken,
        newPassword: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset successfully. Please log in again.'),
        ),
      );

      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/sign-in', (route) => false);
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message =
          error is AppError &&
              error.detail != null &&
              error.detail!.trim().isNotEmpty
          ? error.detail!
          : error is AppError
          ? error.message
          : 'Unable to reset password right now.';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
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
            errorBuilder: (context, error, stackTrace) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF8F6EF), Color(0xFFF2F4F7)],
                ),
              ),
            ),
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
                    'Reset password',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.brandNavy,
                      fontWeight: FontWeight.w800,
                      fontSize: 30,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    'Use the email link to sign in and choose a new password.',
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email],
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.mail_outline_rounded),
                                ),
                                validator: AuthValidators.validateEmail,
                              ),
                              SizedBox(height: AppSpacing.md),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                decoration: InputDecoration(
                                  labelText: 'New Password',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                  ),
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                  ),
                                ),
                                validator: AuthValidators
                                    .validatePasswordForCreateAccount,
                              ),
                              SizedBox(height: AppSpacing.md),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                textInputAction: TextInputAction.done,
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                  ),
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword;
                                      });
                                    },
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                  ),
                                ),
                                validator: (value) =>
                                    AuthValidators.validateConfirmPassword(
                                      value,
                                      _passwordController.text,
                                    ),
                                onFieldSubmitted: (_) => _submit(),
                              ),
                              SizedBox(height: AppSpacing.lg),
                              SizedBox(
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isSubmitting ? null : _submit,
                                  child: _isSubmitting
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  AppColors.white,
                                                ),
                                          ),
                                        )
                                      : const Text('Reset Password'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
