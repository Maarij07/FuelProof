import 'dart:math' as math;

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

class PriceHistoryScreen extends StatefulWidget {
  const PriceHistoryScreen({super.key});

  @override
  State<PriceHistoryScreen> createState() => _PriceHistoryScreenState();
}

class _PriceHistoryScreenState extends State<PriceHistoryScreen> {
  late final PriceRepository _priceRepository;

  bool _initialized = false;
  bool _isLoading = true;
  String? _errorMessage;
  String? _stationId;
  String _stationName = 'Station';
  String _fuelType = 'petrol';
  List<PriceHistory> _history = const [];

  @override
  void initState() {
    super.initState();
    final tokenManager = TokenManager();
    final apiClient = ApiClient(tokenManager: tokenManager);
    _priceRepository = PriceRepository(apiClient: apiClient);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic> && args['stationId'] is String) {
      _stationId = args['stationId'] as String;
      _stationName = (args['stationName'] as String?) ?? 'Station';
      _loadHistory();
    } else {
      setState(() {
        _errorMessage = 'Station price history unavailable.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadHistory() async {
    final stationId = _stationId;
    if (stationId == null || stationId.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _priceRepository.getPriceHistory(
        stationId: stationId,
        fuelType: _fuelType,
      );

      if (!mounted) return;
      setState(() {
        _history = list.take(10).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      var message = 'Unable to load price history.';
      if (e is AppError && e.detail != null && e.detail!.trim().isNotEmpty) {
        message = e.detail!;
      }
      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    }
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '--';
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
        title: Text('Price History', style: AppTextStyles.sectionHeading),
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.md),
        children: [
          Text(_stationName, style: AppTextStyles.cardTitle),
          SizedBox(height: AppSpacing.sm),
          _fuelTypeTabs(),
          SizedBox(height: AppSpacing.md),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage != null)
            _message(_errorMessage!)
          else if (_history.isEmpty)
            _message('No price history available.')
          else ...[
            _chartCard(),
            SizedBox(height: AppSpacing.md),
            ..._history.map((item) => _historyTile(item)),
          ],
        ],
      ),
    );
  }

  Widget _fuelTypeTabs() {
    const fuelTypes = ['petrol', 'diesel', 'premium', 'cng', 'lpg'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: fuelTypes.map((type) {
          final selected = _fuelType == type;
          return Padding(
            padding: EdgeInsets.only(right: AppSpacing.sm),
            child: ChoiceChip(
              label: Text(type.toUpperCase()),
              selected: selected,
              selectedColor: AppColors.accentTeal,
              onSelected: (_) {
                setState(() {
                  _fuelType = type;
                });
                _loadHistory();
              },
              labelStyle: AppTextStyles.caption.copyWith(
                color: selected ? AppColors.white : AppColors.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _chartCard() {
    final points = _history.reversed.map((e) => e.pricePerLitre).toList();
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
          Text('Last 10 records trend', style: AppTextStyles.cardTitle),
          SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 140,
            width: double.infinity,
            child: CustomPaint(
              painter: _MiniLinePainter(
                values: points,
                lineColor: AppColors.accentTeal,
                gridColor: AppColors.softGray,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyTile(PriceHistory item) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppBorderRadius.card),
          boxShadow: AppShadows.subtleList,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_formatDate(item.effectiveFrom), style: AppTextStyles.body),
            Text(
              'PKR ${item.pricePerLitre.toStringAsFixed(2)}',
              style: AppTextStyles.cardTitle.copyWith(
                color: AppColors.accentTeal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _message(String text) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Text(
          text,
          style: AppTextStyles.body,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _MiniLinePainter extends CustomPainter {
  _MiniLinePainter({
    required this.values,
    required this.lineColor,
    required this.gridColor,
  });

  final List<double> values;
  final Color lineColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = gridColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i <= 3; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    if (values.length < 2) return;

    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final range = (maxV - minV).abs() < 0.001 ? 1.0 : (maxV - minV);

    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final normalized = (values[i] - minV) / range;
      final y = size.height - (normalized * (size.height - 8)) - 4;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final line = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _MiniLinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor;
  }
}
