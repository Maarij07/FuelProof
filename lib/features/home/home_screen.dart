import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/text_styles.dart';
import '../../core/models/auth_models.dart';
import '../../core/models/transaction_models.dart';
import '../../core/repositories/auth_repository.dart';
import '../../core/repositories/transaction_repository.dart';
import '../../core/services/api_client.dart';
import '../../core/services/token_manager.dart';
import '../../shared/widgets/app_bottom_navigation_bar.dart';
import '../../shared/widgets/dashboard_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TokenManager _tokenManager;
  late final ApiClient _apiClient;
  late final AuthRepository _authRepository;
  late final TransactionRepository _transactionRepository;

  User? _user;
  List<FuelPrice> _fuelPrices = const [];
  List<Transaction> _recentTransactions = const [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _transactionsError;
  String? _pricesError;

  @override
  void initState() {
    super.initState();
    _tokenManager = TokenManager();
    _apiClient = ApiClient(tokenManager: _tokenManager);
    _authRepository = AuthRepository(
      apiClient: _apiClient,
      tokenManager: _tokenManager,
    );
    _transactionRepository = TransactionRepository(apiClient: _apiClient);
    _loadDashboardData();
  }

  void _navigateToScreen(String routeName) {
    Navigator.of(context).pushNamed(routeName);
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _transactionsError = null;
      _pricesError = null;
    });

    try {
      final userFuture = _authRepository.getCurrentUser();
      final transactionsFuture = _transactionRepository.getMyTransactions(
        limit: 3,
        offset: 0,
      );
      final pricesFuture = _transactionRepository.getCurrentPrices();

      final user = await userFuture;

      List<Transaction> recentTransactions = const [];
      try {
        final transactionResponse = await transactionsFuture;
        recentTransactions = transactionResponse.items;
      } catch (e) {
        _transactionsError = 'Recent transactions are unavailable right now.';
      }

      List<FuelPrice> fuelPrices = const [];
      try {
        fuelPrices = await pricesFuture;
      } catch (e) {
        _pricesError = 'Live fuel prices are unavailable right now.';
      }

      if (!mounted) return;

      setState(() {
        _user = user;
        _recentTransactions = recentTransactions;
        _fuelPrices = fuelPrices;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to load your account data right now';
        _isLoading = false;
      });
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _displayName() {
    final fullName = _user?.fullName.trim();
    if (fullName == null || fullName.isEmpty) return 'Ayesha';
    return fullName.split(' ').first;
  }

  String _roleLabel() {
    final role = (_user?.role ?? 'customer').trim();
    if (role.isEmpty) return 'Customer';
    return role[0].toUpperCase() + role.substring(1).toLowerCase();
  }

  String _fuelTypeLabel(FuelType fuelType) {
    switch (fuelType) {
      case FuelType.petrol:
        return 'Petrol';
      case FuelType.diesel:
        return 'Diesel';
      case FuelType.premium:
        return 'Premium';
      case FuelType.cng:
        return 'CNG';
      case FuelType.lpg:
        return 'LPG';
    }
  }

  String _transactionStatusLabel(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.failed:
        return 'Failed';
      case TransactionStatus.refunded:
        return 'Refunded';
    }
  }

  Color _transactionStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return AppColors.success;
      case TransactionStatus.pending:
        return AppColors.warning;
      case TransactionStatus.failed:
        return AppColors.alert;
      case TransactionStatus.refunded:
        return AppColors.brandNavy;
    }
  }

  IconData _fuelTypeIcon(FuelType fuelType) {
    switch (fuelType) {
      case FuelType.petrol:
      case FuelType.premium:
        return Icons.local_fire_department_rounded;
      case FuelType.diesel:
        return Icons.oil_barrel_rounded;
      case FuelType.cng:
        return Icons.local_gas_station_rounded;
      case FuelType.lpg:
        return Icons.propane_tank_rounded;
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'en_PK',
      symbol: 'PKR ',
      decimalDigits: 2,
    ).format(amount);
  }

  String _formatUpdatedDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate).toLocal();
      return 'Updated ${DateFormat.MMMd().format(date)}';
    } catch (_) {
      return 'Updated recently';
    }
  }

  String _formatRelativeTime(String isoDate) {
    try {
      final date = DateTime.parse(isoDate).toLocal();
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) return 'Just now';
      if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
      if (difference.inHours < 24) return '${difference.inHours}h ago';
      return DateFormat('MMM d · h:mm a').format(date);
    } catch (_) {
      return 'Recently';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              SizedBox(height: AppSpacing.lg),
              Text(
                '${_greeting()}, ${_displayName()}',
                style: AppTextStyles.displayHero.copyWith(
                  fontSize: 28,
                  height: 1.0,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              _buildRoleChip(),
              SizedBox(height: AppSpacing.lg),
              if (_transactionsError != null) ...[
                _buildWarningCard(_transactionsError!),
                SizedBox(height: AppSpacing.md),
              ],
              if (_pricesError != null) ...[
                _buildWarningCard(_pricesError!),
                SizedBox(height: AppSpacing.md),
              ],
              ScanToStartCard(onTap: () => _navigateToScreen('/scan-qr')),
              SizedBox(height: AppSpacing.md),
              _buildSecondaryActions(),
              SizedBox(height: AppSpacing.lg),
              _buildLiveFuelPricesSection(),
              SizedBox(height: AppSpacing.lg),
              if (_errorMessage != null) _buildErrorCard(),
              if (_errorMessage != null) SizedBox(height: AppSpacing.lg),
              _buildRecentActivitySection(),
              SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToScreen('/scan-qr'),
        backgroundColor: AppColors.accentTeal,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.qr_code_scanner_rounded),
        label: const Text('Scan QR'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: const AppBottomNavigationBar(currentIndex: 0),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'FuelProof',
          style: AppTextStyles.sectionHeading.copyWith(
            fontSize: 24,
            letterSpacing: -1.1,
          ),
        ),
        IconButton(
          onPressed: () => _navigateToScreen('/notifications'),
          icon: Icon(
            Icons.notifications_none_rounded,
            color: AppColors.primaryText,
            size: 30,
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSmallActionCard(
                icon: Icons.qr_code_scanner_rounded,
                label: 'Scan QR',
                onTap: () => _navigateToScreen('/scan-qr'),
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildSmallActionCard(
                icon: Icons.location_on_rounded,
                label: 'Find Stations',
                onTap: () => _navigateToScreen('/station-finder'),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildSmallActionCard(
                icon: Icons.directions_car_rounded,
                label: 'My Vehicles',
                onTap: () => _navigateToScreen('/fleet-vehicles'),
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildSmallActionCard(
                icon: Icons.compare_arrows_rounded,
                label: 'Price Compare',
                onTap: () => _navigateToScreen('/price-compare'),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.md),
        _buildSmallActionCard(
          icon: Icons.bar_chart_rounded,
          label: 'My Reports',
          onTap: () => _navigateToScreen('/reports'),
        ),
      ],
    );
  }

  Widget _buildRoleChip() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.tealLight,
        borderRadius: BorderRadius.circular(AppBorderRadius.pill),
      ),
      child: Text(
        _roleLabel(),
        style: AppTextStyles.caption.copyWith(
          color: AppColors.accentTeal,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.alertLight,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.alert),
          SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(_errorMessage!, style: AppTextStyles.body)),
          TextButton(onPressed: _loadDashboardData, child: Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildWarningCard(String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.warning),
          SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message, style: AppTextStyles.body)),
        ],
      ),
    );
  }

  Widget _buildLiveFuelPricesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Live Fuel Prices',
          style: AppTextStyles.sectionHeading.copyWith(fontSize: 24),
        ),
        SizedBox(height: AppSpacing.md),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_fuelPrices.isEmpty)
          _emptySection('No live prices available')
        else
          SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _fuelPrices.length,
              separatorBuilder: (_, _) => SizedBox(width: AppSpacing.md),
              itemBuilder: (context, index) {
                final price = _fuelPrices[index];
                return Container(
                  width: 220,
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppBorderRadius.card),
                    border: Border.all(
                      color: AppColors.softGray.withValues(alpha: 0.45),
                    ),
                    boxShadow: AppShadows.subtleList,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.tealLight,
                          borderRadius: BorderRadius.circular(
                            AppBorderRadius.pill,
                          ),
                        ),
                        child: Text(
                          _fuelTypeLabel(price.fuelType),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.accentTeal,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        '${_formatCurrency(price.pricePerLitre)} / L',
                        style: AppTextStyles.cardTitle.copyWith(
                          color: AppColors.brandNavy,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        _formatUpdatedDate(price.effectiveFrom),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _emptySection(String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        border: Border.all(color: AppColors.softGray.withValues(alpha: 0.45)),
      ),
      child: Text(message, style: AppTextStyles.body),
    );
  }

  Widget _buildSmallActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppBorderRadius.card),
            border: Border.all(
              color: AppColors.softGray.withValues(alpha: 0.45),
            ), // UPDATED: Replaced withOpacity with withValues
            boxShadow: AppShadows.subtleList,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.accentTeal, size: 18),
              SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: AppTextStyles.sectionHeading.copyWith(fontSize: 24),
        ),
        SizedBox(height: AppSpacing.md),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_recentTransactions.isEmpty)
          _emptySection('No transactions yet')
        else
          ..._recentTransactions.map(
            (transaction) => Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: _activityTile(
                station:
                    transaction.stationId ??
                    _fuelTypeLabel(transaction.fuelType),
                detail:
                    '${transaction.litresDispensed.toStringAsFixed(2)} L • ${_formatCurrency(transaction.totalAmount)}',
                time: _formatRelativeTime(transaction.createdAt),
                status: _transactionStatusLabel(transaction.status),
                statusColor: _transactionStatusColor(transaction.status),
                icon: _fuelTypeIcon(transaction.fuelType),
                onTap: () => Navigator.of(context).pushNamed(
                  '/transaction-detail',
                  arguments: {'transactionId': transaction.id},
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _activityTile({
    required String station,
    required String detail,
    required String time,
    required String status,
    required Color statusColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        child: Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppBorderRadius.card),
            border: Border.all(
              color: AppColors.softGray.withValues(alpha: 0.45),
            ),
            boxShadow: AppShadows.subtleList,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.tealLight,
                  borderRadius: BorderRadius.circular(AppBorderRadius.small),
                ),
                child: Icon(icon, color: AppColors.accentTeal, size: 20),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(station, style: AppTextStyles.cardTitle),
                    SizedBox(height: AppSpacing.xs),
                    Text(detail, style: AppTextStyles.caption),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppBorderRadius.pill),
                    ),
                    child: Text(
                      status,
                      style: AppTextStyles.caption.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(time, style: AppTextStyles.caption),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
