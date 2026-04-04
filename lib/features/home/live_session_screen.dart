import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/app_constants.dart';

class LiveSessionScreen extends StatefulWidget {
  const LiveSessionScreen({super.key}); // UPDATED

  @override
  State<LiveSessionScreen> createState() => _LiveSessionScreenState();
}

class _LiveSessionScreenState extends State<LiveSessionScreen> {
  int _fuelLiters = 45;
  double _costAmount = 2250.00;
  int _elapsedSeconds = 125;
  String _nozzleStatus = 'Active';
  bool _isPumping = true;

  @override
  void initState() {
    super.initState();
    _startPumpingSimulation();
  }

  void _startPumpingSimulation() {
    Future.delayed(Duration(seconds: 1), () {
      if (mounted && _isPumping) {
        setState(() {
          _fuelLiters += 1;
          _costAmount += 50.0;
          _elapsedSeconds += 1;
        });
        _startPumpingSimulation();
      }
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _stopSession() {
    setState(() {
      _isPumping = false;
      _nozzleStatus = 'Stopped';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Session stopped successfully'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Live Session', style: AppTextStyles.sectionHeading),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppBorderRadius.card),
                  boxShadow: AppShadows.subtleList,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pump Status',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.secondaryText,
                              ),
                            ),
                            SizedBox(height: AppSpacing.xs),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _isPumping
                                        ? AppColors.success
                                        : AppColors.alert,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                SizedBox(width: AppSpacing.sm),
                                Text(
                                  _nozzleStatus,
                                  style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: _isPumping
                                        ? AppColors.success
                                        : AppColors.alert,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Time Elapsed',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.secondaryText,
                              ),
                            ),
                            SizedBox(height: AppSpacing.xs),
                            Text(
                              _formatTime(_elapsedSeconds),
                              style: AppTextStyles.cardTitle.copyWith(
                                color: AppColors.brandNavy,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              Text('Fuel Dispensed', style: AppTextStyles.cardTitle),
              SizedBox(height: AppSpacing.md),
              Container(
                padding: EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppBorderRadius.card),
                  boxShadow: AppShadows.subtleList,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Volume',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.secondaryText,
                              ),
                            ),
                            SizedBox(height: AppSpacing.sm),
                            Text(
                              '$_fuelLiters L',
                              style: AppTextStyles.liveDataHero.copyWith(
                                fontSize: 48,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Total Cost',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.secondaryText,
                              ),
                            ),
                            SizedBox(height: AppSpacing.sm),
                            Text(
                              'â‚±${_costAmount.toStringAsFixed(2)}',
                              style: AppTextStyles.liveDataHero.copyWith(
                                fontSize: 48,
                                color: AppColors.accentTeal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.lg),
                    LinearProgressIndicator(
                      value: (_fuelLiters % 100) / 100,
                      backgroundColor: AppColors.lightGray,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.accentTeal,
                      ),
                      minHeight: 6,
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Price per liter: â‚±50.00',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                        Text(
                          'Tank: ${(_fuelLiters % 100)}%',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.accentTeal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              Text('Nozzle Information', style: AppTextStyles.cardTitle),
              SizedBox(height: AppSpacing.md),
              Container(
                padding: EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppBorderRadius.card),
                  boxShadow: AppShadows.subtleList,
                ),
                child: Column(
                  children: [
                    _buildInfoRow('Nozzle ID', 'NZ-0847'),
                    Divider(color: AppColors.softGray, height: AppSpacing.lg),
                    _buildInfoRow('Pump Number', 'Pump 3'),
                    Divider(color: AppColors.softGray, height: AppSpacing.lg),
                    _buildInfoRow('Fuel Grade', 'Premium 95 RON'),
                    Divider(color: AppColors.softGray, height: AppSpacing.lg),
                    _buildInfoRow('Temperature', '32Â°C'),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isPumping ? _stopSession : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.alert,
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppBorderRadius.button,
                      ),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: AppColors.softGray,
                  ),
                  child: Text(
                    'Stop Session',
                    style: AppTextStyles.cardTitle.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.body.copyWith(color: AppColors.secondaryText),
        ),
        Text(
          value,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
      ],
    );
  }
}
