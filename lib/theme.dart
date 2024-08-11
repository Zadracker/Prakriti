import 'package:flutter/material.dart';

class AppTheme {
  static const Color darkPrimaryColor = Colors.black;
  static const Color darkSecondaryColor = Colors.grey;
  static const Color darkAccentColor = Colors.green;
  static const Color darkHeadingColor = Colors.white;
  static const Color darkBodyColor = Colors.white70;

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: darkPrimaryColor,
    hintColor: const Color(0xFF4CAF50),
    scaffoldBackgroundColor: darkPrimaryColor,
    appBarTheme: const AppBarTheme(
      color: darkPrimaryColor,
      titleTextStyle: TextStyle(color: darkHeadingColor),
      iconTheme: IconThemeData(color: darkHeadingColor),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkPrimaryColor,
      selectedItemColor: darkAccentColor,
      unselectedItemColor: darkSecondaryColor,
    ),
    tabBarTheme: const TabBarTheme(
      labelColor: darkAccentColor,
      unselectedLabelColor: darkSecondaryColor,
      indicator: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: darkAccentColor,
          ),
        ),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: darkHeadingColor),
      bodyLarge: TextStyle(color: darkBodyColor),
      labelLarge: TextStyle(color: darkHeadingColor),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: darkHeadingColor, backgroundColor: darkAccentColor,
      ),
    ),
  );
}
