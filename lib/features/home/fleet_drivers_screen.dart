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

class FleetDriversScreen extends StatefulWidget {
  const FleetDriversScreen({super.key});

  @override
  State<FleetDriversScreen> createState() => _FleetDriversScreenState();
}

class _FleetDriversScreenState extends State<FleetDriversScreen> {
  late final FleetRepository _fleetRepository;

  bool _initialized = false;
  String? _targetVehicleId;
  bool _isLoading = true;
  String? _errorMessage;
  List<Driver> _drivers = const [];

  @override
  void initState() {
    super.initState();
    final tokenManager = TokenManager();
    final apiClient = ApiClient(tokenManager: tokenManager);
    _fleetRepository = FleetRepository(apiClient: apiClient);
    _loadDrivers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic> && args['vehicleId'] is String) {
      _targetVehicleId = args['vehicleId'] as String;
    }
  }

  Future<void> _loadDrivers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final drivers = await _fleetRepository.getDrivers();
      if (!mounted) return;
      setState(() {
        _drivers = drivers;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      var message = 'Unable to load drivers.';
      if (e is AppError && e.detail != null && e.detail!.trim().isNotEmpty) {
        message = e.detail!;
      }
      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    }
  }

  Future<void> _openAddDriverSheet() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final licenseController = TextEditingController();
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
                  Text('Add Driver', style: AppTextStyles.sectionHeading),
                  SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: licenseController,
                    decoration: const InputDecoration(
                      labelText: 'License Number',
                    ),
                  ),
                  SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: submitting
                          ? null
                          : () async {
                              final name = nameController.text.trim();
                              final phone = phoneController.text.trim();
                              final license = licenseController.text.trim();

                              if (name.isEmpty ||
                                  phone.isEmpty ||
                                  license.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please fill all fields'),
                                  ),
                                );
                                return;
                              }

                              setModalState(() {
                                submitting = true;
                              });

                              try {
                                await _fleetRepository.addDriver(
                                  fullName: name,
                                  phone: phone,
                                  licenseNumber: license,
                                );
                                if (!context.mounted) return;
                                Navigator.pop(context);
                                _loadDrivers();
                              } catch (_) {
                                if (!context.mounted) return;
                                setModalState(() {
                                  submitting = false;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Unable to add driver right now',
                                    ),
                                  ),
                                );
                              }
                            },
                      child: Text(submitting ? 'Saving...' : 'Add Driver'),
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

  Future<void> _assignDriver(Driver driver) async {
    final vehicleId = _targetVehicleId;
    if (vehicleId == null || vehicleId.isEmpty) return;

    try {
      await _fleetRepository.assignDriver(
        vehicleId: vehicleId,
        driverUid: driver.uid ?? driver.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Driver assigned successfully')),
      );
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to assign driver right now')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          _targetVehicleId == null ? 'Drivers' : 'Select Driver',
          style: AppTextStyles.sectionHeading,
        ),
      ),
      floatingActionButton: _targetVehicleId == null
          ? FloatingActionButton(
              onPressed: _openAddDriverSheet,
              backgroundColor: AppColors.accentTeal,
              child: const Icon(Icons.add),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!, style: AppTextStyles.body))
          : _drivers.isEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Text('No drivers added yet.', style: AppTextStyles.body),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(AppSpacing.md),
              itemCount: _drivers.length,
              itemBuilder: (context, index) {
                final d = _drivers[index];
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
                          children: [
                            Expanded(
                              child: Text(
                                d.fullName,
                                style: AppTextStyles.cardTitle,
                              ),
                            ),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: d.isActive
                                    ? AppColors.success
                                    : AppColors.softGray,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppSpacing.xs),
                        Text('Phone: ${d.phone}', style: AppTextStyles.body),
                        SizedBox(height: AppSpacing.xs),
                        Text(
                          'License: ${d.licenseNumber}',
                          style: AppTextStyles.caption,
                        ),
                        SizedBox(height: AppSpacing.xs),
                        Text(
                          d.assignedVehicleId != null
                              ? 'Assigned vehicle: ${d.assignedVehicleId}'
                              : 'Unassigned',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                        if (_targetVehicleId != null) ...[
                          SizedBox(height: AppSpacing.sm),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: d.isActive
                                  ? () => _assignDriver(d)
                                  : null,
                              child: const Text('Assign To Vehicle'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
