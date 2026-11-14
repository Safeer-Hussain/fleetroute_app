import 'package:flutter/material.dart';

class AppTheme {
  static const Color obsidianPrimary = Color(0xFF10B981);
  static const Color obsidianSecondary = Color(0xFF0EA5E9);
  static const Color obsidianTertiary = Color(0xFFF59E0B);
  static const Color obsidianError = Color(0xFFEF4444);
  static const Color obsidianSurface = Color(0xFF0B132B);
  static const Color obsidianContainer = Color(0xFF16223F);
  static const Color obsidianContainerHighest = Color(0xFF1E2D56);
  static const Color obsidianOnSurface = Color(0xFFF1F5F9);
  static const Color obsidianOnSurfaceVariant = Color(0xFF94A3B8);
  static const Color obsidianOutline = Color(0xFF334155);
  static const Color obsidianOutlineVariant = Color(0xFF1E293B);

  static const Color lightPrimary = Color(0xFF059669);
  static const Color lightSecondary = Color(0xFF0284C7);
  static const Color lightTertiary = Color(0xFFD97706);
  static const Color lightError = Color(0xFFDC2626);
  static const Color lightSurface = Color(0xFFF8FAFC);
  static const Color lightContainer = Color(0xFFEDF2F7);
  static const Color lightContainerHighest = Color(0xFFE2E8F0);
  static const Color lightOnSurface = Color(0xFF0F172A);
  static const Color lightOnSurfaceVariant = Color(0xFF475569);
  static const Color lightOutline = Color(0xFFCBD5E1);
  static const Color lightOutlineVariant = Color(0xFFE2E8F0);

  static ThemeData get darkTheme {
    final colorScheme = const ColorScheme.dark(
      primary: obsidianPrimary,
      onPrimary: Color(0xFF022C22),
      secondary: obsidianSecondary,
      onSecondary: Color(0xFF082F49),
      tertiary: obsidianTertiary,
      onTertiary: Color(0xFF451A03),
      error: obsidianError,
      onError: Color(0xFF450A0A),
      surface: obsidianSurface,
      onSurface: obsidianOnSurface,
      onSurfaceVariant: obsidianOnSurfaceVariant,
      outline: obsidianOutline,
      outlineVariant: obsidianOutlineVariant,
      surfaceContainer: obsidianContainer,
      surfaceContainerHighest: obsidianContainerHighest,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surfaceContainer,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
      ),
    );
  }

  static ThemeData get lightTheme {
    final colorScheme = const ColorScheme.light(
      primary: lightPrimary,
      onPrimary: Color(0xFFFFFFFF),
      secondary: lightSecondary,
      onSecondary: Color(0xFFFFFFFF),
      tertiary: lightTertiary,
      onTertiary: Color(0xFFFFFFFF),
      error: lightError,
      onError: Color(0xFFFFFFFF),
      surface: lightSurface,
      onSurface: lightOnSurface,
      onSurfaceVariant: lightOnSurfaceVariant,
      outline: lightOutline,
      outlineVariant: lightOutlineVariant,
      surfaceContainer: lightContainer,
      surfaceContainerHighest: lightContainerHighest,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surfaceContainer,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
      ),
    );
  }
}
