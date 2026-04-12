import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/text_styles.dart';
import '../../core/models/error_models.dart';
import '../../core/models/transaction_models.dart';
import '../../core/repositories/transaction_repository.dart';
import '../../core/services/api_client.dart';
import '../../core/services/token_manager.dart';
import '../../shared/widgets/app_bottom_navigation_bar.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late final TransactionRepository _transactionRepository;

  bool _isLoading = true;
  String? _errorMessage;
  List<Transaction> _allTransactions = [];
  String _selectedPeriod = 'month'; // 'all', 'month', 'last_month', '3months'

  @override
  void initState() {
    super.initState();
    final tokenManager = TokenManager();
    _transactionRepository = TransactionRepository(
      apiClient: ApiClient(tokenManager: tokenManager),
    );
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final response = await _transactionRepository.getMyTransactions(
        limit: 500,
        offset: 0,
      );
      if (!mounted) return;
      setState(() {
        _allTransactions = response.items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final message =
          e is AppError && e.detail != null && e.detail!.trim().isNotEmpty
              ? e.detail!
              : 'Unable to load report data.';
      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    }
  }

  // ─── Period filter ────────────────────────────────────────────────────────

  List<Transaction> get _filtered {
    final now = DateTime.now();
    return _allTransactions.where((t) {
      final date = DateTime.tryParse(t.createdAt)?.toLocal();
      if (date == null) return false;
      switch (_selectedPeriod) {
        case 'month':
          return date.year == now.year && date.month == now.month;
        case 'last_month':
          final last = DateTime(now.year, now.month - 1);
          return date.year == last.year && date.month == last.month;
        case '3months':
          return date.isAfter(now.subtract(const Duration(days: 90)));
        default:
          return true;
      }
    }).toList();
  }

  // ─── Computed stats ───────────────────────────────────────────────────────

  double get _totalSpent =>
      _filtered.fold(0.0, (sum, t) => sum + t.totalAmount);

  double get _totalLitres =>
      _filtered.fold(0.0, (sum, t) => sum + t.litresDispensed);

  int get _completedCount =>
      _filtered.where((t) => t.status == TransactionStatus.completed).length;

  double get _avgPerTransaction =>
      _filtered.isEmpty ? 0 : _totalSpent / _filtered.length;

  // ─── Fuel type breakdown ──────────────────────────────────────────────────

  Map<FuelType, _FuelStat> get _fuelBreakdown {
    final map = <FuelType, _FuelStat>{};
    for (final t in _filtered) {
      final existing = map[t.fuelType];
      if (existing == null) {
        map[t.fuelType] = _FuelStat(litres: t.litresDispensed, amount: t.totalAmount, count: 1);
      } else {
        map[t.fuelType] = _FuelStat(
          litres: existing.litres + t.litresDispensed,
          amount: existing.amount + t.totalAmount,
          count: existing.count + 1,
        );
      }
    }
    return map;
  }

  // ─── Payment method breakdown ─────────────────────────────────────────────

  Map<PaymentMethod, int> get _paymentBreakdown {
    final map = <PaymentMethod, int>{};
    for (final t in _filtered) {
      map[t.paymentMethod] = (map[t.paymentMethod] ?? 0) + 1;
    }
    return map;
  }

  // ─── Monthly spending (last 6 months) ────────────────────────────────────

  List<_MonthStat> get _monthlyTrend {
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final m = DateTime(now.year, now.month - (5 - i));
      return m;
    });

    return months.map((month) {
      final spent = _allTransactions
          .where((t) {
            final d = DateTime.tryParse(t.createdAt)?.toLocal();
            return d != null && d.year == month.year && d.month == month.month;
          })
          .fold(0.0, (sum, t) => sum + t.totalAmount);
      return _MonthStat(
        label: DateFormat('MMM').format(month),
        amount: spent,
      );
    }).toList();
  }

  // ─── Formatters ───────────────────────────────────────────────────────────

  String _pkr(double amount) => NumberFormat.currency(
        locale: 'en_PK',
        symbol: 'PKR ',
        decimalDigits: 0,
      ).format(amount);

  String _fuelLabel(FuelType t) =>
      t.name[0].toUpperCase() + t.name.substring(1);

  String _paymentLabel(PaymentMethod m) =>
      m.name[0].toUpperCase() + m.name.substring(1).replaceAll('_', ' ');

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      bottomNavigationBar: const AppBottomNavigationBar(currentIndex: 0),
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Reports', style: AppTextStyles.sectionHeading),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppColors.primaryText),
            onPressed: _isLoading ? null : _loadTransactions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadTransactions,
                  child: ListView(
                    padding: EdgeInsets.all(AppSpacing.md),
                    children: [
                      _buildPeriodSelector(),
                      SizedBox(height: AppSpacing.lg),
                      _buildSummaryCards(),
                      SizedBox(height: AppSpacing.lg),
                      _buildFuelBreakdown(),
                      SizedBox(height: AppSpacing.lg),
                      _buildPaymentBreakdown(),
                      SizedBox(height: AppSpacing.lg),
                      _buildMonthlyTrend(),
                      SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, color: AppColors.alert, size: 48),
            SizedBox(height: AppSpacing.md),
            Text(_errorMessage!, style: AppTextStyles.body, textAlign: TextAlign.center),
            SizedBox(height: AppSpacing.md),
            ElevatedButton(onPressed: _loadTransactions, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  // ─── Period selector ──────────────────────────────────────────────────────

  Widget _buildPeriodSelector() {
    final periods = [
      ('month', 'This Month'),
      ('last_month', 'Last Month'),
      ('3months', 'Last 3 Months'),
      ('all', 'All Time'),
    ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: periods.length,
        separatorBuilder: (_, i) => SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final (value, label) = periods[index];
          final selected = _selectedPeriod == value;
          return GestureDetector(
            onTap: () => setState(() => _selectedPeriod = value),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: selected ? AppColors.accentTeal : AppColors.white,
                borderRadius: BorderRadius.circular(AppBorderRadius.pill),
                border: Border.all(
                  color: selected ? AppColors.accentTeal : AppColors.softGray,
                ),
              ),
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: selected ? AppColors.white : AppColors.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Summary cards ────────────────────────────────────────────────────────

  Widget _buildSummaryCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Summary', style: AppTextStyles.sectionHeading.copyWith(fontSize: 20)),
        SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: _statCard('Total Spent', _pkr(_totalSpent), Icons.payments_rounded, AppColors.brandNavy)),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: _statCard('Total Litres', '${_totalLitres.toStringAsFixed(1)} L', Icons.local_gas_station_rounded, AppColors.accentTeal)),
          ],
        ),
        SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(child: _statCard('Completed', '$_completedCount / ${_filtered.length}', Icons.receipt_long_rounded, AppColors.success)),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: _statCard('Avg per Fill', _pkr(_avgPerTransaction), Icons.trending_up_rounded, AppColors.warning)),
          ],
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        boxShadow: AppShadows.subtleList,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.small),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Text(value, style: AppTextStyles.cardTitle.copyWith(color: color, fontSize: 18)),
          SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  // ─── Fuel type breakdown ──────────────────────────────────────────────────

  Widget _buildFuelBreakdown() {
    final breakdown = _fuelBreakdown;
    if (breakdown.isEmpty) return const SizedBox.shrink();

    final maxAmount = breakdown.values.fold(0.0, (m, s) => m > s.amount ? m : s.amount);

    final colors = [
      AppColors.accentTeal,
      AppColors.brandNavy,
      AppColors.success,
      AppColors.warning,
      AppColors.alert,
    ];

    return _sectionCard(
      title: 'Fuel Type Breakdown',
      child: Column(
        children: breakdown.entries.toList().asMap().entries.map((entry) {
          final i = entry.key;
          final fuelType = entry.value.key;
          final stat = entry.value.value;
          final ratio = maxAmount > 0 ? stat.amount / maxAmount : 0.0;
          final color = colors[i % colors.length];

          return Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Text(_fuelLabel(fuelType), style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(_pkr(stat.amount), style: AppTextStyles.body.copyWith(color: color, fontWeight: FontWeight.w700)),
                        Text('${stat.litres.toStringAsFixed(1)} L · ${stat.count} fills', style: AppTextStyles.caption),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    backgroundColor: AppColors.lightGray,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Payment method breakdown ─────────────────────────────────────────────

  Widget _buildPaymentBreakdown() {
    final breakdown = _paymentBreakdown;
    if (breakdown.isEmpty) return const SizedBox.shrink();

    final total = breakdown.values.fold(0, (s, c) => s + c);

    return _sectionCard(
      title: 'Payment Methods',
      child: Column(
        children: breakdown.entries.map((entry) {
          final ratio = total > 0 ? entry.value / total : 0.0;
          return Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(_paymentLabel(entry.key), style: AppTextStyles.body),
                ),
                Expanded(
                  flex: 5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      backgroundColor: AppColors.lightGray,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentTeal),
                      minHeight: 8,
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 36,
                  child: Text(
                    '${entry.value}',
                    style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Monthly trend ────────────────────────────────────────────────────────

  Widget _buildMonthlyTrend() {
    final trend = _monthlyTrend;
    final maxAmount = trend.fold(0.0, (m, s) => m > s.amount ? m : s.amount);

    return _sectionCard(
      title: 'Monthly Spending (Last 6 Months)',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: trend.map((stat) {
          final ratio = maxAmount > 0 ? stat.amount / maxAmount : 0.0;
          const barMaxHeight = 100.0;
          final barHeight = ratio * barMaxHeight;
          final isZero = stat.amount == 0;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  if (!isZero)
                    Text(
                      _pkr(stat.amount).replaceAll('PKR ', ''),
                      style: AppTextStyles.caption.copyWith(fontSize: 9),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (isZero) SizedBox(height: 14),
                  SizedBox(height: AppSpacing.xs),
                  Container(
                    height: isZero ? 4 : barHeight,
                    decoration: BoxDecoration(
                      color: isZero
                          ? AppColors.lightGray
                          : AppColors.accentTeal.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    stat.label,
                    style: AppTextStyles.caption,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Shared card wrapper ──────────────────────────────────────────────────

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        boxShadow: AppShadows.subtleList,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.sectionHeading.copyWith(fontSize: 16)),
          SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

// ─── Data helpers ─────────────────────────────────────────────────────────────

class _FuelStat {
  final double litres;
  final double amount;
  final int count;

  const _FuelStat({
    required this.litres,
    required this.amount,
    required this.count,
  });
}

class _MonthStat {
  final String label;
  final double amount;

  const _MonthStat({required this.label, required this.amount});
}
