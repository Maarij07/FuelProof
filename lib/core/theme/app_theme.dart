import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../constants/spacing.dart';
import '../constants/text_styles.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.accentTeal,
      scaffoldBackgroundColor: AppColors.primaryBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.sectionHeading,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(
          color: AppColors.primaryText,
          size: AppDimensions.iconNavigationSize,
        ),
      ),
      // Card theme - clean, minimal with soft shadow
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.card),
        ),
        margin: EdgeInsets.zero,
        shadowColor: AppColors.primaryText.withValues(alpha: 0.06),
      ),
      // Elevated button - teal accent with subtle shadow
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentTeal,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.button),
          ),
          textStyle: AppTextStyles.cardTitle,
          shadowColor: AppColors.accentTeal.withValues(alpha: 0.2),
        ),
      ),
      // Input fields - clean, minimal
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.input),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.input),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.input),
          borderSide: const BorderSide(color: AppColors.accentTeal, width: 2),
        ),
        contentPadding: EdgeInsets.all(AppSpacing.md),
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.tertiaryText),
      ),
      // Text theme - clean hierarchy
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayHero,
        headlineSmall: AppTextStyles.sectionHeading,
        titleMedium: AppTextStyles.cardTitle,
        bodyMedium: AppTextStyles.body,
        labelSmall: AppTextStyles.caption,
      ),
      // Divider - subtle
      dividerColor: const Color(0xFFD9D9D9),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFD9D9D9),
        thickness: 1,
        space: 0,
      ),
      // Bottom navigation - clean theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        elevation: 0,
        selectedItemColor: AppColors.accentTeal,
        unselectedItemColor: AppColors.tertiaryText,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
    );
  }

  static ThemeData get darkTheme {
    const darkSurface = Color(0xFF111827);
    const darkBg = Color(0xFF0B1220);
    const darkCard = Color(0xFF182334);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.accentTeal,
      scaffoldBackgroundColor: darkBg,
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.sectionHeading.copyWith(
          color: AppColors.white,
        ),
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(
          color: AppColors.white,
          size: AppDimensions.iconNavigationSize,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.card),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentTeal,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.button),
          ),
          textStyle: AppTextStyles.cardTitle,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.input),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.input),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.input),
          borderSide: const BorderSide(color: AppColors.accentTeal, width: 2),
        ),
        contentPadding: EdgeInsets.all(AppSpacing.md),
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.softGray),
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayHero.copyWith(
          color: AppColors.white,
        ),
        headlineSmall: AppTextStyles.sectionHeading.copyWith(
          color: AppColors.white,
        ),
        titleMedium: AppTextStyles.cardTitle.copyWith(color: AppColors.white),
        bodyMedium: AppTextStyles.body.copyWith(color: AppColors.offWhite),
        labelSmall: AppTextStyles.caption.copyWith(color: AppColors.softGray),
      ),
      dividerColor: const Color(0xFF2A364A),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2A364A),
        thickness: 1,
        space: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        indicatorColor: AppColors.accentTeal.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? AppColors.accentTeal : AppColors.softGray,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
      ),
    );
  }
}
