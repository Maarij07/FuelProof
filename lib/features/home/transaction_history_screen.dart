import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/text_styles.dart';
import '../../core/models/error_models.dart';
import '../../core/models/transaction_models.dart';
import '../../core/repositories/transaction_repository.dart';
import '../../core/services/api_client.dart';
import '../../core/services/token_manager.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  late final TransactionRepository _transactionRepository;
  late final TextEditingController _searchController;

  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'All';
  String _searchQuery = '';
  List<Transaction> _transactions = const [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    final tokenManager = TokenManager();
    final apiClient = ApiClient(tokenManager: tokenManager);
    _transactionRepository = TransactionRepository(apiClient: apiClient);
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _transactionRepository.getMyTransactions(
        limit: 100,
        offset: 0,
      );
      if (!mounted) return;
      setState(() {
        _transactions = response.items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      var message = 'Unable to load transactions.';
      if (e is AppError && e.detail != null && e.detail!.trim().isNotEmpty) {
        message = e.detail!;
      }
      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    }
  }

  List<Transaction> _filteredTransactions() {
    final query = _searchQuery.trim().toLowerCase();
    return _transactions.where((transaction) {
      final statusMatches =
          _selectedFilter == 'All' ||
          transaction.status.name == _selectedFilter.toLowerCase();
      final searchMatches =
          query.isEmpty ||
          transaction.id.toLowerCase().contains(query) ||
          transaction.stationId?.toLowerCase().contains(query) == true ||
          transaction.vehicleId?.toLowerCase().contains(query) == true ||
          transaction.nozzleId.toLowerCase().contains(query) ||
          transaction.fuelType.name.toLowerCase().contains(query);
      return statusMatches && searchMatches;
    }).toList();
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'en_PK',
      symbol: 'PKR ',
      decimalDigits: 2,
    ).format(amount);
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate).toLocal();
      return DateFormat('MMM d, yyyy · h:mm a').format(date);
    } catch (_) {
      return isoDate;
    }
  }

  String _statusLabel(TransactionStatus status) {
    return status.name[0].toUpperCase() + status.name.substring(1);
  }

  Color _statusColor(BuildContext context, TransactionStatus status) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (status) {
      case TransactionStatus.completed:
        return Colors.green;
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.failed:
        return colorScheme.error;
      case TransactionStatus.refunded:
        return colorScheme.secondary;
    }
  }

  String _fuelLabel(FuelType fuelType) {
    return fuelType.name[0].toUpperCase() + fuelType.name.substring(1);
  }

  void _openDetail(Transaction transaction) {
    Navigator.of(context)
        .pushNamed(
          '/transaction-detail',
          arguments: {'transactionId': transaction.id},
        )
        .then((_) => _loadTransactions());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filteredTransactions = _filteredTransactions();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Transaction History',
          style: AppTextStyles.sectionHeading.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(AppBorderRadius.input),
                boxShadow: AppShadows.subtleList,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search by ID, station, vehicle, or fuel type',
                  hintStyle: AppTextStyles.body.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                  contentPadding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final filters = [
                  'All',
                  'Completed',
                  'Pending',
                  'Failed',
                  'Refunded',
                ];
                final filter = filters[index];
                final isSelected = _selectedFilter == filter;
                return FilterChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                  backgroundColor: colorScheme.surface,
                  selectedColor: colorScheme.primary,
                  labelStyle: AppTextStyles.body.copyWith(
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppBorderRadius.pill),
                    side: BorderSide(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                    ),
                  ),
                );
              },
              separatorBuilder: (_, separatorIndex) =>
                  SizedBox(width: AppSpacing.sm),
              itemCount: 5,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                    child: Text(
                      _errorMessage!,
                      style: AppTextStyles.body.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : filteredTransactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 64,
                          color: colorScheme.outline,
                        ),
                        SizedBox(height: AppSpacing.md),
                        Text(
                          'No transactions found',
                          style: AppTextStyles.body.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadTransactions,
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      itemCount: filteredTransactions.length,
                      itemBuilder: (context, index) {
                        final transaction = filteredTransactions[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: AppSpacing.md),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(
                              AppBorderRadius.card,
                            ),
                            onTap: () => _openDetail(transaction),
                            child: Container(
                              padding: EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(
                                  AppBorderRadius.card,
                                ),
                                boxShadow: AppShadows.subtleList,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              transaction.id,
                                              style: AppTextStyles.cardTitle,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(height: AppSpacing.xs),
                                            Text(
                                              _fuelLabel(transaction.fuelType),
                                              style: AppTextStyles.caption
                                                  .copyWith(
                                                    color: colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: AppSpacing.sm,
                                          vertical: AppSpacing.xs,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _statusColor(
                                            context,
                                            transaction.status,
                                          ).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(
                                            AppBorderRadius.pill,
                                          ),
                                        ),
                                        child: Text(
                                          _statusLabel(transaction.status),
                                          style: AppTextStyles.caption.copyWith(
                                            color: _statusColor(
                                              context,
                                              transaction.status,
                                            ),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: AppSpacing.md),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Volume',
                                            style: AppTextStyles.caption
                                                .copyWith(
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                          SizedBox(height: AppSpacing.xs),
                                          Text(
                                            '${transaction.litresDispensed.toStringAsFixed(1)} L',
                                            style: AppTextStyles.body.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Amount',
                                            style: AppTextStyles.caption
                                                .copyWith(
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                          SizedBox(height: AppSpacing.xs),
                                          Text(
                                            _formatCurrency(
                                              transaction.totalAmount,
                                            ),
                                            style: AppTextStyles.body.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Date',
                                            style: AppTextStyles.caption
                                                .copyWith(
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                          SizedBox(height: AppSpacing.xs),
                                          Text(
                                            _formatDate(transaction.createdAt),
                                            style: AppTextStyles.caption
                                                .copyWith(
                                                  color: colorScheme.onSurface,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
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
