import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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
  static const bool _useRealGoogleMap = bool.fromEnvironment(
    'USE_GOOGLE_MAPS',
    defaultValue: kReleaseMode,
  );

  late final StationRepository _stationRepository;
  late final TextEditingController _searchController;

  bool _isLoading = true;
  String? _errorMessage;
  List<Station> _stations = const [];
  Set<String> _favoriteIds = <String>{};
  GoogleMapController? _mapController;

  String _stationGroup = 'all';
  String _fuelType = 'all';
  String _sortBy = 'recommended';
  double _radiusMiles = 100;
  String _searchQuery = '';
  String? _selectedStationId;

  @override
  void initState() {
    super.initState();
    _stationRepository = ref.read(stationRepositoryProvider);
    _searchController = TextEditingController();
    _loadStations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
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
        radiusKm: (_radiusMiles * 1.60934).round(),
        fuelType: _fuelType == 'all' ? null : _fuelType,
      );

      final favorites = await _stationRepository.getFavoriteStations();

      if (!mounted) return;

      setState(() {
        _stations = stations;
        _favoriteIds = favorites.map((station) => station.id).toSet();
        _selectedStationId = stations.isEmpty
            ? null
            : (_selectedStationId != null &&
                      stations.any(
                        (station) => station.id == _selectedStationId,
                      )
                  ? _selectedStationId
                  : stations.first.id);
        _isLoading = false;
      });

      if (_useRealGoogleMap) {
        await _fitMapToStations();
      }
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

  List<Station> get _filteredStations {
    Iterable<Station> stations = _stations;

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      stations = stations.where((station) {
        return station.name.toLowerCase().contains(query) ||
            station.address.toLowerCase().contains(query) ||
            station.city.toLowerCase().contains(query);
      });
    }

    if (_stationGroup == 'favorites') {
      stations = stations.where((station) => _favoriteIds.contains(station.id));
    } else if (_stationGroup == 'savings') {
      stations = stations.where((station) => _stationPrice(station) != null);
    } else if (_stationGroup == 'open') {
      stations = stations.where((station) => station.isActive);
    }

    final list = stations.toList();

    switch (_sortBy) {
      case 'price':
        list.sort((left, right) {
          final leftPrice = _stationPrice(left);
          final rightPrice = _stationPrice(right);
          if (leftPrice == null && rightPrice == null) return 0;
          if (leftPrice == null) return 1;
          if (rightPrice == null) return -1;
          return leftPrice.compareTo(rightPrice);
        });
        break;
      case 'distance':
        list.sort((left, right) {
          final leftDistance = left.distanceKm ?? double.infinity;
          final rightDistance = right.distanceKm ?? double.infinity;
          return leftDistance.compareTo(rightDistance);
        });
        break;
      default:
        list.sort((left, right) {
          if (left.isActive != right.isActive) {
            return left.isActive ? -1 : 1;
          }

          if (_favoriteIds.contains(left.id) !=
              _favoriteIds.contains(right.id)) {
            return _favoriteIds.contains(left.id) ? -1 : 1;
          }

          final leftDistance = left.distanceKm ?? double.infinity;
          final rightDistance = right.distanceKm ?? double.infinity;
          return leftDistance.compareTo(rightDistance);
        });
    }

    return list;
  }

  Station? get _selectedStation {
    final selectedId = _selectedStationId;
    if (selectedId == null) return null;
    for (final station in _filteredStations) {
      if (station.id == selectedId) return station;
    }
    return null;
  }

  LatLng get _mapCenter {
    final selectedStation = _selectedStation;
    if (selectedStation != null) {
      return LatLng(selectedStation.latitude, selectedStation.longitude);
    }

    final stations = _filteredStations;
    if (stations.isNotEmpty) {
      final station = stations.first;
      return LatLng(station.latitude, station.longitude);
    }

    return const LatLng(_defaultLat, _defaultLng);
  }

  double? _stationPrice(Station station) {
    final prices = station.currentPrices;

    if (prices is num) {
      return prices.toDouble();
    }

    if (prices is Map) {
      final preferredKeys = <String>[
        _fuelType,
        'price',
        'regular',
        'petrol',
        'diesel',
        'premium',
      ];

      for (final key in preferredKeys) {
        final value = prices[key];
        if (value is num) return value.toDouble();
        if (value is Map && value['price_per_litre'] is num) {
          return (value['price_per_litre'] as num).toDouble();
        }
      }

      for (final value in prices.values) {
        if (value is num) return value.toDouble();
        if (value is Map && value['price_per_litre'] is num) {
          return (value['price_per_litre'] as num).toDouble();
        }
      }
    }

    return null;
  }

  String _formatPrice(double? value) {
    if (value == null) return 'Price N/A';
    return '\$${value.toStringAsFixed(2)}';
  }

  String _formatUpdatedAt(Station station) {
    final created = DateTime.tryParse(station.createdAt);
    if (created == null) return 'Updated recently';

    final difference = DateTime.now().difference(created);
    if (difference.inMinutes < 60) {
      return 'Updated ${difference.inMinutes} mins ago';
    }

    if (difference.inHours < 24) {
      return 'Updated ${difference.inHours} hours ago';
    }

    return 'Updated ${difference.inDays} days ago';
  }

  Set<Marker> _buildMarkers() {
    return _filteredStations.map((station) {
      final isSelected = station.id == _selectedStationId;
      return Marker(
        markerId: MarkerId(station.id),
        position: LatLng(station.latitude, station.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isSelected
              ? BitmapDescriptor.hueAzure
              : station.isActive
              ? BitmapDescriptor.hueGreen
              : BitmapDescriptor.hueRed,
        ),
        infoWindow: InfoWindow(
          title: station.name,
          snippet: '${station.address}, ${station.city}',
          onTap: () => _openStationDetail(station.id),
        ),
        onTap: () => _selectStation(station),
      );
    }).toSet();
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    await _fitMapToStations();
  }

  Future<void> _fitMapToStations() async {
    final controller = _mapController;
    final stations = _filteredStations;
    if (controller == null || stations.isEmpty) return;

    if (stations.length == 1) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(stations.first.latitude, stations.first.longitude),
          14,
        ),
      );
      return;
    }

    final latitudes = stations.map((station) => station.latitude).toList();
    final longitudes = stations.map((station) => station.longitude).toList();

    final bounds = LatLngBounds(
      southwest: LatLng(
        latitudes.reduce((left, right) => left < right ? left : right),
        longitudes.reduce((left, right) => left < right ? left : right),
      ),
      northeast: LatLng(
        latitudes.reduce((left, right) => left > right ? left : right),
        longitudes.reduce((left, right) => left > right ? left : right),
      ),
    );

    try {
      await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 64));
    } catch (_) {
      await controller.animateCamera(CameraUpdate.newLatLng(_mapCenter));
    }
  }

  Future<void> _moveCameraToSelectedStation() async {
    final controller = _mapController;
    final station = _selectedStation;
    if (controller == null || station == null) return;

    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(station.latitude, station.longitude),
        14,
      ),
    );
  }

  void _selectStation(Station station) {
    setState(() {
      _selectedStationId = station.id;
    });

    unawaited(_moveCameraToSelectedStation());
  }

  void _openStationDetail(String stationId) {
    Navigator.of(
      context,
    ).pushNamed('/station-detail', arguments: {'stationId': stationId});
  }

  Future<void> _openDirections(Station station) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${station.latitude},${station.longitude}',
    );

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open directions right now')),
      );
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

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _selectedStationId = _filteredStations.isEmpty
          ? null
          : (_selectedStationId != null &&
                    _filteredStations.any(
                      (station) => station.id == _selectedStationId,
                    )
                ? _selectedStationId
                : _filteredStations.first.id);
    });

    if (_useRealGoogleMap) {
      unawaited(_fitMapToStations());
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
        title: Text('Fuel Map', style: AppTextStyles.sectionHeading),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? _buildErrorState()
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 900;

                        return Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: isWide
                              ? Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    SizedBox(
                                      width: 430,
                                      child: _buildLeftPanel(),
                                    ),
                                    SizedBox(width: AppSpacing.md),
                                    Expanded(child: _buildMapPanel()),
                                  ],
                                )
                              : _buildMobileLayout(),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    final stations = _filteredStations;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearchBar(),
          SizedBox(height: AppSpacing.md),
          _buildFilterRow(compact: true),
          SizedBox(height: AppSpacing.md),
          _buildResultsHeader(),
          SizedBox(height: AppSpacing.md),
          SizedBox(height: 280, child: _buildMapPanel()),
          SizedBox(height: AppSpacing.md),
          if (stations.isEmpty)
            _buildNoResultsState()
          else
            ...stations.map(_buildStationCard),
          SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppBorderRadius.card),
              border: Border.all(color: AppColors.softGray),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: AppColors.primaryText),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: const InputDecoration(
                      hintText: 'Search stations or city',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                    icon: const Icon(Icons.close_rounded),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pushNamed('/route-stations'),
          icon: const Icon(Icons.route_rounded),
          label: const Text('Route'),
        ),
      ],
    );
  }

  Widget _buildLeftPanel({bool compact = false}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        border: Border.all(color: AppColors.softGray),
        boxShadow: AppShadows.subtleList,
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(
                            AppBorderRadius.card,
                          ),
                          border: Border.all(color: AppColors.softGray),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              color: AppColors.primaryText,
                            ),
                            SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: _onSearchChanged,
                                decoration: const InputDecoration(
                                  hintText: 'Search stations or city',
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                            if (_searchQuery.isNotEmpty)
                              IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                                icon: const Icon(Icons.close_rounded),
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    FilledButton.icon(
                      onPressed: () =>
                          Navigator.of(context).pushNamed('/route-stations'),
                      icon: const Icon(Icons.route_rounded),
                      label: const Text('Route'),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.md),
                _buildFilterRow(compact: compact),
                SizedBox(height: AppSpacing.md),
                _buildResultsHeader(),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: _filteredStations.isEmpty
                  ? _buildNoResultsState()
                  : ListView.builder(
                      itemCount: _filteredStations.length,
                      itemBuilder: (context, index) {
                        return _buildStationCard(_filteredStations[index]);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow({required bool compact}) {
    final spacing = compact ? AppSpacing.sm : AppSpacing.md;
    final radiusWidth = compact ? 110.0 : 120.0;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        SizedBox(
          width: compact ? 170 : 180,
          child: _buildDropdownField(
            value: _stationGroup,
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All Stations')),
              DropdownMenuItem(
                value: 'savings',
                child: Text('Savings Stations'),
              ),
              DropdownMenuItem(value: 'favorites', child: Text('Favorites')),
              DropdownMenuItem(value: 'open', child: Text('Open Now')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _stationGroup = value;
              });
              if (_useRealGoogleMap) unawaited(_fitMapToStations());
            },
          ),
        ),
        SizedBox(
          width: compact ? 150 : 160,
          child: _buildDropdownField(
            value: _fuelType,
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All Fuel')),
              DropdownMenuItem(value: 'petrol', child: Text('Petrol')),
              DropdownMenuItem(value: 'diesel', child: Text('Diesel')),
              DropdownMenuItem(value: 'premium', child: Text('Premium')),
              DropdownMenuItem(value: 'cng', child: Text('CNG')),
              DropdownMenuItem(value: 'lpg', child: Text('LPG')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _fuelType = value;
              });
              _loadStations();
            },
          ),
        ),
        SizedBox(
          width: radiusWidth,
          child: _buildDropdownField(
            value: _radiusMiles.toInt().toString(),
            items: const [
              DropdownMenuItem(value: '5', child: Text('5 mi')),
              DropdownMenuItem(value: '30', child: Text('30 mi')),
              DropdownMenuItem(value: '50', child: Text('50 mi')),
              DropdownMenuItem(value: '100', child: Text('100 mi')),
              DropdownMenuItem(value: '200', child: Text('200 mi')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _radiusMiles = double.tryParse(value) ?? _radiusMiles;
              });
              _loadStations();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultsHeader() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Results', style: AppTextStyles.cardTitle),
            SizedBox(height: AppSpacing.xs),
            Text(
              '${_filteredStations.length} merchants',
              style: AppTextStyles.caption,
            ),
          ],
        ),
        const Spacer(),
        SizedBox(
          width: 160,
          child: _buildDropdownField(
            value: _sortBy,
            items: const [
              DropdownMenuItem(
                value: 'recommended',
                child: Text('Recommended'),
              ),
              DropdownMenuItem(value: 'price', child: Text('Price')),
              DropdownMenuItem(value: 'distance', child: Text('Distance')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _sortBy = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        border: Border.all(color: AppColors.softGray),
      ),
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildMapPanel() {
    final selectedStation = _selectedStation;

    if (!_useRealGoogleMap) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppBorderRadius.card),
          border: Border.all(color: AppColors.softGray),
          boxShadow: AppShadows.subtleList,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _MockMapPainter())),
            Positioned(
              left: AppSpacing.md,
              top: AppSpacing.md,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppBorderRadius.pill),
                ),
                child: const Text('Search this area'),
              ),
            ),
            Positioned(
              right: AppSpacing.md,
              bottom: AppSpacing.md,
              child: FloatingActionButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Map preview mode')),
                ),
                backgroundColor: AppColors.accentTeal,
                child: const Icon(Icons.chat_bubble_outline_rounded),
              ),
            ),
            if (selectedStation != null)
              Positioned(
                left: AppSpacing.md,
                bottom: AppSpacing.md,
                right: AppSpacing.md,
                child: _stationPriceBubble(selectedStation),
              ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        border: Border.all(color: AppColors.softGray),
        boxShadow: AppShadows.subtleList,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _mapCenter,
              zoom: _filteredStations.length == 1 ? 14 : 10,
            ),
            markers: _buildMarkers(),
            onMapCreated: _onMapCreated,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            compassEnabled: true,
            onTap: (_) {
              if (_selectedStationId == null) return;
              setState(() {
                _selectedStationId = null;
              });
            },
          ),
          Positioned(
            left: AppSpacing.md,
            top: AppSpacing.md,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppBorderRadius.pill),
                boxShadow: AppShadows.subtleList,
              ),
              child: Text(
                '${_filteredStations.length} results',
                style: AppTextStyles.caption,
              ),
            ),
          ),
          if (selectedStation != null)
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.md,
              child: _stationPriceBubble(selectedStation),
            ),
        ],
      ),
    );
  }

  Widget _stationPriceBubble(Station station) {
    final price = _stationPrice(station);

    return GestureDetector(
      onTap: () => _openStationDetail(station.id),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppBorderRadius.card),
          boxShadow: AppShadows.subtleList,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.tealLight,
              ),
              child: Icon(
                Icons.local_gas_station_rounded,
                color: AppColors.accentTeal,
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(station.name, style: AppTextStyles.cardTitle),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    '${station.distanceKm != null ? '${station.distanceKm!.toStringAsFixed(1)} km away' : 'Distance N/A'} • ${_formatUpdatedAt(station)}',
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatPrice(price),
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 20),
                ),
                SizedBox(height: AppSpacing.xs),
                TextButton.icon(
                  onPressed: () => _openDirections(station),
                  icon: const Icon(Icons.directions_rounded),
                  label: const Text('Directions'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStationCard(Station station) {
    final isFavorite = _favoriteIds.contains(station.id);
    final price = _stationPrice(station);

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        onTap: () => _openStationDetail(station.id),
        child: Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: _selectedStationId == station.id
                ? AppColors.tealLight
                : AppColors.white,
            borderRadius: BorderRadius.circular(AppBorderRadius.card),
            border: Border.all(
              color: _selectedStationId == station.id
                  ? AppColors.accentTeal
                  : AppColors.softGray,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.lightGray,
                ),
                child: Center(
                  child: Text(
                    station.name.isNotEmpty
                        ? station.name[0].toUpperCase()
                        : '?',
                    style: AppTextStyles.cardTitle,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                station.name,
                                style: AppTextStyles.cardTitle,
                              ),
                              SizedBox(height: AppSpacing.xs),
                              Text(
                                '${station.distanceKm != null ? '${station.distanceKm!.toStringAsFixed(1)} km away' : 'Distance N/A'} • ${_formatUpdatedAt(station)}',
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
                            isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border,
                            color: AppColors.alert,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _chip(
                          station.isActive ? 'Open' : 'Closed',
                          station.isActive
                              ? AppColors.success
                              : AppColors.alert,
                        ),
                        if (price != null) _chip('6¢ off', AppColors.success),
                        if (station.distanceKm != null)
                          _chip(
                            '${station.distanceKm!.toStringAsFixed(1)} km away',
                            AppColors.accentTeal,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatPrice(price),
                    style: AppTextStyles.cardTitle.copyWith(fontSize: 20),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(_fuelTypeLabel(_fuelType), style: AppTextStyles.caption),
                ],
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
              textAlign: TextAlign.center,
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

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.gas_meter_rounded, size: 56, color: AppColors.brandNavy),
            SizedBox(height: AppSpacing.md),
            Text('Nothing in this area', style: AppTextStyles.cardTitle),
            SizedBox(height: AppSpacing.xs),
            Text(
              'Try searching another area or applying different filters.',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MockMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = const Color(0xFFEAF2EF)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Offset.zero & size, backgroundPaint);

    final gridPaint = Paint()
      ..color = const Color(0xFFBCD8D3).withValues(alpha: 0.75)
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += 52) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    for (double y = 0; y <= size.height; y += 52) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final routePaint = Paint()
      ..color = const Color(0xFF8BC3BE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    final route = Path()
      ..moveTo(size.width * 0.08, size.height * 0.76)
      ..quadraticBezierTo(
        size.width * 0.34,
        size.height * 0.6,
        size.width * 0.52,
        size.height * 0.66,
      )
      ..quadraticBezierTo(
        size.width * 0.7,
        size.height * 0.72,
        size.width * 0.88,
        size.height * 0.28,
      );

    canvas.drawPath(route, routePaint);

    final markerPaint = Paint()..color = const Color(0xFF0CA7A0);
    final markerOutline = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final points = <Offset>[
      Offset(size.width * 0.24, size.height * 0.58),
      Offset(size.width * 0.52, size.height * 0.48),
      Offset(size.width * 0.76, size.height * 0.36),
    ];

    for (final point in points) {
      canvas.drawCircle(point, 10, markerPaint);
      canvas.drawCircle(point, 10, markerOutline);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
