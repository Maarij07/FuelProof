import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/text_styles.dart';
import '../../core/models/error_models.dart';
import '../../core/models/station_models.dart';
import '../../core/repositories/station_repository.dart';
import '../../core/state/app_providers.dart';
import '../../shared/widgets/app_bottom_navigation_bar.dart';

class StationFinderScreen extends ConsumerStatefulWidget {
  const StationFinderScreen({super.key});

  @override
  ConsumerState<StationFinderScreen> createState() =>
      _StationFinderScreenState();
}

class _StationFinderScreenState extends ConsumerState<StationFinderScreen> {
  static const double _defaultLat = 31.5204;
  static const double _defaultLng = 74.3587;

  late final StationRepository _stationRepository;

  bool _isLoading = true;
  String? _errorMessage;
  List<Station> _stations = const [];
  Set<String> _favoriteIds = <String>{};

  String _selectedFuelType = 'all';
  double _radiusKm = 10;
  bool _isMapView = true;

  @override
  void initState() {
    super.initState();
    _stationRepository = ref.read(stationRepositoryProvider);
    _loadStations();
  }

  Future<void> _loadStations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final stations = await _stationRepository.getNearbyStations(
        latitude: _defaultLat,
        longitude: _defaultLng,
        radiusKm: _radiusKm.toInt(),
        fuelType: _selectedFuelType == 'all' ? null : _selectedFuelType,
      );

      final favorites = await _stationRepository.getFavoriteStations();

      if (!mounted) return;

      setState(() {
        _stations = stations;
        _favoriteIds = favorites.map((s) => s.id).toSet();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      var message = 'Unable to load nearby stations.';
      if (e is AppError && e.detail != null && e.detail!.trim().isNotEmpty) {
        message = e.detail!;
      }

      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite(Station station) async {
    final isFavorite = _favoriteIds.contains(station.id);

    setState(() {
      if (isFavorite) {
        _favoriteIds.remove(station.id);
      } else {
        _favoriteIds.add(station.id);
      }
    });

    try {
      if (isFavorite) {
        await _stationRepository.removeFavorite(station.id);
      } else {
        await _stationRepository.addFavorite(station.id);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (isFavorite) {
          _favoriteIds.add(station.id);
        } else {
          _favoriteIds.remove(station.id);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update favorite right now')),
      );
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
      bottomNavigationBar: const AppBottomNavigationBar(currentIndex: 0),
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.primaryText),
        ),
        title: Text('Find Stations', style: AppTextStyles.sectionHeading),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed('/route-stations'),
            icon: Icon(Icons.route_rounded, color: AppColors.accentTeal),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed('/favorites'),
            icon: Icon(Icons.favorite_rounded, color: AppColors.alert),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildControls(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? _buildErrorState()
                : _stations.isEmpty
                ? _buildEmptyState()
                : (_isMapView ? _buildMapLikeView() : _buildListView()),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppBorderRadius.card),
                    border: Border.all(color: AppColors.softGray),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedFuelType,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Fuel')),
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
                        setState(() {
                          _selectedFuelType = value;
                        });
                        _loadStations();
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.md),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: true,
                    icon: Icon(Icons.map_rounded),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    icon: Icon(Icons.list_rounded),
                  ),
                ],
                selected: <bool>{_isMapView},
                onSelectionChanged: (selected) {
                  setState(() {
                    _isMapView = selected.first;
                  });
                },
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text(
                'Radius: ${_radiusKm.toStringAsFixed(0)} km',
                style: AppTextStyles.body,
              ),
              Expanded(
                child: Slider(
                  value: _radiusKm,
                  min: 1,
                  max: 30,
                  divisions: 29,
                  onChanged: (value) {
                    setState(() {
                      _radiusKm = value;
                    });
                  },
                  onChangeEnd: (_) => _loadStations(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapLikeView() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.navyLight,
              borderRadius: BorderRadius.circular(AppBorderRadius.card),
              boxShadow: AppShadows.subtleList,
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    'Map Preview',
                    style: AppTextStyles.cardTitle.copyWith(
                      color: AppColors.brandNavy,
                    ),
                  ),
                ),
                Positioned(
                  top: AppSpacing.md,
                  right: AppSpacing.md,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppBorderRadius.pill),
                    ),
                    child: Text(
                      '${_stations.length} stations',
                      style: AppTextStyles.caption,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.md),
          ..._stations.take(5).map(_buildStationCard),
          SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: _stations.length,
      itemBuilder: (context, index) => _buildStationCard(_stations[index]),
    );
  }

  Widget _buildStationCard(Station station) {
    final isFavorite = _favoriteIds.contains(station.id);

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        onTap: () => Navigator.of(
          context,
        ).pushNamed('/station-detail', arguments: {'stationId': station.id}),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(station.name, style: AppTextStyles.cardTitle),
                        SizedBox(height: AppSpacing.xs),
                        Text(
                          '${station.address}, ${station.city}',
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _toggleFavorite(station),
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: AppColors.alert,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  _chip(
                    station.isActive ? 'Open' : 'Closed',
                    station.isActive ? AppColors.success : AppColors.alert,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  _chip(
                    station.distanceKm != null
                        ? '${station.distanceKm!.toStringAsFixed(1)} km away'
                        : 'Distance N/A',
                    AppColors.accentTeal,
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: station.fuelTypesAvailable
                    .map(
                      (type) =>
                          _chip(_fuelTypeLabel(type), AppColors.brandNavy),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppBorderRadius.pill),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: AppColors.alert, size: 42),
            SizedBox(height: AppSpacing.md),
            Text(
              _errorMessage ?? 'Failed to load stations',
              style: AppTextStyles.body,
            ),
            SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: _loadStations,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Text(
          'No stations found in selected radius/fuel type.',
          style: AppTextStyles.body,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
