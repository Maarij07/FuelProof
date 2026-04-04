import 'package:flutter/material.dart';
import 'core/constants/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/auth/create_account_screen.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/home/home_screen.dart';
import 'features/home/scan_qr_screen.dart';
import 'features/home/live_session_screen.dart';
import 'features/home/transaction_success_screen.dart';
import 'features/home/transaction_history_screen.dart';
import 'features/home/station_finder_screen.dart';
import 'features/home/evidence_capture_screen.dart';
import 'features/home/ai_chat_screen.dart';
import 'features/home/profile_screen.dart';
import 'features/notifications/notification_screen.dart';

class AppThemeController {
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(
    ThemeMode.light,
  );
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeController.themeMode,
      builder: (context, mode, child) {
        AppColors.setDarkMode(mode == ThemeMode.dark);

        return MaterialApp(
          title: 'FuelProof',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          debugShowCheckedModeBanner: false,
          home: const SplashScreen(),
          routes: {
            '/splash': (context) => const SplashScreen(),
            '/auth': (context) => const AuthScreen(),
            '/sign-in': (context) => const SignInScreen(),
            '/create-account': (context) => const CreateAccountScreen(),
            '/forgot-password': (context) => const ForgotPasswordScreen(),
            '/home': (context) => const HomeScreen(),
            '/scan-qr': (context) => const ScanQrScreen(),
            '/live-session': (context) => const LiveSessionScreen(),
            '/transaction-success': (context) =>
                const TransactionSuccessScreen(),
            '/transaction-history': (context) =>
                const TransactionHistoryScreen(),
            '/station-finder': (context) => const StationFinderScreen(),
            '/evidence-capture': (context) => const EvidenceCaptureScreen(),
            '/ai-chat': (context) => const AIChatScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/notifications': (context) => const NotificationScreen(),
          },
          initialRoute: '/splash',
        );
      },
    );
  }
}
