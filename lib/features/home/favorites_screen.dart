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

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late final StationRepository _stationRepository;

  bool _isLoading = true;
  String? _errorMessage;
  List<Station> _favorites = const [];

  @override
  void initState() {
    super.initState();
    final tokenManager = TokenManager();
    final apiClient = ApiClient(tokenManager: tokenManager);
    _stationRepository = StationRepository(apiClient: apiClient);
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final favorites = await _stationRepository.getFavoriteStations();
      if (!mounted) return;
      setState(() {
        _favorites = favorites;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      var message = 'Unable to load favorites.';
      if (e is AppError && e.detail != null && e.detail!.trim().isNotEmpty) {
        message = e.detail!;
      }
      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFavorite(String stationId) async {
    final previous = _favorites;
    setState(() {
      _favorites = _favorites.where((s) => s.id != stationId).toList();
    });

    try {
      await _stationRepository.removeFavorite(stationId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Removed from favorites')));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _favorites = previous;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to remove favorite right now')),
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
        title: Text('Favorite Stations', style: AppTextStyles.sectionHeading),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!, style: AppTextStyles.body))
          : _favorites.isEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'No favorite stations yet. Tap favorite on any station to save it.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body,
                ),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(AppSpacing.md),
              itemCount: _favorites.length,
              itemBuilder: (context, index) {
                final station = _favorites[index];
                return Dismissible(
                  key: ValueKey(station.id),
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
                  onDismissed: (_) => _removeFavorite(station.id),
                  child: Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: InkWell(
                      onTap: () => Navigator.of(context).pushNamed(
                        '/station-detail',
                        arguments: {'stationId': station.id},
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
                            Text(station.name, style: AppTextStyles.cardTitle),
                            SizedBox(height: AppSpacing.xs),
                            Text(
                              '${station.address}, ${station.city}',
                              style: AppTextStyles.caption,
                            ),
                            SizedBox(height: AppSpacing.sm),
                            Text(
                              station.distanceKm != null
                                  ? '${station.distanceKm!.toStringAsFixed(1)} km away'
                                  : 'Distance N/A',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.accentTeal,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
