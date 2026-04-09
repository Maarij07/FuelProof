import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/text_styles.dart';
import '../../core/models/error_models.dart';
import '../../core/models/station_models.dart';
import '../../core/repositories/station_repository.dart';
import '../../core/services/api_client.dart';
import '../../core/services/token_manager.dart';

class StationDetailScreen extends StatefulWidget {
  const StationDetailScreen({super.key});

  @override
  State<StationDetailScreen> createState() => _StationDetailScreenState();
}

class _StationDetailScreenState extends State<StationDetailScreen> {
  late final StationRepository _stationRepository;

  bool _initialized = false;
  bool _isLoading = true;
  bool _isFavoriteLoading = true;
  bool _isTogglingFavorite = false;
  String? _errorMessage;
  Station? _station;
  String? _stationId;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    final tokenManager = TokenManager();
    final apiClient = ApiClient(tokenManager: tokenManager);
    _stationRepository = StationRepository(apiClient: apiClient);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic> && args['stationId'] is String) {
      _stationId = args['stationId'] as String;
      _loadStation();
    } else {
      setState(() {
        _errorMessage = 'Station details not found.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStation() async {
    final id = _stationId;
    if (id == null || id.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final station = await _stationRepository.getStation(id);
      if (!mounted) return;
      setState(() {
        _station = station;
        _isLoading = false;
      });
      _loadFavoriteState();
    } catch (e) {
      if (!mounted) return;
      var message = 'Unable to load station details.';
      if (e is AppError && e.detail != null && e.detail!.trim().isNotEmpty) {
        message = e.detail!;
      }
      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFavoriteState() async {
    final station = _station;
    if (station == null) return;

    setState(() {
      _isFavoriteLoading = true;
    });

    try {
      final favorites = await _stationRepository.getFavoriteStations();
      if (!mounted) return;
      setState(() {
        _isFavorite = favorites.any((item) => item.id == station.id);
        _isFavoriteLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isFavoriteLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final station = _station;
    if (station == null || _isFavoriteLoading || _isTogglingFavorite) return;

    final previous = _isFavorite;
    setState(() {
      _isFavorite = !previous;
      _isTogglingFavorite = true;
    });

    try {
      if (previous) {
        await _stationRepository.removeFavorite(station.id);
      } else {
        await _stationRepository.addFavorite(station.id);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isFavorite = previous;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update favorite right now')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isTogglingFavorite = false;
        });
      }
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
        return value.toUpperCase();
    }
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

  Future<void> _callStation(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (!await launchUrl(uri)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open dialer right now')),
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
        actions: [
          IconButton(
            onPressed: _isFavoriteLoading || _isTogglingFavorite
                ? null
                : _toggleFavorite,
            icon: _isFavoriteLoading || _isTogglingFavorite
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.alert,
                      ),
                    ),
                  )
                : Icon(
                    _isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border,
                    color: AppColors.alert,
                  ),
          ),
        ],
        title: Text('Station Detail', style: AppTextStyles.sectionHeading),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!, style: AppTextStyles.body))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final station = _station!;

    return ListView(
      padding: EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          station.name,
          style: AppTextStyles.sectionHeading.copyWith(fontSize: 24),
        ),
        SizedBox(height: AppSpacing.xs),
        Text('${station.address}, ${station.city}', style: AppTextStyles.body),
        SizedBox(height: AppSpacing.md),
        Row(
          children: [
            _chip(
              station.isActive ? 'Open' : 'Closed',
              station.isActive ? AppColors.success : AppColors.alert,
            ),
            SizedBox(width: AppSpacing.sm),
            if (station.distanceKm != null)
              _chip(
                '${station.distanceKm!.toStringAsFixed(1)} km from you',
                AppColors.accentTeal,
              ),
          ],
        ),
        SizedBox(height: AppSpacing.lg),
        _sectionCard(
          title: 'Fuel Types Available',
          child: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: station.fuelTypesAvailable
                .map((type) => _chip(_fuelTypeLabel(type), AppColors.brandNavy))
                .toList(),
          ),
        ),
        SizedBox(height: AppSpacing.md),
        _sectionCard(
          title: 'Station Info',
          child: Column(
            children: [
              _infoRow('Operating Hours', station.operatingHours ?? 'N/A'),
              Divider(color: AppColors.softGray),
              _infoRow('Contact', station.contactPhone ?? 'N/A'),
              Divider(color: AppColors.softGray),
              _infoRow(
                'Coordinates',
                '${station.latitude}, ${station.longitude}',
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pushNamed(
              '/price-history',
              arguments: {'stationId': station.id, 'stationName': station.name},
            ),
            icon: const Icon(Icons.show_chart_rounded),
            label: const Text('View Prices'),
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _openDirections(station),
            icon: const Icon(Icons.navigation_rounded),
            label: const Text('Get Directions'),
          ),
        ),
        if (_isFavoriteLoading) ...[
          SizedBox(height: AppSpacing.sm),
          Text(
            'Checking favorite status...',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ],
        if (station.contactPhone != null) ...[
          SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _callStation(station.contactPhone!),
              icon: const Icon(Icons.call_rounded),
              label: const Text('Call Station'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
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
          Text(title, style: AppTextStyles.cardTitle),
          SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.caption),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
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
}
