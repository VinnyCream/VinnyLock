import 'package:flutter/material.dart';
import 'package:vinnylock/app/theme/tokens.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(Palette.light, Brightness.light);
  static ThemeData dark() => _build(Palette.dark, Brightness.dark);

  static ThemeData _build(Palette p, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: p.brand,
      onPrimary: p.onBrand,
      primaryContainer: p.brandContainer,
      onPrimaryContainer: p.onBrandContainer,
      secondary: p.brand,
      onSecondary: p.onBrand,
      error: p.danger,
      onError: p.onDanger,
      surface: p.surface,
      onSurface: p.onSurface,
      onSurfaceVariant: p.muted,
      surfaceContainerHighest: p.tone,
      outline: p.muted,
      outlineVariant: p.tone,
    );

    final text = TextTheme(
      titleLarge: const TextStyle(fontSize: Type.title, fontWeight: Type.strong, height: 1.3),
      titleMedium: const TextStyle(fontSize: Type.body, fontWeight: Type.strong, height: 1.4),
      bodyLarge: const TextStyle(fontSize: Type.body, fontWeight: Type.regular, height: 1.5),
      bodyMedium: const TextStyle(fontSize: Type.label, fontWeight: Type.regular, height: 1.5),
      labelLarge: const TextStyle(fontSize: Type.label, fontWeight: Type.strong, height: 1.4),
      bodySmall: const TextStyle(fontSize: Type.caption, fontWeight: Type.regular, height: 1.4),
    ).apply(bodyColor: p.onSurface, displayColor: p.onSurface);

    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(Corner.medium));

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      textTheme: text,
      extensions: <ThemeExtension<dynamic>>[AppColors(p)],
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      dividerTheme: DividerThemeData(color: p.tone, space: 1, thickness: 1),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: shape,
      ),
      listTileTheme: ListTileThemeData(
        minVerticalPadding: Space.sm,
        contentPadding: const EdgeInsets.symmetric(horizontal: Space.lg),
        iconColor: p.muted,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.tone,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Corner.medium),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Corner.medium),
          borderSide: BorderSide(color: p.brand, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.md),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(Layout.minTarget, Layout.minTarget),
          shape: shape,
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(Layout.minTarget, Layout.minTarget),
          shape: shape,
          side: BorderSide(color: p.muted),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(Layout.minTarget, Layout.minTarget),
          shape: shape,
          textStyle: text.labelLarge,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> s) {
          return s.contains(WidgetState.selected) ? p.onBrand : p.muted;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> s) {
          return s.contains(WidgetState.selected) ? p.brand : p.tone;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> s) {
          return s.contains(WidgetState.selected) ? p.brand : p.muted;
        }),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        indicatorColor: p.brandContainer,
        labelTextStyle: WidgetStatePropertyAll<TextStyle>(text.bodySmall!),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: p.surface,
        indicatorColor: p.brandContainer,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.onSurface,
        contentTextStyle: text.bodyMedium!.copyWith(color: p.background),
      ),
    );
  }
}
