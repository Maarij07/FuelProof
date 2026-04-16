import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/constants/app_colors.dart';
import 'core/services/transaction_sync_service.dart';
import 'core/services/preferences_service.dart';
import 'core/theme/app_theme.dart';
import 'features/home/dashboard_shell.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/auth/create_account_screen.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/auth/otp_verify_screen.dart';
import 'features/auth/reset_password_screen.dart';
import 'features/home/scan_qr_screen.dart';
import 'features/home/wifi_connect_screen.dart';
import 'features/home/live_session_screen.dart';
import 'features/home/transaction_success_screen.dart';
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
import 'features/home/reports_screen.dart';
import 'features/notifications/notification_screen.dart';
import 'features/splash/splash_screen.dart';
import 'shared/widgets/debug_log_overlay.dart';

class AppThemeController {
  static late final ValueNotifier<ThemeMode> themeMode;
  static bool _initialized = false;

  static void initialize() {
    if (!_initialized) {
      themeMode = ValueNotifier(PreferencesService.getThemeMode());
      _initialized = true;
    }
  }

  static ValueNotifier<ThemeMode> getThemeMode() {
    if (!_initialized) {
      initialize();
    }
    return themeMode;
  }

  static ThemeMode get currentMode => getThemeMode().value;

  static Future<void> setThemeMode(ThemeMode mode) async {
    if (currentMode == mode) return;
    getThemeMode().value = mode;
    await PreferencesService.setThemeMode(mode);
  }

  static Future<void> toggleDarkMode(bool enabled) {
    return setThemeMode(enabled ? ThemeMode.dark : ThemeMode.light);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Hive.initFlutter();
  await PreferencesService.init();
  AppThemeController.initialize();
  await TransactionSyncService.instance.init();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeController.getThemeMode(),
      builder: (context, mode, child) {
        AppColors.setDarkMode(mode == ThemeMode.dark);

        return MaterialApp(
          title: 'FuelGuard',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            final appChild = child ?? const SizedBox.shrink();
            if (!kDebugMode) return appChild;
            return Stack(children: [appChild, const DebugLogOverlay()]);
          },
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
            '/verification': (context) {
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
              final oobCode = args is Map<String, dynamic>
                  ? (args['oobCode'] as String? ?? '')
                  : '';
              return ResetPasswordScreen(email: email, oobCode: oobCode);
            },
            '/home': (context) => const DashboardShell(initialIndex: 0),
            '/scan-qr': (context) => const ScanQrScreen(),
            '/wifi-connect': (context) => const WifiConnectScreen(),
            '/live-session': (context) => const LiveSessionScreen(),
            '/transaction-success': (context) {
              final args = ModalRoute.of(context)?.settings.arguments;
              final transactionId = args is Map<String, dynamic>
                  ? (args['transactionId'] as String?)
                  : null;
              return TransactionSuccessScreen(transactionId: transactionId);
            },
            '/transaction-history': (context) =>
                const DashboardShell(initialIndex: 1),
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
            '/reports': (context) => const ReportsScreen(),
            '/ai-chat': (context) => const DashboardShell(initialIndex: 2),
            '/profile': (context) => const DashboardShell(initialIndex: 3),
            '/notifications': (context) => const NotificationScreen(),
          },
          initialRoute: '/splash',
        );
      },
    );
  }
}
