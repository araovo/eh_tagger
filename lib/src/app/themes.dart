import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppThemes {
  static ThemeData light({Color color = Colors.lightBlue}) {
    return ThemeData(
      primarySwatch: color as MaterialColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: color,
        primary: color,
        brightness: Brightness.light,
        surfaceTint: Colors.transparent,
      ),
      iconTheme: const IconThemeData(
        size: 24.0,
        fill: 0.0,
        weight: 400.0,
        grade: 0.0,
        opticalSize: 48.0,
        color: Colors.white,
        opacity: 0.8,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        selectedIconTheme: IconThemeData(
          color: color,
          opacity: 1.0,
        ),
        unselectedIconTheme: const IconThemeData(
          color: Colors.black,
          opacity: 1.0,
        ),
        unselectedLabelTextStyle: const TextStyle(
          color: Colors.black,
        ),
        selectedLabelTextStyle: const TextStyle(
          color: Colors.black,
        ),
        labelType: NavigationRailLabelType.all,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        foregroundColor: Colors.white,
        backgroundColor: color,
      ),
      appBarTheme: AppBarTheme(
        iconTheme: const IconThemeData(
          color: Colors.white,
          size: 24.0,
        ),
        color: Colors.transparent,
        centerTitle: false,
        titleTextStyle: Typography.dense2014.titleLarge?.copyWith(
          color: Colors.black,
          fontSize: 32.0,
          fontWeight: FontWeight.w500,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      scaffoldBackgroundColor: Colors.transparent,
    );
  }

  static ThemeData dark({Color color = Colors.blue}) {
    return ThemeData(
      primarySwatch: color as MaterialColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: color,
        primary: color,
        brightness: Brightness.dark,
        surfaceTint: Colors.transparent,
      ),
      iconTheme: const IconThemeData(
        size: 24.0,
        fill: 0.0,
        weight: 400.0,
        grade: 0.0,
        opticalSize: 48.0,
        color: Colors.white,
        opacity: 0.8,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        selectedIconTheme: IconThemeData(
          color: color,
          opacity: 1.0,
        ),
        unselectedIconTheme: const IconThemeData(
          color: Colors.white,
          opacity: 1.0,
        ),
        selectedLabelTextStyle: const TextStyle(
          color: Colors.white,
        ),
        unselectedLabelTextStyle: const TextStyle(
          color: Colors.white,
        ),
        labelType: NavigationRailLabelType.all,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        foregroundColor: Colors.white,
        backgroundColor: color,
      ),
      appBarTheme: AppBarTheme(
        iconTheme: const IconThemeData(
          color: Colors.white,
          size: 24.0,
        ),
        color: Colors.transparent,
        centerTitle: false,
        titleTextStyle: Typography.dense2014.titleLarge?.copyWith(
          color: Colors.white,
          fontSize: 32.0,
          fontWeight: FontWeight.w500,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      scaffoldBackgroundColor: Colors.transparent,
    );
  }
}
