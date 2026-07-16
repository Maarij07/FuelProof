import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart'
    show
        getDownloadsDirectory,
        getApplicationDocumentsDirectory;
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/text_styles.dart';
import '../../core/models/report_models.dart';
import '../../core/models/transaction_models.dart';
import '../../core/repositories/transaction_repository.dart';
import '../../core/state/app_providers.dart';
import '../../shared/widgets/app_bottom_navigation_bar.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  late final TransactionRepository _repo;

  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isStatsLoading = false;
  bool _isDownloading = false;
  bool _fromCache = false;
  String? _errorMessage;
  List<Transaction> _all = [];
  MyReportSummary? _summary;
  MyComparative? _comparative;
  String _period = 'monthly';

  @override
  void initState() {
    super.initState();
    _repo = ref.read(transactionRepositoryProvider);
    _loadWithCache();
  }

  Future<void> _loadWithCache() async {
    final cached = _repo.getCachedTransactions();
    if (cached != null && cached.items.isNotEmpty) {
      setState(() {
        _all = cached.items;
        _fromCache = true;
        _isLoading = false;
      });
    }
    await Future.wait([
      _load(silent: cached != null),
      _loadStats(),
    ]);
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = _all.isEmpty;
        _isRefreshing = _all.isNotEmpty;
        _errorMessage = null;
      });
    } else {
      if (mounted) setState(() => _isRefreshing = true);
    }
    try {
      final res = await _repo.getMyTransactions(limit: 100, offset: 0);
      if (!mounted) return;
      setState(() {
        _all = res.items;
        _isLoading = false;
        _isRefreshing = false;
        _fromCache = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        if (_all.isEmpty) {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        }
      });
    }
  }

  Future<void> _loadStats() async {
    if (mounted) setState(() => _isStatsLoading = true);
    try {
      if (_period == 'all') {
        final summary = await _repo.getMyReportSummary(period: _period);
        if (!mounted) return;
        setState(() {
          _summary = summary;
          _comparative = null;
          _isStatsLoading = false;
        });
      } else {
        final results = await Future.wait([
          _repo.getMyReportSummary(period: _period),
          _repo.getMyComparative(period: _period),
        ]);
        if (!mounted) return;
        setState(() {
          _summary = results[0] as MyReportSummary;
          _comparative = results[1] as MyComparative;
          _isStatsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isStatsLoading = false);
    }
  }

  List<Transaction> get _filtered {
    final now = DateTime.now();
    return _all.where((t) {
      final date = DateTime.tryParse(t.createdAt)?.toLocal();
      if (date == null) return true;
      switch (_period) {
        case 'daily':
          return date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
        case 'weekly':
          return date.isAfter(now.subtract(const Duration(days: 7)));
        case 'monthly':
          return date.year == now.year && date.month == now.month;
        default:
          return true;
      }
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  double get _totalSpent =>
      _summary?.totalSpent ??
      _filtered.fold(0.0, (s, t) => s + t.totalAmount);
  double get _totalLitres =>
      _summary?.totalLitres ??
      _filtered.fold(0.0, (s, t) => s + t.litresDispensed);
  int get _fillCount => _summary?.transactionCount ?? _filtered.length;

  String _pkr(double v) =>
      'PKR ${NumberFormat('#,##0', 'en_US').format(v)}';

  String _formatDate(String raw) {
    final d = DateTime.tryParse(raw)?.toLocal();
    if (d == null) return raw;
    return DateFormat('dd MMM yyyy, hh:mm a').format(d);
  }

  Future<void> _export(String format) async {
    setState(() => _isDownloading = true);
    try {
      final bytes =
          await _repo.exportMyReport(format: format, period: _period);
      final ts = DateTime.now().millisecondsSinceEpoch;
      final filename = 'FuelGuard_${_period}_$ts.$format';

      // Prefer the public Downloads directory; fall back to documents dir.
      Directory? dir = await getDownloadsDirectory();
      dir ??= await getApplicationDocumentsDirectory();

      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);

      if (!mounted) return;

      final uri = Uri.file(file.path);
      final opened = await canLaunchUrl(uri) &&
          await launchUrl(uri, mode: LaunchMode.externalApplication)
              .then((_) => true)
              .catchError((_) => false);

      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to Downloads: $filename'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Export failed: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppColors.alert,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      bottomNavigationBar: const AppBottomNavigationBar(currentIndex: 0),
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back_rounded, color: AppColors.primaryText),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text('My Reports', style: AppTextStyles.sectionHeading),
        centerTitle: true,
        actions: [
          if (_isDownloading)
            Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.accentTeal),
              ),
            ),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppColors.primaryText),
            onPressed: (_isLoading || _isRefreshing)
                ? null
                : () {
                    _load();
                    _loadStats();
                  },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _all.isEmpty
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: () async {
                    await Future.wait([_load(), _loadStats()]);
                  },
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(AppSpacing.md,
                              AppSpacing.md, AppSpacing.md, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStatusBanner(),
                              _buildPeriodSelector(),
                              SizedBox(height: AppSpacing.md),
                              _buildSummaryRow(),
                              SizedBox(height: AppSpacing.md),
                              if (_summary != null &&
                                  _summary!.dailySpending.isNotEmpty) ...[
                                _buildSpendingChart(),
                                SizedBox(height: AppSpacing.md),
                              ],
                              if (_summary != null &&
                                  _summary!.fuelBreakdown.isNotEmpty) ...[
                                _buildFuelBreakdown(),
                                SizedBox(height: AppSpacing.md),
                              ],
                              if (_comparative != null) ...[
                                _buildComparativeCard(),
                                SizedBox(height: AppSpacing.md),
                              ],
                              _buildExportButtons(),
                              SizedBox(height: AppSpacing.md),
                              Text('Transaction History',
                                  style: AppTextStyles.cardTitle.copyWith(
                                      color: AppColors.primaryText)),
                              SizedBox(height: AppSpacing.sm),
                            ],
                          ),
                        ),
                      ),
                      if (_filtered.isEmpty)
                        SliverFillRemaining(child: _buildEmpty())
                      else
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(AppSpacing.md, 0,
                              AppSpacing.md, AppSpacing.xxl),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) =>
                                  _buildTransactionCard(_filtered[i]),
                              childCount: _filtered.length,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  // ── Status banner ───────────────────────────────────────────────────────────

  Widget _buildStatusBanner() {
    if (!_isRefreshing && !_fromCache && !_isStatsLoading) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isRefreshing || _isStatsLoading) ...[
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                  strokeWidth: 1.5, color: AppColors.accentTeal),
            ),
            SizedBox(width: AppSpacing.xs),
            Text(
              _isRefreshing ? 'Refreshing…' : 'Loading stats…',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.accentTeal),
            ),
          ] else if (_fromCache) ...[
            Icon(Icons.offline_bolt_outlined,
                size: 12, color: AppColors.secondaryText),
            SizedBox(width: 4),
            Text(
              'Showing cached data',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.secondaryText),
            ),
          ],
        ],
      ),
    );
  }

  // ── Period selector ─────────────────────────────────────────────────────────

  Widget _buildPeriodSelector() {
    const periods = [
      ('daily', 'Today'),
      ('weekly', 'This Week'),
      ('monthly', 'This Month'),
      ('all', 'All Time'),
    ];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: periods.length,
        separatorBuilder: (_, _) => SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) {
          final (val, label) = periods[i];
          final sel = _period == val;
          return GestureDetector(
            onTap: () {
              if (_period == val) return;
              setState(() {
                _period = val;
                _summary = null;
                _comparative = null;
              });
              _loadStats();
            },
            child: Container(
              height: 36,
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: sel ? AppColors.accentTeal : AppColors.white,
                borderRadius: BorderRadius.circular(AppBorderRadius.pill),
                border: Border.all(
                  color: sel ? AppColors.accentTeal : AppColors.softGray,
                ),
              ),
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: sel ? AppColors.white : AppColors.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Summary tiles ───────────────────────────────────────────────────────────

  Widget _buildSummaryRow() {
    return Row(
      children: [
        Expanded(
          child: _statTile('Spent', _pkr(_totalSpent),
              Icons.payments_rounded, AppColors.brandNavy),
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _statTile(
              'Litres',
              '${_totalLitres.toStringAsFixed(1)} L',
              Icons.local_gas_station_rounded,
              AppColors.accentTeal),
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _statTile('Fills', '$_fillCount',
              Icons.receipt_long_rounded, AppColors.success),
        ),
      ],
    );
  }

  Widget _statTile(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        boxShadow: AppShadows.subtleList,
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w700, color: color, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.secondaryText),
          ),
        ],
      ),
    );
  }

  // ── Spending trend chart ────────────────────────────────────────────────────

  Widget _buildSpendingChart() {
    final raw = _summary!.dailySpending;
    final display =
        raw.length > 14 ? raw.sublist(raw.length - 14) : raw;

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Spending Trend', style: AppTextStyles.cardTitle),
              if (_isStatsLoading)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AppColors.accentTeal),
                ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          _SpendingBarChart(data: display),
        ],
      ),
    );
  }

  // ── Fuel breakdown ──────────────────────────────────────────────────────────

  Widget _buildFuelBreakdown() {
    final entries = [..._summary!.fuelBreakdown]
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final maxAmount =
        entries.fold(0.0, (m, e) => max(m, e.amount));

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
          Text('Fuel Breakdown', style: AppTextStyles.cardTitle),
          SizedBox(height: AppSpacing.md),
          ...entries.map((e) => _buildFuelBar(e, maxAmount)),
        ],
      ),
    );
  }

  static const _fuelColors = {
    'petrol': AppColors.accentTeal,
    'diesel': AppColors.brandNavy,
    'premium': AppColors.warning,
    'cng': AppColors.success,
    'lpg': Color(0xFF8B5CF6),
  };

  Widget _buildFuelBar(FuelBreakdownEntry e, double maxAmount) {
    final frac =
        maxAmount > 0 ? (e.amount / maxAmount).clamp(0.0, 1.0) : 0.0;
    final color = _fuelColors[e.fuelType] ?? AppColors.accentTeal;
    final label =
        e.fuelType[0].toUpperCase() + e.fuelType.substring(1);

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText),
              ),
              Text(
                '${_pkr(e.amount)}  •  ${e.litres.toStringAsFixed(1)} L  •  ${e.count} fills',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.secondaryText),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xs),
          LayoutBuilder(
            builder: (ctx, constraints) => Stack(
              children: [
                Container(
                  height: 6,
                  width: constraints.maxWidth,
                  decoration: BoxDecoration(
                    color: AppColors.lightGray,
                    borderRadius:
                        BorderRadius.circular(AppBorderRadius.pill),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  height: 6,
                  width: constraints.maxWidth * frac,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius:
                        BorderRadius.circular(AppBorderRadius.pill),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Comparative analysis ────────────────────────────────────────────────────

  Widget _buildComparativeCard() {
    final c = _comparative!;
    const periodLabels = {
      'daily': 'vs Yesterday',
      'weekly': 'vs Last Week',
      'monthly': 'vs Last Month',
    };

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Comparative Analysis',
                  style: AppTextStyles.cardTitle),
              Text(
                periodLabels[_period] ?? '',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.secondaryText),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                  child: _compareTile('Spending',
                      _pkr(c.current.totalSpent), c.changePctSpent)),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                  child: _compareTile(
                      'Litres',
                      '${c.current.totalLitres.toStringAsFixed(1)} L',
                      c.changePctLitres)),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                  child: _compareTile(
                      'Fills', '${c.current.count}', c.changePctCount)),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Previous: ${_pkr(c.previous.totalSpent)}  •  ${c.previous.totalLitres.toStringAsFixed(1)} L  •  ${c.previous.count} fills',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.tertiaryText),
          ),
        ],
      ),
    );
  }

  Widget _compareTile(String label, String value, double pct) {
    final isUp = pct > 0;
    final isFlat = pct == 0.0;
    final changeColor = isFlat
        ? AppColors.secondaryText
        : (isUp ? AppColors.alert : AppColors.success);
    final arrow = isFlat ? '→' : (isUp ? '↑' : '↓');

    return Container(
      padding: EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
                fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(arrow,
                  style: TextStyle(
                      color: changeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
              SizedBox(width: 2),
              Text(
                '${pct.abs().toStringAsFixed(1)}%',
                style: AppTextStyles.caption.copyWith(
                    color: changeColor, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
                color: AppColors.tertiaryText, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ── Export buttons ──────────────────────────────────────────────────────────

  Widget _buildExportButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isDownloading ? null : () => _export('pdf'),
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
            label: const Text('Export PDF'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.alert,
              side: BorderSide(
                  color: AppColors.alert.withValues(alpha: 0.5)),
              padding: EdgeInsets.symmetric(
                  vertical: AppSpacing.sm + 2),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppBorderRadius.button),
              ),
            ),
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isDownloading ? null : () => _export('csv'),
            icon: const Icon(Icons.table_chart_rounded, size: 16),
            label: const Text('Export CSV'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accentTeal,
              side: BorderSide(
                  color: AppColors.accentTeal.withValues(alpha: 0.5)),
              padding: EdgeInsets.symmetric(
                  vertical: AppSpacing.sm + 2),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppBorderRadius.button),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Error / empty states ────────────────────────────────────────────────────

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded,
                color: AppColors.alert, size: 48),
            SizedBox(height: AppSpacing.md),
            Text('Could not load transactions',
                style: AppTextStyles.cardTitle,
                textAlign: TextAlign.center),
            SizedBox(height: AppSpacing.sm),
            Text(
              _errorMessage!,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.secondaryText),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: _loadWithCache,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentTeal,
                foregroundColor: AppColors.white,
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 64, color: AppColors.softGray),
          SizedBox(height: AppSpacing.md),
          Text('No transactions found',
              style: AppTextStyles.cardTitle
                  .copyWith(color: AppColors.secondaryText)),
          SizedBox(height: AppSpacing.xs),
          Text(
            'Transactions for the selected period\nwill appear here.',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.tertiaryText),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Transaction card ────────────────────────────────────────────────────────

  Widget _buildTransactionCard(Transaction t) {
    final statusColor = _statusColor(t.status);
    final fuelIcon = _fuelIcon(t.fuelType);

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/transaction-detail',
        arguments: {'transactionId': t.id},
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: AppSpacing.sm),
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppBorderRadius.card),
          boxShadow: AppShadows.subtleList,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color:
                    AppColors.accentTeal.withValues(alpha: 0.1),
                borderRadius:
                    BorderRadius.circular(AppBorderRadius.small),
              ),
              child: Icon(fuelIcon,
                  color: AppColors.accentTeal, size: 22),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t.fuelType.name[0].toUpperCase() +
                            t.fuelType.name.substring(1),
                        style: AppTextStyles.body
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _pkr(t.totalAmount),
                        style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandNavy),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${t.litresDispensed.toStringAsFixed(2)} L  •  ${_pkr(t.pricePerLitre)}/L',
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.secondaryText),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                              AppBorderRadius.pill),
                        ),
                        child: Text(
                          t.status.name,
                          style: AppTextStyles.caption.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    _formatDate(t.createdAt),
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.tertiaryText, fontSize: 11),
                  ),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.softGray, size: 18),
          ],
        ),
      ),
    );
  }

  Color _statusColor(TransactionStatus s) {
    switch (s) {
      case TransactionStatus.completed:
        return AppColors.success;
      case TransactionStatus.pending:
        return AppColors.warning;
      case TransactionStatus.failed:
        return AppColors.alert;
      case TransactionStatus.refunded:
        return AppColors.accentTeal;
    }
  }

  IconData _fuelIcon(FuelType t) {
    switch (t) {
      case FuelType.cng:
        return Icons.gas_meter_outlined;
      case FuelType.lpg:
        return Icons.propane_outlined;
      default:
        return Icons.local_gas_station_rounded;
    }
  }
}

// ── Spending bar chart ────────────────────────────────────────────────────────

class _SpendingBarChart extends StatelessWidget {
  final List<DailySpending> data;
  const _SpendingBarChart({required this.data});

  static const double _barAreaH = 100.0;
  static const double _labelH   = 22.0;
  static const double _barW     = 24.0;
  static const double _colW     = 44.0;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'No spending data',
          style: AppTextStyles.caption
              .copyWith(color: AppColors.tertiaryText),
        ),
      );
    }

    final maxAmt = data.map((e) => e.amount).reduce(max);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((d) {
          final frac   = maxAmt > 0 ? (d.amount / maxAmt).clamp(0.0, 1.0) : 0.0;
          final barH   = max(4.0, _barAreaH * frac);
          final label  = d.date.length >= 10 ? d.date.substring(5) : d.date;

          return SizedBox(
            width: _colW,
            height: _barAreaH + _labelH,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // bar
                Container(
                  width: _barW,
                  height: barH,
                  decoration: BoxDecoration(
                    color: AppColors.accentTeal,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // date label
                SizedBox(
                  height: _labelH - 4,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 9,
                      color: AppColors.tertiaryText,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
