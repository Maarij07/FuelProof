import 'package:flutter/material.dart';
import 'core/constants/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/auth/create_account_screen.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/auth/otp_verify_screen.dart';
import 'features/auth/reset_password_screen.dart';
import 'features/home/home_screen.dart';
import 'features/home/scan_qr_screen.dart';
import 'features/home/live_session_screen.dart';
import 'features/home/transaction_success_screen.dart';
import 'features/home/transaction_history_screen.dart';
import 'features/home/transaction_detail_screen.dart';
import 'features/home/station_finder_screen.dart';
import 'features/home/route_stations_screen.dart';
import 'features/home/station_detail_screen.dart';
import 'features/home/favorites_screen.dart';
import 'features/home/price_compare_screen.dart';
import 'features/home/cheapest_fuel_screen.dart';
import 'features/home/price_alerts_screen.dart';
import 'features/home/price_history_screen.dart';
import 'features/home/fleet_vehicles_screen.dart';
import 'features/home/fleet_vehicle_detail_screen.dart';
import 'features/home/fleet_drivers_screen.dart';
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
            '/otp-verify': (context) {
              final args = ModalRoute.of(context)?.settings.arguments;
              final email = args is Map<String, dynamic>
                  ? (args['email'] as String? ?? '')
                  : '';
              final flow = args is Map<String, dynamic>
                  ? (args['flow'] as String? ?? 'signup')
                  : 'signup';
              return OtpVerifyScreen(email: email, flow: flow);
            },
            '/reset-password': (context) {
              final args = ModalRoute.of(context)?.settings.arguments;
              final email = args is Map<String, dynamic>
                  ? (args['email'] as String? ?? '')
                  : '';
              return ResetPasswordScreen(email: email);
            },
            '/home': (context) => const HomeScreen(),
            '/scan-qr': (context) => const ScanQrScreen(),
            '/live-session': (context) => const LiveSessionScreen(),
            '/transaction-success': (context) {
              final args = ModalRoute.of(context)?.settings.arguments;
              final transactionId = args is Map<String, dynamic>
                  ? (args['transactionId'] as String?)
                  : null;
              return TransactionSuccessScreen(transactionId: transactionId);
            },
            '/transaction-history': (context) =>
                const TransactionHistoryScreen(),
            '/transaction-detail': (context) => const TransactionDetailScreen(),
            '/station-finder': (context) => const StationFinderScreen(),
            '/route-stations': (context) => const RouteStationsScreen(),
            '/station-detail': (context) => const StationDetailScreen(),
            '/favorites': (context) => const FavoritesScreen(),
            '/price-compare': (context) => const PriceCompareScreen(),
            '/cheapest-fuel': (context) => const CheapestFuelScreen(),
            '/price-alerts': (context) => const PriceAlertsScreen(),
            '/price-history': (context) => const PriceHistoryScreen(),
            '/fleet-vehicles': (context) => const FleetVehiclesScreen(),
            '/fleet-vehicle-detail': (context) =>
                const FleetVehicleDetailScreen(),
            '/fleet-drivers': (context) => const FleetDriversScreen(),
            '/evidence-capture': (context) {
              final args = ModalRoute.of(context)?.settings.arguments;
              final transactionId = args is Map<String, dynamic>
                  ? (args['transactionId'] as String?)
                  : null;
              return EvidenceCaptureScreen(transactionId: transactionId);
            },
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
