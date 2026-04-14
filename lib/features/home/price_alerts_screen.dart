import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/text_styles.dart';
import '../../core/models/error_models.dart';
import '../../core/models/station_models.dart';
import '../../core/repositories/price_repository.dart';
import '../../core/repositories/station_repository.dart';
import '../../core/services/api_client.dart';
import '../../core/services/token_manager.dart';

class PriceAlertsScreen extends StatefulWidget {
  const PriceAlertsScreen({super.key});

  @override
  State<PriceAlertsScreen> createState() => _PriceAlertsScreenState();
}

class _PriceAlertsScreenState extends State<PriceAlertsScreen> {
  static const double _defaultLat = 31.5204;
  static const double _defaultLng = 74.3587;

  late final PriceRepository _priceRepository;
  late final StationRepository _stationRepository;

  bool _isLoading = true;
  String? _errorMessage;
  List<PriceAlert> _alerts = const [];
  List<Station> _stations = const [];

  @override
  void initState() {
    super.initState();
    final tokenManager = TokenManager();
    final apiClient = ApiClient(tokenManager: tokenManager);
    _priceRepository = PriceRepository(apiClient: apiClient);
    _stationRepository = StationRepository(apiClient: apiClient);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final alerts = await _priceRepository.getPriceAlerts();
      final stations = await _stationRepository.getNearbyStations(
        latitude: _defaultLat,
        longitude: _defaultLng,
        radiusKm: 30,
      );

      if (!mounted) return;
      setState(() {
        _alerts = alerts;
        _stations = stations;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      var message = 'Unable to load price alerts.';
      if (e is AppError && e.detail != null && e.detail!.trim().isNotEmpty) {
        message = e.detail!;
      }
      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAlert(String alertId) async {
    final backup = _alerts;
    setState(() {
      _alerts = _alerts.where((a) => a.id != alertId).toList();
    });

    try {
      await _priceRepository.deletePriceAlert(alertId);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _alerts = backup;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to delete alert right now')),
      );
    }
  }

  Future<void> _setAlertActive(PriceAlert alert, bool isActive) async {
    final previous = _alerts;
    final updatedAlert = PriceAlert(
      id: alert.id,
      userId: alert.userId,
      stationId: alert.stationId,
      fuelType: alert.fuelType,
      targetPrice: alert.targetPrice,
      isActive: isActive,
      createdAt: alert.createdAt,
    );

    setState(() {
      _alerts = _alerts
          .map((item) => item.id == alert.id ? updatedAlert : item)
          .toList();
    });

    try {
      await _priceRepository.setPriceAlertActive(
        alertId: alert.id,
        isActive: isActive,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _alerts = previous;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update alert right now')),
      );
    }
  }

  String _stationName(String stationId) {
    final station = _stations
        .where((s) => s.id == stationId)
        .cast<Station?>()
        .firstWhere((s) => s != null, orElse: () => null);
    return station?.name ??
        'Station ${stationId.substring(0, stationId.length > 8 ? 8 : stationId.length)}';
  }

  Future<void> _openCreateAlertSheet() async {
    if (_stations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No stations available for alert setup')),
      );
      return;
    }

    String selectedStationId = _stations.first.id;
    String selectedFuelType = 'petrol';
    final targetController = TextEditingController();
    bool isSubmitting = false;

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
                  Text('Set Price Alert', style: AppTextStyles.sectionHeading),
                  SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: selectedStationId,
                    decoration: const InputDecoration(labelText: 'Station'),
                    items: _stations
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(
                              s.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setModalState(() {
                        selectedStationId = value;
                      });
                    },
                  ),
                  SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: selectedFuelType,
                    decoration: const InputDecoration(labelText: 'Fuel Type'),
                    items: const [
                      DropdownMenuItem(value: 'petrol', child: Text('Petrol')),
                      DropdownMenuItem(value: 'diesel', child: Text('Diesel')),
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
                        selectedFuelType = value;
                      });
                    },
                  ),
                  SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: targetController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Target Price (PKR)',
                      hintText: '270.00',
                    ),
                  ),
                  SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final navigator = Navigator.of(context);
                              final target = double.tryParse(
                                targetController.text.trim(),
                              );
                              if (target == null || target <= 0) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Enter a valid target price'),
                                  ),
                                );
                                return;
                              }

                              setModalState(() {
                                isSubmitting = true;
                              });

                              try {
                                await _priceRepository.createPriceAlert(
                                  stationId: selectedStationId,
                                  fuelType: selectedFuelType,
                                  targetPrice: target,
                                );
                                if (!context.mounted) return;
                                navigator.pop();
                                _loadData();
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Price alert set'),
                                  ),
                                );
                              } catch (_) {
                                if (!context.mounted) return;
                                setModalState(() {
                                  isSubmitting = false;
                                });
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Unable to create alert right now',
                                    ),
                                  ),
                                );
                              }
                            },
                      child: Text(isSubmitting ? 'Saving...' : 'Create Alert'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('Price Alerts', style: AppTextStyles.sectionHeading),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateAlertSheet,
        backgroundColor: AppColors.accentTeal,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!, style: AppTextStyles.body))
          : _alerts.isEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  "No price alerts set. We'll notify you when fuel drops to your target price.",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body,
                ),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(AppSpacing.md),
              itemCount: _alerts.length,
              itemBuilder: (context, index) {
                final alert = _alerts[index];
                return Dismissible(
                  key: ValueKey(alert.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.alert,
                      borderRadius: BorderRadius.circular(AppBorderRadius.card),
                    ),
                    child: Icon(Icons.delete_rounded, color: AppColors.white),
                  ),
                  onDismissed: (_) => _deleteAlert(alert.id),
                  child: Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
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
                          Text(
                            _stationName(alert.stationId),
                            style: AppTextStyles.cardTitle,
                          ),
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            'Alert when ${alert.fuelType.toUpperCase()} ≤ PKR ${alert.targetPrice.toStringAsFixed(2)}',
                            style: AppTextStyles.body,
                          ),
                          SizedBox(height: AppSpacing.xs),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                alert.isActive ? 'Active' : 'Paused',
                                style: AppTextStyles.caption.copyWith(
                                  color: alert.isActive
                                      ? AppColors.success
                                      : AppColors.secondaryText,
                                ),
                              ),
                              Switch.adaptive(
                                value: alert.isActive,
                                activeThumbColor: AppColors.accentTeal,
                                onChanged: (value) =>
                                    _setAlertActive(alert, value),
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
    );
  }
}
