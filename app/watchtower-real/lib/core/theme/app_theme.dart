import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tokens.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: colorBgBase,
      colorScheme: const ColorScheme.dark(
        primary: colorBrand,
        secondary: colorBrandCyan,
        surface: colorBgSurface,
        onPrimary: colorTextPrimary,
        onSecondary: colorTextPrimary,
        onSurface: colorTextPrimary,
      ),
      // Bottom nav transparent sur le feed
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: colorTextPrimary,
        unselectedItemColor: colorTextSecondary,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        unselectedLabelStyle: TextStyle(fontSize: 10),
        elevation: 0,
      ),
      // AppBar transparent
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      // Pas de glow sur les scrollviews
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
    );
  }

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: colorBgLight,
      colorScheme: const ColorScheme.light(
        primary: colorBrand,
        secondary: colorBrandCyan,
        surface: colorBgLightSurface,
      ),
    );
  }
}
