import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/text_styles.dart';
import '../../core/models/error_models.dart';
import '../../core/models/fleet_models.dart';
import '../../core/repositories/fleet_repository.dart';
import '../../core/state/app_providers.dart';

class FleetVehiclesScreen extends ConsumerStatefulWidget {
  const FleetVehiclesScreen({super.key});

  @override
  ConsumerState<FleetVehiclesScreen> createState() =>
      _FleetVehiclesScreenState();
}

class _FleetVehiclesScreenState extends ConsumerState<FleetVehiclesScreen> {
  late final FleetRepository _fleetRepository;

  bool _isLoading = true;
  String? _errorMessage;
  List<Vehicle> _vehicles = const [];

  @override
  void initState() {
    super.initState();
    _fleetRepository = ref.read(fleetRepositoryProvider);
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final vehicles = await _fleetRepository.getVehicles();
      if (!mounted) return;
      setState(() {
        _vehicles = vehicles;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      var message = 'Unable to load vehicles.';
      if (e is AppError && e.detail != null && e.detail!.trim().isNotEmpty) {
        message = e.detail!;
      }
      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    }
  }

  Future<void> _openAddVehicleSheet() async {
    final regController = TextEditingController();
    final makeController = TextEditingController();
    final modelController = TextEditingController();
    final yearController = TextEditingController();
    final tankController = TextEditingController();
    String fuelType = 'petrol';
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
                    Text('Add Vehicle', style: AppTextStyles.sectionHeading),
                    SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: regController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Registration Number',
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: makeController,
                      decoration: const InputDecoration(labelText: 'Make'),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: modelController,
                      decoration: const InputDecoration(labelText: 'Model'),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: yearController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Year'),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String>(
                      initialValue: fuelType,
                      decoration: const InputDecoration(labelText: 'Fuel Type'),
                      items: const [
                        DropdownMenuItem(
                          value: 'petrol',
                          child: Text('Petrol'),
                        ),
                        DropdownMenuItem(
                          value: 'diesel',
                          child: Text('Diesel'),
                        ),
                        DropdownMenuItem(
                          value: 'premium',
                          child: Text('Premium'),
                        ),
                        DropdownMenuItem(value: 'cng', child: Text('CNG')),
                        DropdownMenuItem(value: 'lpg', child: Text('LPG')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() {
                          fuelType = value;
                        });
                      },
                    ),
                    SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: tankController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Tank Capacity (L)',
                      ),
                    ),
                    SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: submitting
                            ? null
                            : () async {
                                final reg = regController.text.trim();
                                final make = makeController.text.trim();
                                final model = modelController.text.trim();
                                final year = int.tryParse(
                                  yearController.text.trim(),
                                );
                                final tank = double.tryParse(
                                  tankController.text.trim(),
                                );

                                if (reg.isEmpty ||
                                    make.isEmpty ||
                                    model.isEmpty ||
                                    year == null ||
                                    tank == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please fill all fields correctly',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                setModalState(() {
                                  submitting = true;
                                });

                                try {
                                  await _fleetRepository.addVehicle(
                                    registrationNumber: reg,
                                    make: make,
                                    model: model,
                                    year: year,
                                    fuelType: fuelType,
                                    tankCapacity: tank,
                                  );
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  _loadVehicles();
                                } catch (_) {
                                  if (!context.mounted) return;
                                  setModalState(() {
                                    submitting = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Unable to add vehicle right now',
                                      ),
                                    ),
                                  );
                                }
                              },
                        child: Text(submitting ? 'Saving...' : 'Add Vehicle'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.primaryText),
        ),
        title: Text('My Vehicles', style: AppTextStyles.sectionHeading),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed('/fleet-drivers'),
            icon: const Icon(Icons.badge_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddVehicleSheet,
        backgroundColor: AppColors.accentTeal,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!, style: AppTextStyles.body))
          : _vehicles.isEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'No vehicles added yet. Add your first vehicle to start tracking fuel expenses.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body,
                ),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(AppSpacing.md),
              itemCount: _vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = _vehicles[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.md),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppBorderRadius.card),
                    onTap: () => Navigator.of(context).pushNamed(
                      '/fleet-vehicle-detail',
                      arguments: {'vehicleId': vehicle.id},
                    ),
                    child: Container(
                      padding: EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(
                          AppBorderRadius.card,
                        ),
                        boxShadow: AppShadows.subtleList,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  vehicle.registrationNumber,
                                  style: AppTextStyles.sectionHeading,
                                ),
                              ),
                              if (!vehicle.isActive)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: AppSpacing.xs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.softGray,
                                    borderRadius: BorderRadius.circular(
                                      AppBorderRadius.pill,
                                    ),
                                  ),
                                  child: Text(
                                    'Inactive',
                                    style: AppTextStyles.caption,
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            '${vehicle.make} ${vehicle.model} ${vehicle.year}',
                            style: AppTextStyles.body,
                          ),
                          SizedBox(height: AppSpacing.sm),
                          Text(
                            '${vehicle.totalFuelConsumed.toStringAsFixed(1)} L consumed total',
                            style: AppTextStyles.caption,
                          ),
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            'PKR ${vehicle.totalExpense.toStringAsFixed(0)} total spent',
                            style: AppTextStyles.cardTitle.copyWith(
                              color: AppColors.accentTeal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
