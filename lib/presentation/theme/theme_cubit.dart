import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  final SharedPreferences sharedPreferences;

  ThemeCubit({required this.sharedPreferences})
    : super(_initialTheme(sharedPreferences));

  static ThemeMode _initialTheme(SharedPreferences prefs) {
    final saved = prefs.getString(AppConstants.prefThemeMode);
    if (saved == 'light') return ThemeMode.light;
    return ThemeMode.dark; // Default to Obsidian Logistics Dark
  }

  void toggleTheme() {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    sharedPreferences.setString(
      AppConstants.prefThemeMode,
      next == ThemeMode.light ? 'light' : 'dark',
    );
    emit(next);
  }

  void setTheme(ThemeMode mode) {
    sharedPreferences.setString(
      AppConstants.prefThemeMode,
      mode == ThemeMode.light ? 'light' : 'dark',
    );
    emit(mode);
  }
}
