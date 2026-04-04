import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/widgets/app_bottom_navigation_bar.dart';

class Transaction {
  final String id;
  final String station;
  final String fuelType;
  final double volume;
  final double price;
  final DateTime date;
  final String status;

  Transaction({
    required this.id,
    required this.station,
    required this.fuelType,
    required this.volume,
    required this.price,
    required this.date,
    required this.status,
  });
}

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key}); // UPDATED

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  late TextEditingController _searchController;

  final List<Transaction> _allTransactions = [
    Transaction(
      id: 'TXN-2024-089452',
      station: 'Shell - Makati Avenue',
      fuelType: 'Premium 95 RON',
      volume: 45.0,
      price: 2250.00,
      date: DateTime.now(),
      status: 'Completed',
    ),
    Transaction(
      id: 'TXN-2024-089451',
      station: 'Caltex - BGC',
      fuelType: 'Diesel',
      volume: 60.0,
      price: 2400.00,
      date: DateTime.now().subtract(Duration(days: 1)),
      status: 'Completed',
    ),
    Transaction(
      id: 'TXN-2024-089450',
      station: 'Petron - Quezon City',
      fuelType: 'Premium 95 RON',
      volume: 50.0,
      price: 2500.00,
      date: DateTime.now().subtract(Duration(days: 2)),
      status: 'Pending',
    ),
    Transaction(
      id: 'TXN-2024-089449',
      station: 'Shell - Makati Avenue',
      fuelType: 'Regular 91 RON',
      volume: 40.0,
      price: 1800.00,
      date: DateTime.now().subtract(Duration(days: 3)),
      status: 'Completed',
    ),
    Transaction(
      id: 'TXN-2024-089448',
      station: 'Chevron - Pasig',
      fuelType: 'Premium 95 RON',
      volume: 55.0,
      price: 2750.00,
      date: DateTime.now().subtract(Duration(days: 4)),
      status: 'Pending',
    ),
    Transaction(
      id: 'TXN-2024-089447',
      station: 'Caltex - BGC',
      fuelType: 'Diesel',
      volume: 70.0,
      price: 2800.00,
      date: DateTime.now().subtract(Duration(days: 5)),
      status: 'Completed',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Transaction> _getFilteredTransactions() {
    List<Transaction> filtered = _allTransactions;

    if (_selectedFilter != 'All') {
      filtered = filtered.where((t) => t.status == _selectedFilter).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (t) =>
                t.station.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                t.id.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    return filtered;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTransactions = _getFilteredTransactions();

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      bottomNavigationBar: const AppBottomNavigationBar(currentIndex: 1),
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Transaction History', style: AppTextStyles.sectionHeading),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
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
                  hintText: 'Search by station or ID',
                  hintStyle: AppTextStyles.body.copyWith(
                    color: AppColors.tertiaryText,
                  ),
                  border: InputBorder.none,
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.secondaryText,
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Completed', 'Pending'].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: EdgeInsets.only(right: AppSpacing.sm),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      backgroundColor: AppColors.white,
                      selectedColor: AppColors.accentTeal,
                      labelStyle: AppTextStyles.body.copyWith(
                        color: isSelected
                            ? AppColors.white
                            : AppColors.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppBorderRadius.pill,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.accentTeal
                              : AppColors.softGray,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Expanded(
            child: filteredTransactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 64,
                          color: AppColors.softGray,
                        ),
                        SizedBox(height: AppSpacing.md),
                        Text(
                          'No transactions found',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = filteredTransactions[index];
                      return _buildTransactionCard(transaction);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    final isCompleted = transaction.status == 'Completed';

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: GestureDetector(
        onTap: () {},
        child: Container(
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.station,
                          style: AppTextStyles.cardTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: AppSpacing.xs),
                        Text(
                          transaction.fuelType,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.secondaryText,
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
                      color: isCompleted
                          ? AppColors.successLight
                          : AppColors.warningLight,
                      borderRadius: BorderRadius.circular(AppBorderRadius.pill),
                    ),
                    child: Text(
                      transaction.status,
                      style: AppTextStyles.caption.copyWith(
                        color: isCompleted
                            ? AppColors.success
                            : AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Volume',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        '${transaction.volume.toStringAsFixed(1)} L',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Amount',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        'â‚±${transaction.price.toStringAsFixed(2)}',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentTeal,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Date',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        _formatDate(transaction.date),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primaryText,
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
  }
}
