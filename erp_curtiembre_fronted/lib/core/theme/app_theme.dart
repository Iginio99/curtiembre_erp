import 'package:erp_curtiembre_fronted/core/theme/app_colors.dart';
import 'package:erp_curtiembre_fronted/core/theme/app_radius.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData light() {
    final baseTextTheme = ThemeData.light().textTheme.apply(
      fontFamily: 'Segoe UI',
    );

    final textTheme = _buildTextTheme(baseTextTheme, _lightColorScheme);

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
      blendLevel: 6,
      subThemesData: _subThemesData(isDark: false),
      useMaterial3: true,
      visualDensity: VisualDensity.compact,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
    ).copyWith(
      colorScheme: _lightColorScheme,
      textTheme: textTheme,
      appBarTheme: _buildAppBarTheme(_lightColorScheme, textTheme),
      cardTheme: _buildCardTheme(_lightColorScheme),
      chipTheme: _buildChipTheme(_lightColorScheme, false),
      inputDecorationTheme: _buildInputTheme(_lightColorScheme),
      filledButtonTheme: _buildFilledButtonTheme(_lightColorScheme),
      outlinedButtonTheme: _buildOutlinedButtonTheme(_lightColorScheme),
      textButtonTheme: _buildTextButtonTheme(_lightColorScheme),
      iconButtonTheme: _buildIconButtonTheme(_lightColorScheme),
      dataTableTheme: _buildDataTableTheme(_lightColorScheme),
      dividerTheme: DividerThemeData(
        color: _lightColorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData dark() {
    final baseTextTheme = ThemeData.dark().textTheme.apply(
      fontFamily: 'Segoe UI',
    );

    final textTheme = _buildTextTheme(baseTextTheme, _darkColorScheme);

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
      blendLevel: 10,
      subThemesData: _subThemesData(isDark: true),
      useMaterial3: true,
      visualDensity: VisualDensity.compact,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
    ).copyWith(
      colorScheme: _darkColorScheme,
      textTheme: textTheme,
      appBarTheme: _buildAppBarTheme(_darkColorScheme, textTheme),
      cardTheme: _buildCardTheme(_darkColorScheme),
      chipTheme: _buildChipTheme(_darkColorScheme, true),
      inputDecorationTheme: _buildInputTheme(_darkColorScheme),
      filledButtonTheme: _buildFilledButtonTheme(_darkColorScheme),
      outlinedButtonTheme: _buildOutlinedButtonTheme(_darkColorScheme),
      textButtonTheme: _buildTextButtonTheme(_darkColorScheme),
      iconButtonTheme: _buildIconButtonTheme(_darkColorScheme),
      dataTableTheme: _buildDataTableTheme(_darkColorScheme),
      dividerTheme: DividerThemeData(
        color: _darkColorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static FlexSubThemesData _subThemesData({required bool isDark}) {
    return FlexSubThemesData(
      defaultRadius: AppRadius.card,
      buttonMinSize: const Size(64, 38),
      elevatedButtonRadius: AppRadius.button,
      filledButtonRadius: AppRadius.button,
      outlinedButtonRadius: AppRadius.button,
      inputDecoratorRadius: AppRadius.input,
      inputDecoratorBorderType: FlexInputBorderType.outline,
      cardRadius: AppRadius.card,
      dialogRadius: AppRadius.dialog,
      blendOnLevel: isDark ? 16 : 6,
      blendOnColors: false,
      appBarScrolledUnderElevation: 0,
      interactionEffects: true,
    );
  }

  static TextTheme _buildTextTheme(TextTheme base, ColorScheme colors) {
    return base.copyWith(
      displaySmall: base.displaySmall?.copyWith(
        fontSize: 24,
        height: 1.20,
        fontWeight: FontWeight.w700,
        color: colors.onSurface,
      ),

      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 20,
        height: 1.20,
        fontWeight: FontWeight.w700,
        color: colors.onSurface,
      ),

      titleLarge: base.titleLarge?.copyWith(
        fontSize: 18,
        height: 1.20,
        fontWeight: FontWeight.w700,
        color: colors.onSurface,
      ),

      titleMedium: base.titleMedium?.copyWith(
        fontSize: 15,
        height: 1.20,
        fontWeight: FontWeight.w700,
        color: colors.onSurface,
      ),

      titleSmall: base.titleSmall?.copyWith(
        fontSize: 13,
        height: 1.20,
        fontWeight: FontWeight.w600,
        color: colors.onSurface,
      ),

      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 14,
        height: 1.30,
        color: colors.onSurface,
      ),

      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 13,
        height: 1.28,
        color: colors.onSurface,
      ),

      bodySmall: base.bodySmall?.copyWith(
        fontSize: 11,
        height: 1.22,
        color: colors.onSurfaceVariant,
      ),

      labelLarge: base.labelLarge?.copyWith(
        fontSize: 12.5,
        height: 1.15,
        fontWeight: FontWeight.w700,
      ),

      labelMedium: base.labelMedium?.copyWith(
        fontSize: 11.5,
        height: 1.15,
        fontWeight: FontWeight.w600,
      ),

      labelSmall: base.labelSmall?.copyWith(
        fontSize: 10.5,
        height: 1.15,
        fontWeight: FontWeight.w600,
        letterSpacing: .1,
      ),
    );
  }

  static AppBarTheme _buildAppBarTheme(
    ColorScheme colors,
    TextTheme textTheme,
  ) {
    return AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: colors.surface,
      foregroundColor: colors.onSurface,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 54,
      titleSpacing: 18,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: colors.onSurface,
      ),
    );
  }

  static CardThemeData _buildCardTheme(ColorScheme colors) {
    return CardThemeData(
      color: colors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
    );
  }

  static ChipThemeData _buildChipTheme(ColorScheme colors, bool isDark) {
    return ChipThemeData(
      backgroundColor: colors.surfaceContainerHighest,
      disabledColor: colors.surfaceContainerHighest,
      selectedColor: colors.primaryContainer,
      secondarySelectedColor: colors.primaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      labelPadding: const EdgeInsets.symmetric(horizontal: 2),
      labelStyle: TextStyle(
        fontSize: 11.5,
        color: colors.onSurface,
        fontWeight: FontWeight.w600,
      ),
      secondaryLabelStyle: TextStyle(
        fontSize: 11.5,
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

      contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),

      labelStyle: TextStyle(fontSize: 11.5, color: colors.onSurfaceVariant),

      floatingLabelStyle: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w500,
        color: colors.primary,
      ),

      hintStyle: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),

      helperStyle: TextStyle(fontSize: 10, color: colors.onSurfaceVariant),

      errorStyle: TextStyle(fontSize: 10, color: colors.error),

      border: border,
      enabledBorder: border,

      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: colors.primary, width: 1.4),
      ),

      errorBorder: border.copyWith(borderSide: BorderSide(color: colors.error)),

      focusedErrorBorder: border.copyWith(
        borderSide: BorderSide(color: colors.error, width: 1.4),
      ),
    );
  }

  static FilledButtonThemeData _buildFilledButtonTheme(ColorScheme colors) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 38),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme(ColorScheme colors) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 38),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        foregroundColor: colors.onSurface,
        side: BorderSide(color: colors.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
    );
  }

  static TextButtonThemeData _buildTextButtonTheme(ColorScheme colors) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(40, 34),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        foregroundColor: colors.primary,
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  static IconButtonThemeData _buildIconButtonTheme(ColorScheme colors) {
    return IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(34, 34),
        maximumSize: const Size(38, 38),
        padding: const EdgeInsets.all(6),
        foregroundColor: colors.onSurfaceVariant,
      ),
    );
  }

  static DataTableThemeData _buildDataTableTheme(ColorScheme colors) {
    return DataTableThemeData(
      headingRowColor: WidgetStatePropertyAll(colors.surfaceContainerHighest),

      dataRowColor: WidgetStatePropertyAll(colors.surface),

      headingTextStyle: TextStyle(
        color: colors.onSurfaceVariant,
        fontWeight: FontWeight.w700,
        fontSize: 10.5,
        letterSpacing: .12,
      ),

      dataTextStyle: TextStyle(color: colors.onSurface, fontSize: 12.5),

      headingRowHeight: 38,
      dataRowMinHeight: 40,
      dataRowMaxHeight: 46,

      horizontalMargin: 12,
      columnSpacing: 16,
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

    outline: Color(0xFFCDD0D5),
    outlineVariant: Color(0xFFE4E6E9),

    shadow: Color(0x12000000),
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
    onPrimaryContainer: AppDarkColors.text,

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

    outline: Color(0xFF55585F),
    outlineVariant: Color(0xFF383A40),

    shadow: Colors.black,
    scrim: Colors.black,

    inverseSurface: AppDarkColors.text,
    onInverseSurface: AppDarkColors.surface,

    inversePrimary: AppColors.primary,

    surfaceTint: AppDarkColors.primary,
  );
}
