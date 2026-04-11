import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/text_styles.dart';
import '../../core/models/error_models.dart';
import '../../core/models/station_models.dart';
import '../../core/repositories/station_repository.dart';
import '../../core/services/api_client.dart';
import '../../core/services/token_manager.dart';

class RouteStationsScreen extends StatefulWidget {
  const RouteStationsScreen({super.key});

  @override
  State<RouteStationsScreen> createState() => _RouteStationsScreenState();
}

class _RouteStationsScreenState extends State<RouteStationsScreen> {
  static const double _defaultOriginLat = 31.5204;
  static const double _defaultOriginLng = 74.3587;
  static const double _defaultDestLat = 31.4504;
  static const double _defaultDestLng = 74.3;

  late final StationRepository _stationRepository;
  late final TextEditingController _originLatController;
  late final TextEditingController _originLngController;
  late final TextEditingController _destLatController;
  late final TextEditingController _destLngController;

  bool _isLoading = false;
  bool _hasSearched = false;
  String? _errorMessage;
  String _selectedFuelType = 'all';
  List<Station> _stations = const [];

  @override
  void initState() {
    super.initState();
    final tokenManager = TokenManager();
    final apiClient = ApiClient(tokenManager: tokenManager);
    _stationRepository = StationRepository(apiClient: apiClient);
    _originLatController = TextEditingController(
      text: _defaultOriginLat.toString(),
    );
    _originLngController = TextEditingController(
      text: _defaultOriginLng.toString(),
    );
    _destLatController = TextEditingController(
      text: _defaultDestLat.toString(),
    );
    _destLngController = TextEditingController(
      text: _defaultDestLng.toString(),
    );
  }

  @override
  void dispose() {
    _originLatController.dispose();
    _originLngController.dispose();
    _destLatController.dispose();
    _destLngController.dispose();
    super.dispose();
  }

  double? _parseCoordinate(TextEditingController controller) {
    return double.tryParse(controller.text.trim());
  }

  Future<void> _searchRouteStations() async {
    final originLat = _parseCoordinate(_originLatController);
    final originLng = _parseCoordinate(_originLngController);
    final destLat = _parseCoordinate(_destLatController);
    final destLng = _parseCoordinate(_destLngController);

    if (originLat == null ||
        originLng == null ||
        destLat == null ||
        destLng == null) {
      setState(() {
        _errorMessage = 'Enter valid origin and destination coordinates.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasSearched = true;
    });

    try {
      final stations = await _stationRepository.getRouteStations(
        originLat: originLat,
        originLng: originLng,
        destLat: destLat,
        destLng: destLng,
        fuelType: _selectedFuelType == 'all' ? null : _selectedFuelType,
      );

      if (!mounted) return;
      setState(() {
        _stations = stations;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      var message = 'Unable to load route stations.';
      if (e is AppError && e.detail != null && e.detail!.trim().isNotEmpty) {
        message = e.detail!;
      }
      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    }
  }

  String _fuelTypeLabel(String value) {
    switch (value) {
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
        return 'All';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text('Route Stations', style: AppTextStyles.sectionHeading),
      ),
      body: ListView(
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
                Text('Route Search', style: AppTextStyles.cardTitle),
                SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _originLatController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Origin Lat',
                        ),
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        controller: _originLngController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Origin Lng',
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _destLatController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Destination Lat',
                        ),
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        controller: _destLngController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Destination Lng',
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: ['all', 'petrol', 'diesel', 'premium', 'cng', 'lpg']
                      .map(
                        (type) => ChoiceChip(
                          label: Text(_fuelTypeLabel(type)),
                          selected: _selectedFuelType == type,
                          selectedColor: AppColors.accentTeal,
                          onSelected: (_) {
                            setState(() {
                              _selectedFuelType = type;
                            });
                          },
                          labelStyle: AppTextStyles.caption.copyWith(
                            color: _selectedFuelType == type
                                ? AppColors.white
                                : AppColors.primaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                      .toList(),
                ),
                SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _searchRouteStations,
                    icon: const Icon(Icons.alt_route_rounded),
                    label: Text(_isLoading ? 'Searching...' : 'Find Stations'),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.md),
          if (_errorMessage != null)
            Container(
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppBorderRadius.card),
                boxShadow: AppShadows.subtleList,
              ),
              child: Text(_errorMessage!, style: AppTextStyles.body),
            )
          else if (!_hasSearched)
            Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Text(
                'Enter origin and destination coordinates to load stations along the route.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body,
              ),
            )
          else if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_stations.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Text(
                'No route stations found for the selected trip.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body,
              ),
            )
          else
            ..._stations.map(
              (station) => Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.md),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppBorderRadius.card),
                  onTap: () => Navigator.of(context).pushNamed(
                    '/station-detail',
                    arguments: {'stationId': station.id},
                  ),
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
                                station.name,
                                style: AppTextStyles.cardTitle,
                              ),
                            ),
                            if (station.distanceFromRouteKm != null)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accentTeal.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppBorderRadius.pill,
                                  ),
                                ),
                                child: Text(
                                  '${station.distanceFromRouteKm!.toStringAsFixed(1)} km off route',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.accentTeal,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: AppSpacing.xs),
                        Text(
                          '${station.address}, ${station.city}',
                          style: AppTextStyles.caption,
                        ),
                        SizedBox(height: AppSpacing.sm),
                        Text(
                          station.distanceKm != null
                              ? '${station.distanceKm!.toStringAsFixed(1)} km from origin'
                              : 'Distance N/A',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
