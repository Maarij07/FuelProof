import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/widgets/app_bottom_navigation_bar.dart';

class Station {
  final String id;
  final String name;
  final String location;
  final double distance;
  final double price;
  final double rating;
  final bool isFavorite;
  final String fuelType;
  final bool isOpen;

  Station({
    required this.id,
    required this.name,
    required this.location,
    required this.distance,
    required this.price,
    required this.rating,
    required this.isFavorite,
    required this.fuelType,
    required this.isOpen,
  });
}

class StationFinderScreen extends StatefulWidget {
  const StationFinderScreen({super.key}); // UPDATED

  @override
  State<StationFinderScreen> createState() => _StationFinderScreenState();
}

class _StationFinderScreenState extends State<StationFinderScreen> {
  String _selectedSort = 'Cheapest';
  late List<Station> _stations;
  late List<Station> _sortedStations;

  @override
  void initState() {
    super.initState();
    _initializeStations();
    _sortStations();
  }

  void _initializeStations() {
    _stations = [
      Station(
        id: 'S001',
        name: 'Shell - Makati Avenue',
        location: '123 Makati Ave, Makati City',
        distance: 0.8,
        price: 50.00,
        rating: 4.8,
        isFavorite: true,
        fuelType: 'Premium 95 RON',
        isOpen: true,
      ),
      Station(
        id: 'S002',
        name: 'Caltex - BGC',
        location: 'Fort Drive, BGC, Taguig',
        distance: 1.2,
        price: 49.50,
        rating: 4.6,
        isFavorite: false,
        fuelType: 'Diesel',
        isOpen: true,
      ),
      Station(
        id: 'S003',
        name: 'Petron - Quezon City',
        location: '456 Commonwealth Ave, QC',
        distance: 2.1,
        price: 50.50,
        rating: 4.5,
        isFavorite: false,
        fuelType: 'Premium 95 RON',
        isOpen: true,
      ),
      Station(
        id: 'S004',
        name: 'Chevron - Pasig',
        location: '789 Ortigas Ave, Pasig',
        distance: 3.5,
        price: 51.00,
        rating: 4.7,
        isFavorite: false,
        fuelType: 'Regular 91 RON',
        isOpen: false,
      ),
      Station(
        id: 'S005',
        name: 'Seaoil - Makati',
        location: '321 Ayala Ave, Makati',
        distance: 0.5,
        price: 49.75,
        rating: 4.4,
        isFavorite: false,
        fuelType: 'Diesel',
        isOpen: true,
      ),
      Station(
        id: 'S006',
        name: 'MLEX Gas Station',
        location: 'MLEX, San Juan',
        distance: 5.2,
        price: 50.25,
        rating: 4.3,
        isFavorite: false,
        fuelType: 'Premium 95 RON',
        isOpen: true,
      ),
    ];
  }

  void _sortStations() {
    _sortedStations = List.from(_stations);

    switch (_selectedSort) {
      case 'Cheapest':
        _sortedStations.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Nearest':
        _sortedStations.sort((a, b) => a.distance.compareTo(b.distance));
        break;
      case 'Favorite':
        _sortedStations.sort((a, b) => b.isFavorite ? 1 : -1);
        break;
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Find Stations', style: AppTextStyles.sectionHeading),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.navyLight,
                borderRadius: BorderRadius.circular(AppBorderRadius.card),
                boxShadow: AppShadows.subtleList,
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map, size: 48, color: AppColors.brandNavy),
                        SizedBox(height: AppSpacing.sm),
                        Text(
                          'Map View',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.brandNavy,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: AppSpacing.md,
                    right: AppSpacing.md,
                    child: Container(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                        boxShadow: AppShadows.lightList,
                      ),
                      child: Icon(
                        Icons.my_location,
                        color: AppColors.accentTeal,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: ['Cheapest', 'Nearest', 'Favorite'].map((sort) {
                final isSelected = _selectedSort == sort;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: AppSpacing.sm),
                    child: ChoiceChip(
                      label: Text(sort),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedSort = sort;
                            _sortStations();
                          });
                        }
                      },
                      backgroundColor: AppColors.white,
                      selectedColor: AppColors.accentTeal,
                      labelStyle: AppTextStyles.caption.copyWith(
                        color: isSelected
                            ? AppColors.white
                            : AppColors.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppBorderRadius.pill,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.accentTeal
                              : AppColors.softGray,
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: _sortedStations.length,
              itemBuilder: (context, index) {
                return _buildStationCard(_sortedStations[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStationCard(Station station) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${station.name} selected'),
              duration: Duration(milliseconds: 800),
            ),
          );
        },
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          station.name,
                          style: AppTextStyles.cardTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: AppSpacing.xs),
                        Text(
                          station.location,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.secondaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        final stationToUpdate = _stations.firstWhere(
                          (s) => s.id == station.id,
                        );
                        final index = _stations.indexOf(stationToUpdate);
                        _stations[index] = Station(
                          id: stationToUpdate.id,
                          name: stationToUpdate.name,
                          location: stationToUpdate.location,
                          distance: stationToUpdate.distance,
                          price: stationToUpdate.price,
                          rating: stationToUpdate.rating,
                          isFavorite: !stationToUpdate.isFavorite,
                          fuelType: stationToUpdate.fuelType,
                          isOpen: stationToUpdate.isOpen,
                        );
                        _sortStations();
                      });
                    },
                    icon: Icon(
                      station.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: AppColors.alert,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Price',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        'â‚±${station.price.toStringAsFixed(2)}/L',
                        style: AppTextStyles.cardTitle.copyWith(
                          color: AppColors.accentTeal,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Distance',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        '${station.distance} km',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rating',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: AppColors.warning,
                          ),
                          SizedBox(width: AppSpacing.xs),
                          Text(
                            station.rating.toStringAsFixed(1),
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(width: AppSpacing.md),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: station.isOpen
                          ? AppColors.successLight
                          : AppColors.alertLight,
                      borderRadius: BorderRadius.circular(AppBorderRadius.pill),
                    ),
                    child: Text(
                      station.isOpen ? 'Open' : 'Closed',
                      style: AppTextStyles.caption.copyWith(
                        color: station.isOpen
                            ? AppColors.success
                            : AppColors.alert,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.md),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.tealLight,
                  borderRadius: BorderRadius.circular(AppBorderRadius.small),
                ),
                child: Text(
                  station.fuelType,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.accentTeal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
