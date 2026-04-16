import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/text_styles.dart';
import '../../core/models/error_models.dart';
import '../../core/models/station_models.dart';
import '../../core/repositories/price_repository.dart';
import '../../core/repositories/station_repository.dart';
import '../../core/state/app_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class CheapestFuelScreen extends ConsumerStatefulWidget {
  const CheapestFuelScreen({super.key});

  @override
  ConsumerState<CheapestFuelScreen> createState() => _CheapestFuelScreenState();
}

class _CheapestFuelScreenState extends ConsumerState<CheapestFuelScreen> {
  static const double _defaultLat = 31.5204;
  static const double _defaultLng = 74.3587;

  late final PriceRepository _priceRepository;
  late final StationRepository _stationRepository;

  bool _isLoading = true;
  bool _isOpeningDirections = false;
  String? _errorMessage;
  CheapestFuel? _result;
  String _fuelType = 'petrol';
  double _radiusKm = 20;

  @override
  void initState() {
    super.initState();
    _priceRepository = ref.read(priceRepositoryProvider);
    _stationRepository = ref.read(stationRepositoryProvider);
    _loadCheapest();
  }

  Future<void> _openDirections(CheapestFuel fuel) async {
    if (_isOpeningDirections) return;

    setState(() {
      _isOpeningDirections = true;
    });

    try {
      final station = await _stationRepository.getStation(fuel.stationId);
      final lat = station.latitude;
      final lng = station.longitude;
      final mapsUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      );

      final launched = await launchUrl(
        mapsUrl,
        mode: LaunchMode.platformDefault,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open maps app.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      var message = 'Unable to open directions right now.';
      if (e is AppError && e.detail != null && e.detail!.trim().isNotEmpty) {
        message = e.detail!;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningDirections = false;
        });
      }
    }
  }

  Future<void> _loadCheapest() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _priceRepository.getCheapestFuel(
        fuelType: _fuelType,
        latitude: _defaultLat,
        longitude: _defaultLng,
        radiusKm: _radiusKm.toInt(),
      );

      if (!mounted) return;
      setState(() {
        _result = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      var message = 'Unable to find cheapest fuel right now.';
      if (e is AppError) {
        if (e.statusCode == 404) {
          message =
              'No stations found within ${_radiusKm.toStringAsFixed(0)} km for this fuel type.';
        } else if (e.detail != null && e.detail!.trim().isNotEmpty) {
          message = e.detail!;
        }
      }
      setState(() {
        _errorMessage = message;
        _result = null;
        _isLoading = false;
      });
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
          'Cheapest Fuel Finder',
          style: AppTextStyles.sectionHeading,
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.md),
        children: [
          _controls(),
          SizedBox(height: AppSpacing.md),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage != null)
            _messageCard(_errorMessage!)
          else if (_result != null)
            _resultCard(_result!),
        ],
      ),
    );
  }

  Widget _controls() {
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
          Text('Fuel Type', style: AppTextStyles.cardTitle),
          SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: ['petrol', 'diesel', 'premium', 'cng', 'lpg'].map((type) {
              final selected = type == _fuelType;
              return ChoiceChip(
                label: Text(type.toUpperCase()),
                selected: selected,
                selectedColor: AppColors.accentTeal,
                onSelected: (_) {
                  setState(() {
                    _fuelType = type;
                  });
                  _loadCheapest();
                },
                labelStyle: AppTextStyles.caption.copyWith(
                  color: selected ? AppColors.white : AppColors.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'Radius: ${_radiusKm.toStringAsFixed(0)} km',
            style: AppTextStyles.body,
          ),
          Slider(
            value: _radiusKm,
            min: 5,
            max: 50,
            divisions: 9,
            onChanged: (value) {
              setState(() {
                _radiusKm = value;
              });
            },
            onChangeEnd: (_) => _loadCheapest(),
          ),
        ],
      ),
    );
  }

  Widget _resultCard(CheapestFuel fuel) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        boxShadow: AppShadows.subtleList,
        border: Border.all(color: AppColors.success, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Best Match',
            style: AppTextStyles.caption.copyWith(color: AppColors.success),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            fuel.stationName,
            style: AppTextStyles.sectionHeading.copyWith(fontSize: 24),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'PKR ${fuel.pricePerLitre.toStringAsFixed(2)} / L',
            style: AppTextStyles.displayHero.copyWith(
              fontSize: 34,
              color: AppColors.success,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            '${fuel.distanceKm.toStringAsFixed(1)} km away',
            style: AppTextStyles.body,
          ),
          SizedBox(height: AppSpacing.xs),
          Text(fuel.address, style: AppTextStyles.caption),
          SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isOpeningDirections
                  ? null
                  : () => _openDirections(fuel),
              icon: _isOpeningDirections
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.white,
                        ),
                      ),
                    )
                  : const Icon(Icons.navigation_rounded),
              label: Text(
                _isOpeningDirections ? 'Opening...' : 'Get Directions',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageCard(String message) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        boxShadow: AppShadows.subtleList,
      ),
      child: Text(
        message,
        style: AppTextStyles.body,
        textAlign: TextAlign.center,
      ),
    );
  }
}
