import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/text_styles.dart';
import '../../core/models/error_models.dart';
import '../../core/models/fleet_models.dart';
import '../../core/repositories/fleet_repository.dart';
import '../../core/services/api_client.dart';
import '../../core/services/token_manager.dart';

class FleetVehicleDetailScreen extends StatefulWidget {
  const FleetVehicleDetailScreen({super.key});

  @override
  State<FleetVehicleDetailScreen> createState() =>
      _FleetVehicleDetailScreenState();
}

class _FleetVehicleDetailScreenState extends State<FleetVehicleDetailScreen>
    with SingleTickerProviderStateMixin {
  late final FleetRepository _fleetRepository;
  late final TabController _tabController;

  bool _initialized = false;
  bool _isLoading = true;
  String? _errorMessage;
  String? _vehicleId;

  Vehicle? _vehicle;
  VehicleConsumption? _consumption;
  ExpenseListResponse? _expenses;
  Budget? _budget;

  @override
  void initState() {
    super.initState();
    final tokenManager = TokenManager();
    final apiClient = ApiClient(tokenManager: tokenManager);
    _fleetRepository = FleetRepository(apiClient: apiClient);
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic> && args['vehicleId'] is String) {
      _vehicleId = args['vehicleId'] as String;
      _loadData();
    } else {
      setState(() {
        _errorMessage = 'Vehicle details unavailable.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadData() async {
    final vehicleId = _vehicleId;
    if (vehicleId == null || vehicleId.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final now = DateTime.now();

    try {
      final results = await Future.wait<dynamic>([
        _fleetRepository.getVehicle(vehicleId),
        _fleetRepository.getVehicleConsumption(vehicleId),
        _fleetRepository.getExpenses(
          vehicleId: vehicleId,
          month: now.month,
          year: now.year,
        ),
        _fleetRepository.getBudget(
          vehicleId: vehicleId,
          month: now.month,
          year: now.year,
        ),
      ]);

      if (!mounted) return;

      setState(() {
        _vehicle = results[0] as Vehicle;
        _consumption = results[1] as VehicleConsumption;
        _expenses = results[2] as ExpenseListResponse;
        _budget = results[3] as Budget;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      var message = 'Unable to load vehicle data.';
      if (e is AppError && e.detail != null && e.detail!.trim().isNotEmpty) {
        message = e.detail!;
      }

      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openLogExpenseSheet() async {
    final vehicle = _vehicle;
    if (vehicle == null) return;

    ExpenseCategory category = ExpenseCategory.fuel;
    final amountController = TextEditingController();
    final litresController = TextEditingController();
    final descriptionController = TextEditingController();
    bool submitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppBorderRadius.card),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Log Expense', style: AppTextStyles.sectionHeading),
                    SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<ExpenseCategory>(
                      initialValue: category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: ExpenseCategory.values
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(e.name.toUpperCase()),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() {
                          category = value;
                        });
                      },
                    ),
                    SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Amount (PKR)',
                      ),
                    ),
                    if (category == ExpenseCategory.fuel) ...[
                      SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: litresController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: 'Litres'),
                      ),
                    ],
                    SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: descriptionController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                      ),
                    ),
                    SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: submitting
                            ? null
                            : () async {
                                final amount = double.tryParse(
                                  amountController.text.trim(),
                                );
                                final litres =
                                    litresController.text.trim().isEmpty
                                    ? null
                                    : double.tryParse(
                                        litresController.text.trim(),
                                      );

                                if (amount == null || amount <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Enter a valid amount'),
                                    ),
                                  );
                                  return;
                                }

                                if (category == ExpenseCategory.fuel &&
                                    (litres == null || litres <= 0)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Enter valid litres for fuel expense',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                setModalState(() {
                                  submitting = true;
                                });

                                try {
                                  await _fleetRepository.logExpense(
                                    vehicleId: vehicle.id,
                                    category: category,
                                    amount: amount,
                                    litres: litres,
                                    description:
                                        descriptionController.text
                                            .trim()
                                            .isEmpty
                                        ? null
                                        : descriptionController.text.trim(),
                                  );
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  _loadData();
                                } catch (_) {
                                  if (!context.mounted) return;
                                  setModalState(() {
                                    submitting = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Unable to log expense right now',
                                      ),
                                    ),
                                  );
                                }
                              },
                        child: Text(submitting ? 'Saving...' : 'Save Expense'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openSetBudgetSheet() async {
    final vehicle = _vehicle;
    if (vehicle == null) return;

    final amountController = TextEditingController(
      text: _budget?.budgetAmount.toStringAsFixed(0) ?? '',
    );
    bool submitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppBorderRadius.card),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Set Budget', style: AppTextStyles.sectionHeading),
                  SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Budget Amount (PKR)',
                    ),
                  ),
                  SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: submitting
                          ? null
                          : () async {
                              final amount = double.tryParse(
                                amountController.text.trim(),
                              );
                              if (amount == null || amount <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Enter a valid budget amount',
                                    ),
                                  ),
                                );
                                return;
                              }

                              setModalState(() {
                                submitting = true;
                              });

                              try {
                                final now = DateTime.now();
                                await _fleetRepository.setBudget(
                                  vehicleId: vehicle.id,
                                  month: now.month,
                                  year: now.year,
                                  amount: amount,
                                );
                                if (!context.mounted) return;
                                Navigator.pop(context);
                                _loadData();
                              } catch (_) {
                                if (!context.mounted) return;
                                setModalState(() {
                                  submitting = false;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Unable to set budget right now',
                                    ),
                                  ),
                                );
                              }
                            },
                      child: Text(submitting ? 'Saving...' : 'Save Budget'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openAssignDriver() async {
    final vehicleId = _vehicle?.id;
    if (vehicleId == null || vehicleId.isEmpty) return;

    final assigned = await Navigator.of(
      context,
    ).pushNamed('/fleet-drivers', arguments: {'vehicleId': vehicleId});

    if (assigned == true) {
      _loadData();
    }
  }

  String _monthLabel(String key) {
    final parts = key.split('-');
    if (parts.length != 2) return key;
    final month = int.tryParse(parts[1]) ?? 1;
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${names[month - 1]} ${parts[0]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text('Vehicle Detail', style: AppTextStyles.sectionHeading),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Expenses'),
            Tab(text: 'Budget'),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
              onPressed: _openLogExpenseSheet,
              backgroundColor: AppColors.accentTeal,
              child: const Icon(Icons.add),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!, style: AppTextStyles.body))
          : TabBarView(
              controller: _tabController,
              children: [_overviewTab(), _expensesTab(), _budgetTab()],
            ),
    );
  }

  Widget _overviewTab() {
    final vehicle = _vehicle!;
    final consumption = _consumption;

    return ListView(
      padding: EdgeInsets.all(AppSpacing.md),
      children: [
        Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppBorderRadius.card),
            boxShadow: AppShadows.subtleList,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vehicle.registrationNumber,
                style: AppTextStyles.sectionHeading,
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                '${vehicle.make} ${vehicle.model} ${vehicle.year}',
                style: AppTextStyles.body,
              ),
              SizedBox(height: AppSpacing.md),
              _infoRow('Fuel Type', vehicle.fuelType.toUpperCase()),
              _infoRow(
                'Tank Capacity',
                '${vehicle.tankCapacity.toStringAsFixed(1)} L',
              ),
              _infoRow(
                'Driver',
                vehicle.assignedDriverUid ?? 'No driver assigned',
              ),
              _infoRow(
                'Total Fuel Consumed',
                '${vehicle.totalFuelConsumed.toStringAsFixed(1)} L',
              ),
              _infoRow(
                'Total Expense',
                'PKR ${vehicle.totalExpense.toStringAsFixed(0)}',
              ),
              SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _openAssignDriver,
                  child: const Text('Assign Driver'),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.md),
        if (consumption != null)
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppBorderRadius.card),
              boxShadow: AppShadows.subtleList,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Monthly Breakdown', style: AppTextStyles.cardTitle),
                SizedBox(height: AppSpacing.sm),
                ...consumption.monthlyBreakdown.entries.map(
                  (entry) => Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_monthLabel(entry.key), style: AppTextStyles.body),
                        Text(
                          '${entry.value.litres.toStringAsFixed(1)} L • PKR ${entry.value.amount.toStringAsFixed(0)}',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _expensesTab() {
    final expenses = _expenses?.items ?? const <Expense>[];

    if (expenses.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Text(
            'No expenses logged for this month.',
            style: AppTextStyles.body,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(AppSpacing.md),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final e = expenses[index];
        return Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
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
                    Text(
                      e.category.name.toUpperCase(),
                      style: AppTextStyles.cardTitle,
                    ),
                    Text(
                      'PKR ${e.amount.toStringAsFixed(0)}',
                      style: AppTextStyles.cardTitle.copyWith(
                        color: AppColors.accentTeal,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.xs),
                if (e.litres != null)
                  Text(
                    '${e.litres!.toStringAsFixed(1)} L',
                    style: AppTextStyles.caption,
                  ),
                if (e.description != null && e.description!.trim().isNotEmpty)
                  Text(e.description!, style: AppTextStyles.body),
                SizedBox(height: AppSpacing.xs),
                Text(e.expenseDate, style: AppTextStyles.caption),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _budgetTab() {
    final b = _budget;

    if (b == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('No budget set for this period', style: AppTextStyles.body),
            SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: _openSetBudgetSheet,
              child: const Text('Set Budget'),
            ),
          ],
        ),
      );
    }

    final pct = (b.budgetAmount <= 0)
        ? 0.0
        : (b.spentAmount / b.budgetAmount).clamp(0.0, 1.0);

    return ListView(
      padding: EdgeInsets.all(AppSpacing.md),
      children: [
        Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppBorderRadius.card),
            boxShadow: AppShadows.subtleList,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Budget Overview', style: AppTextStyles.cardTitle),
              SizedBox(height: AppSpacing.md),
              _infoRow('Budget', 'PKR ${b.budgetAmount.toStringAsFixed(0)}'),
              _infoRow('Spent', 'PKR ${b.spentAmount.toStringAsFixed(0)}'),
              _infoRow('Remaining', 'PKR ${b.remaining.toStringAsFixed(0)}'),
              SizedBox(height: AppSpacing.md),
              LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: AppColors.lightGray,
                valueColor: AlwaysStoppedAnimation<Color>(
                  b.remaining < 0 ? AppColors.alert : AppColors.success,
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              if (b.remaining < 0)
                Text(
                  'Over budget by PKR ${(-b.remaining).toStringAsFixed(0)}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.alert),
                ),
              SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _openSetBudgetSheet,
                  child: const Text('Set Budget'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.caption),
          Text(
            value,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
