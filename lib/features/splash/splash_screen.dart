import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/spacing.dart';
import '../../core/services/token_manager.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key}); // UPDATED

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final TokenManager _tokenManager = TokenManager();

  @override
  void initState() {
    super.initState();
    _navigateAfterSplash();
  }

  void _navigateAfterSplash() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    final isLoggedIn = await _tokenManager.isLoggedIn();

    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacementNamed(isLoggedIn ? '/home' : '/auth');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent:
                ModalRoute.of(context)?.animation ?? AlwaysStoppedAnimation(1),
            curve: Curves.easeInOut,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.primaryBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Image.asset(
                  'logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: AppSpacing.xl),

              // Brand text
            ],
          ),
        ),
      ),
    );
  }
}
