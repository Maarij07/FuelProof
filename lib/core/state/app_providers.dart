import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/auth_repository.dart';
import '../repositories/chat_repository.dart';
import '../repositories/fleet_repository.dart';
import '../repositories/price_repository.dart';
import '../repositories/session_repository.dart';
import '../repositories/station_repository.dart';
import '../repositories/transaction_repository.dart';
import '../services/api_client.dart';
import '../services/firebase_auth_service.dart';
import '../services/token_manager.dart';

final tokenManagerProvider = Provider<TokenManager>((ref) {
  return TokenManager();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenManager = ref.watch(tokenManagerProvider);
  return ApiClient(tokenManager: tokenManager);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenManager: ref.watch(tokenManagerProvider),
  );
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(apiClient: ref.watch(apiClientProvider));
});

final stationRepositoryProvider = Provider<StationRepository>((ref) {
  return StationRepository(apiClient: ref.watch(apiClientProvider));
});

final priceRepositoryProvider = Provider<PriceRepository>((ref) {
  return PriceRepository(apiClient: ref.watch(apiClientProvider));
});

final fleetRepositoryProvider = Provider<FleetRepository>((ref) {
  return FleetRepository(apiClient: ref.watch(apiClientProvider));
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository(apiClient: ref.watch(apiClientProvider));
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(apiClient: ref.watch(apiClientProvider));
});

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

final authStatusProvider = FutureProvider<bool>((ref) async {
  final tokenManager = ref.watch(tokenManagerProvider);
  return tokenManager.isLoggedIn();
});
