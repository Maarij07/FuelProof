import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/spacing.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  static const String _backgroundAsset = 'assets/images/authimage.png';

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
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFF8F6EF), Color(0xFFF2F4F7)],
                  ),
                ),
              );
            },
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
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SizedBox(
                    width: double.infinity,
                    height: constraints.maxHeight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: AppSpacing.lg),
                        const _BrandHeader(),
                        const Spacer(),
                        _LoginFormCard(
                          onSignIn: () =>
                              Navigator.of(context).pushNamed('/sign-in'),
                          onCreateAccount: () => Navigator.of(
                            context,
                          ).pushNamed('/create-account'),
                        ),
                        SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.white.withOpacity(0.75)),
          ),
          child: const Icon(
            Icons.local_gas_station_rounded,
            color: AppColors.accentTeal,
            size: 22,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        Text(
          'FUEL VERIFICATION',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.brandNavy,
            fontSize: 29,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          'Trust. Verify. Save.',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.secondaryText,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _LoginFormCard extends StatelessWidget {
  const _LoginFormCard({required this.onSignIn, required this.onCreateAccount});

  final VoidCallback onSignIn;
  final VoidCallback onCreateAccount;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.white.withOpacity(0.72)),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandNavy.withOpacity(0.08),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'LOGIN FORM',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.brandNavy,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: onSignIn,
                  child: const Text('Sign in'),
                ),
              ),
              SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: onCreateAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandNavy,
                    foregroundColor: AppColors.white,
                  ),
                  child: const Text('Create Account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
