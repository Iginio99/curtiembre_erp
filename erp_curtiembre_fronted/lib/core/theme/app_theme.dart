import 'package:erp_curtiembre_fronted/core/theme/app_colors.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_radius.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData light() {
    final baseTextTheme = ThemeData.light().textTheme.apply(
      fontFamily: 'Segoe UI',
    );

    return FlexThemeData.light(
      colors: const FlexSchemeColor(
        primary: AppColors.primary,
        primaryContainer: AppColors.primarySoft,
        secondary: AppColors.primaryAlt,
        secondaryContainer: AppColors.card,
        tertiary: AppColors.warning,
        tertiaryContainer: AppColors.warningSoft,
        appBarColor: AppColors.surface,
        error: AppColors.error,
      ),
      scaffoldBackground: AppColors.background,
      surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
      blendLevel: 8,
      subThemesData: _subThemesData(isDark: false),
      useMaterial3: true,
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      textTheme: baseTextTheme,
      primaryTextTheme: baseTextTheme,
    ).copyWith(
      colorScheme: _lightColorScheme,
      textTheme: _buildTextTheme(baseTextTheme, _lightColorScheme),
      appBarTheme: _buildAppBarTheme(_lightColorScheme, baseTextTheme),
      cardTheme: _buildCardTheme(_lightColorScheme),
      chipTheme: _buildChipTheme(_lightColorScheme, false),
      inputDecorationTheme: _buildInputTheme(_lightColorScheme),
      filledButtonTheme: _buildFilledButtonTheme(_lightColorScheme),
      outlinedButtonTheme: _buildOutlinedButtonTheme(_lightColorScheme),
      dataTableTheme: _buildDataTableTheme(_lightColorScheme),
      dividerTheme: DividerThemeData(color: _lightColorScheme.outlineVariant),
      extensions: const [],
    );
  }

  static ThemeData dark() {
    final baseTextTheme = ThemeData.dark().textTheme.apply(
      fontFamily: 'Segoe UI',
    );

    return FlexThemeData.dark(
      colors: const FlexSchemeColor(
        primary: AppDarkColors.primary,
        primaryContainer: AppDarkColors.primarySoft,
        secondary: AppDarkColors.primaryAlt,
        secondaryContainer: AppDarkColors.card,
        tertiary: AppDarkColors.warning,
        tertiaryContainer: AppDarkColors.warningSoft,
        appBarColor: AppDarkColors.surface,
        error: AppDarkColors.error,
      ),
      scaffoldBackground: AppDarkColors.background,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 14,
      subThemesData: _subThemesData(isDark: true),
      useMaterial3: true,
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      textTheme: baseTextTheme,
      primaryTextTheme: baseTextTheme,
    ).copyWith(
      colorScheme: _darkColorScheme,
      textTheme: _buildTextTheme(baseTextTheme, _darkColorScheme),
      appBarTheme: _buildAppBarTheme(_darkColorScheme, baseTextTheme),
      cardTheme: _buildCardTheme(_darkColorScheme),
      chipTheme: _buildChipTheme(_darkColorScheme, true),
      inputDecorationTheme: _buildInputTheme(_darkColorScheme),
      filledButtonTheme: _buildFilledButtonTheme(_darkColorScheme),
      outlinedButtonTheme: _buildOutlinedButtonTheme(_darkColorScheme),
      dataTableTheme: _buildDataTableTheme(_darkColorScheme),
      dividerTheme: DividerThemeData(color: _darkColorScheme.outlineVariant),
      extensions: const [],
    );
  }

  static FlexSubThemesData _subThemesData({required bool isDark}) {
    return FlexSubThemesData(
      defaultRadius: AppRadius.card,
      // Avoid invalid negative-width constraints in generated Material 3 button
      // subthemes when the theme toggles between light and dark modes.
      buttonMinSize: const Size(64, 48),
      elevatedButtonRadius: AppRadius.button,
      filledButtonRadius: AppRadius.button,
      outlinedButtonRadius: AppRadius.button,
      inputDecoratorRadius: AppRadius.input,
      inputDecoratorBorderType: FlexInputBorderType.outline,
      cardRadius: AppRadius.card,
      dialogRadius: AppRadius.dialog,
      blendOnLevel: isDark ? 20 : 8,
      blendOnColors: false,
      appBarScrolledUnderElevation: 0,
      interactionEffects: true,
    );
  }

  static TextTheme _buildTextTheme(TextTheme base, ColorScheme colorScheme) {
    return base.copyWith(
      displaySmall: base.displaySmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        height: 1.45,
        color: colorScheme.onSurface,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        height: 1.45,
        color: colorScheme.onSurface,
      ),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    );
  }

  static AppBarTheme _buildAppBarTheme(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  static CardThemeData _buildCardTheme(ColorScheme colorScheme) {
    return CardThemeData(
      color: colorScheme.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
    );
  }

  static ChipThemeData _buildChipTheme(ColorScheme colorScheme, bool isDark) {
    return ChipThemeData(
      backgroundColor: colorScheme.surfaceContainerHighest,
      disabledColor: colorScheme.surfaceContainerHighest,
      selectedColor: colorScheme.primaryContainer,
      secondarySelectedColor: colorScheme.primaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      labelStyle: TextStyle(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      secondaryLabelStyle: TextStyle(
        color: isDark ? AppDarkColors.text : AppColors.text,
        fontWeight: FontWeight.w700,
      ),
      brightness: isDark ? Brightness.dark : Brightness.light,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.badge),
      ),
      side: BorderSide.none,
    );
  }

  static InputDecorationTheme _buildInputTheme(ColorScheme colors) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.input),
      borderSide: BorderSide(color: colors.outlineVariant),
    );
    return InputDecorationTheme(
      filled: true,
      fillColor: colors.surfaceContainerLowest,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: colors.primary, width: 1.5),
      ),
      errorBorder: border.copyWith(borderSide: BorderSide(color: colors.error)),
    );
  }

  static FilledButtonThemeData _buildFilledButtonTheme(ColorScheme colors) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 42),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme(ColorScheme colors) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 42),
        foregroundColor: colors.onSurface,
        side: BorderSide(color: colors.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  static DataTableThemeData _buildDataTableTheme(ColorScheme colors) {
    return DataTableThemeData(
      headingRowColor: WidgetStatePropertyAll(
        colors.brightness == Brightness.dark
            ? const Color(0xFF3B3B3D)
            : const Color(0xFF3B3B3D),
      ),
      headingTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 12,
        letterSpacing: .45,
      ),
      dataTextStyle: TextStyle(color: colors.onSurface, fontSize: 13),
      dividerThickness: 1,
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
    );
  }

  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.primarySoft,
    onPrimaryContainer: AppColors.text,
    secondary: AppColors.primaryAlt,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.card,
    onSecondaryContainer: AppColors.text,
    tertiary: AppColors.warning,
    onTertiary: AppColors.text,
    tertiaryContainer: AppColors.warningSoft,
    onTertiaryContainer: AppColors.text,
    error: AppColors.error,
    onError: Colors.white,
    errorContainer: AppColors.errorSoft,
    onErrorContainer: AppColors.error,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    onSurfaceVariant: AppColors.textSecondary,
    outline: Color(0xFFCFCFD3),
    outlineVariant: Color(0xFFE3E3E6),
    shadow: Color(0x14000000),
    scrim: Color(0x33000000),
    inverseSurface: AppColors.text,
    onInverseSurface: AppColors.surface,
    inversePrimary: AppDarkColors.primary,
    surfaceTint: AppColors.primary,
  );

  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppDarkColors.primary,
    onPrimary: AppColors.text,
    primaryContainer: AppDarkColors.primarySoft,
    onPrimaryContainer: AppColors.text,
    secondary: AppDarkColors.primaryAlt,
    onSecondary: AppColors.text,
    secondaryContainer: AppDarkColors.card,
    onSecondaryContainer: AppDarkColors.text,
    tertiary: AppDarkColors.warning,
    onTertiary: AppColors.text,
    tertiaryContainer: AppDarkColors.warningSoft,
    onTertiaryContainer: AppDarkColors.text,
    error: AppDarkColors.error,
    onError: AppColors.text,
    errorContainer: AppDarkColors.errorSoft,
    onErrorContainer: AppDarkColors.error,
    surface: AppDarkColors.surface,
    onSurface: AppDarkColors.text,
    onSurfaceVariant: AppDarkColors.textSecondary,
    outline: Color(0xFF525257),
    outlineVariant: Color(0xFF38383C),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: AppDarkColors.text,
    onInverseSurface: AppDarkColors.surface,
    inversePrimary: AppColors.primary,
    surfaceTint: AppDarkColors.primary,
  );
}
