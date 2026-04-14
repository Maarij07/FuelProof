import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../constants/spacing.dart';
import '../constants/text_styles.dart';

class AppTheme {
  static const Color _brandPrimary = Color(0xFF0CA7A0);

  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: _brandPrimary,
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF1E3154),
    onSecondary: Color(0xFFFFFFFF),
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFBF8),
    onSurface: Color(0xFF111111),
    primaryContainer: Color(0xFFC8F0EC),
    onPrimaryContainer: Color(0xFF003733),
    secondaryContainer: Color(0xFFE8EEF5),
    onSecondaryContainer: Color(0xFF0E1D37),
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF601410),
    surfaceContainerHighest: Color(0xFFF5F5F5),
    onSurfaceVariant: Color(0xFF767676),
    outline: Color(0xFFA0A0A0),
    outlineVariant: Color(0xFFD9D9D9),
    shadow: Color(0xFF000000),
    inverseSurface: Color(0xFF2F2F2F),
    onInverseSurface: Color(0xFFF4F4F4),
    inversePrimary: Color(0xFF9BE4DC),
    surfaceTint: _brandPrimary,
  );

  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF66D5CB),
    onPrimary: Color(0xFF003733),
    secondary: Color(0xFF9FB7DA),
    onSecondary: Color(0xFF0E1D37),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    surface: Color(0xFF0B1220),
    onSurface: Color(0xFFF8FAFC),
    primaryContainer: Color(0xFF123D3A),
    onPrimaryContainer: Color(0xFFC8F0EC),
    secondaryContainer: Color(0xFF1A2536),
    onSecondaryContainer: Color(0xFFD8E3F3),
    errorContainer: Color(0xFF3A1A1A),
    onErrorContainer: Color(0xFFFFDAD6),
    surfaceContainerHighest: Color(0xFF1E293B),
    onSurfaceVariant: Color(0xFFCBD5E1),
    outline: Color(0xFF94A3B8),
    outlineVariant: Color(0xFF2A364A),
    shadow: Color(0xFF000000),
    inverseSurface: Color(0xFFE6EEF9),
    onInverseSurface: Color(0xFF152033),
    inversePrimary: _brandPrimary,
    surfaceTint: Color(0xFF66D5CB),
  );

  static ThemeData get lightTheme {
    final colorScheme = _lightColorScheme;
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.sectionHeading.copyWith(
          color: colorScheme.onSurface,
        ),
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(
          color: colorScheme.onSurface,
          size: AppDimensions.iconNavigationSize,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.card),
        ),
        margin: EdgeInsets.zero,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.08),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.button),
          ),
          textStyle: AppTextStyles.cardTitle,
          shadowColor: colorScheme.primary.withValues(alpha: 0.22),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
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
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: EdgeInsets.all(AppSpacing.md),
        hintStyle: AppTextStyles.body.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayHero.copyWith(
          color: colorScheme.onSurface,
        ),
        headlineSmall: AppTextStyles.sectionHeading.copyWith(
          color: colorScheme.onSurface,
        ),
        titleMedium: AppTextStyles.cardTitle.copyWith(
          color: colorScheme.onSurface,
        ),
        bodyMedium: AppTextStyles.body.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        labelSmall: AppTextStyles.caption.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      dividerColor: colorScheme.outlineVariant,
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.secondaryContainer,
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = _darkColorScheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.sectionHeading.copyWith(
          color: colorScheme.onSurface,
        ),
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(
          color: colorScheme.onSurface,
          size: AppDimensions.iconNavigationSize,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.card),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
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
        fillColor: colorScheme.surfaceContainerHighest,
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
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: EdgeInsets.all(AppSpacing.md),
        hintStyle: AppTextStyles.body.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayHero.copyWith(
          color: colorScheme.onSurface,
        ),
        headlineSmall: AppTextStyles.sectionHeading.copyWith(
          color: colorScheme.onSurface,
        ),
        titleMedium: AppTextStyles.cardTitle.copyWith(
          color: colorScheme.onSurface,
        ),
        bodyMedium: AppTextStyles.body.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        labelSmall: AppTextStyles.caption.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      dividerColor: colorScheme.outlineVariant,
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.secondaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
