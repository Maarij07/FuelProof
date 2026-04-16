import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/text_styles.dart';
import '../../core/models/error_models.dart';
import '../../core/models/station_models.dart';
import '../../core/repositories/price_repository.dart';
import '../../core/services/api_client.dart';
import '../../core/services/token_manager.dart';

class PriceCompareScreen extends StatefulWidget {
  const PriceCompareScreen({super.key});

  @override
  State<PriceCompareScreen> createState() => _PriceCompareScreenState();
}

class _PriceCompareScreenState extends State<PriceCompareScreen> {
  static const double _defaultLat = 31.5204;
  static const double _defaultLng = 74.3587;

  late final PriceRepository _priceRepository;

  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFuelType = 'petrol';
  List<PriceComparison> _prices = const [];

  @override
  void initState() {
    super.initState();
    final tokenManager = TokenManager();
    final apiClient = ApiClient(tokenManager: tokenManager);
    _priceRepository = PriceRepository(apiClient: apiClient);
    _loadPrices();
  }

  Future<void> _loadPrices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prices = await _priceRepository.comparePrices(
        fuelType: _selectedFuelType,
        latitude: _defaultLat,
        longitude: _defaultLng,
      );

      if (!mounted) return;
      setState(() {
        _prices = prices;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      var message = 'Unable to load price comparison.';
      if (e is AppError && e.detail != null && e.detail!.trim().isNotEmpty) {
        message = e.detail!;
      }
      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    }
  }

  String _fuelTypeLabel(String fuelType) {
    switch (fuelType) {
      case 'petrol':
        return 'Petrol';
      case 'diesel':
        return 'Diesel';
      case 'premium':
        return 'Premium';
      case 'cng':
        return 'CNG';
      case 'lpg':
        return 'LPG';
      default:
        return fuelType;
    }
  }

  String _formatRelative(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return 'Updated recently';
    try {
      final date = DateTime.parse(isoDate).toLocal();
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes}m ago';
      if (diff.inHours < 24) return 'Updated ${diff.inHours}h ago';
      return 'Updated ${date.day}/${date.month}';
    } catch (_) {
      return 'Updated recently';
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
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.primaryText),
        ),
        title: Text('Price Compare', style: AppTextStyles.sectionHeading),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed('/cheapest-fuel'),
            icon: const Icon(Icons.local_offer_rounded),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed('/price-alerts'),
            icon: const Icon(Icons.notifications_active_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFuelTypeTabs(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? _buildMessageCard(_errorMessage!)
                : _prices.isEmpty
                ? _buildMessageCard('No stations found for selected fuel type.')
                : ListView.builder(
                    padding: EdgeInsets.all(AppSpacing.md),
                    itemCount: _prices.length,
                    itemBuilder: (context, index) {
                      final item = _prices[index];
                      final isCheapest = index == 0;
                      return Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.md),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(
                            AppBorderRadius.card,
                          ),
                          onTap: () => Navigator.of(context).pushNamed(
                            '/station-detail',
                            arguments: {'stationId': item.stationId},
                          ),
                          child: Container(
                            padding: EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(
                                AppBorderRadius.card,
                              ),
                              boxShadow: AppShadows.subtleList,
                              border: isCheapest
                                  ? Border.all(
                                      color: AppColors.success,
                                      width: 1.2,
                                    )
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.stationName,
                                        style: AppTextStyles.cardTitle,
                                      ),
                                    ),
                                    if (isCheapest)
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: AppSpacing.sm,
                                          vertical: AppSpacing.xs,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.successLight,
                                          borderRadius: BorderRadius.circular(
                                            AppBorderRadius.pill,
                                          ),
                                        ),
                                        child: Text(
                                          'Cheapest',
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.success,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(height: AppSpacing.xs),
                                Text(
                                  'PKR ${item.pricePerLitre.toStringAsFixed(2)} / L',
                                  style: AppTextStyles.sectionHeading.copyWith(
                                    color: AppColors.accentTeal,
                                  ),
                                ),
                                SizedBox(height: AppSpacing.xs),
                                Row(
                                  children: [
                                    Text(
                                      item.distanceKm != null
                                          ? '${item.distanceKm!.toStringAsFixed(1)} km'
                                          : 'Distance N/A',
                                      style: AppTextStyles.caption,
                                    ),
                                    SizedBox(width: AppSpacing.md),
                                    Text(
                                      _formatRelative(item.lastUpdated),
                                      style: AppTextStyles.caption,
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
        ],
      ),
    );
  }

  Widget _buildFuelTypeTabs() {
    const fuelTypes = ['petrol', 'diesel', 'premium', 'cng', 'lpg'];
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.all(AppSpacing.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: fuelTypes.map((type) {
            final selected = _selectedFuelType == type;
            return Padding(
              padding: EdgeInsets.only(right: AppSpacing.sm),
              child: ChoiceChip(
                label: Text(_fuelTypeLabel(type)),
                selected: selected,
                onSelected: (_) {
                  setState(() {
                    _selectedFuelType = type;
                  });
                  _loadPrices();
                },
                selectedColor: AppColors.accentTeal,
                backgroundColor: AppColors.lightGray,
                labelStyle: AppTextStyles.caption.copyWith(
                  color: selected ? AppColors.white : AppColors.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMessageCard(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Text(
          message,
          style: AppTextStyles.body,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
