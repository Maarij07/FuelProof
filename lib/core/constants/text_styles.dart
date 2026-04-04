import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Display / Hero - 32px, 700
  static TextStyle get displayHero => TextStyle(
    fontFamily: 'Inter',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryText,
    letterSpacing: -0.32,
  );

  // Section Heading - 20px, 600
  static TextStyle get sectionHeading => TextStyle(
    fontFamily: 'Inter',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryText,
    letterSpacing: -0.2,
  );

  // Card Title - 16px, 600
  static TextStyle get cardTitle => TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryText,
    letterSpacing: -0.16,
  );

  // Body - 14px, 400
  static TextStyle get body => TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.secondaryText,
    letterSpacing: -0.14,
  );

  // Caption / Label - 12px, 400
  static TextStyle get caption => TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.secondaryText,
    letterSpacing: -0.12,
  );

  // Live Data (numbers) - 64px, 700, Navy
  static TextStyle get liveDataHero => TextStyle(
    fontFamily: 'Inter',
    fontSize: 64,
    fontWeight: FontWeight.w700,
    color: AppColors.brandNavy,
    letterSpacing: -0.64,
  );

  // Greeting text - 20px, 600
  static TextStyle get greetingText => TextStyle(
    fontFamily: 'Inter',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryText,
    letterSpacing: -0.2,
  );
}
