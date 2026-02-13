import 'package:flutter/material.dart';

class AppTheme {
  // Global seed color for both themes
  static const Color seed = Color(0xFFFF751F);

  // Light Theme
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      primary: seed,
      onSurface: Color.fromARGB(255, 35, 36, 37), // Dark 
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: seed,
      foregroundColor: Colors.white,
      elevation: 0.5,
      titleTextStyle: TextStyle(
        fontSize: 23,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      hintStyle: const TextStyle(color: Color.fromARGB(255, 8,8,8)),
     
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(color: Colors.black87),
      displayMedium: TextStyle(color: Colors.black87),
      displaySmall: TextStyle(color: Colors.black87),

      headlineLarge: TextStyle(color: Colors.black87),
      headlineMedium: TextStyle(color: Colors.black87),
      headlineSmall: TextStyle(color: Colors.black87),

      titleLarge: TextStyle(color: Colors.black87),
      titleMedium: TextStyle(color: Colors.black87),
      titleSmall: TextStyle(color: Colors.black87),

      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black87),
      bodySmall: TextStyle(color: Colors.black87),

      labelLarge: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold,fontSize: 20),
      labelMedium: TextStyle(color: Colors.black87,fontSize: 15),
      labelSmall: TextStyle(color: Colors.black87,fontSize: 10),
    ),
    tabBarTheme: TabBarThemeData(
      indicatorColor: seed,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white60,
      labelStyle: TextStyle(fontWeight: FontWeight.bold),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
    ),
     cardColor: Colors.white,
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Color.fromRGBO(255, 117, 31, 1),
    ),
  );

  // Dark Theme
  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
      primary: Colors.black87,
      onSurface: const Color(0xFFF9FAFB), // Light 
    ),
    appBarTheme: AppBarTheme(
      titleTextStyle: TextStyle(
        fontSize: 23,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    tabBarTheme: TabBarThemeData(
      indicatorColor: Colors.white,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white60,
      labelStyle: TextStyle(fontWeight: FontWeight.bold),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color.fromARGB(255, 212, 215, 221), // Dark gray fill
      hintStyle: const TextStyle(color: Color.fromARGB(255, 8, 8, 8)),
      
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
     cardColor: const Color(0xFF1F2937),
    textTheme: TextTheme(
      displayLarge: TextStyle(color: Colors.white),
      displayMedium: TextStyle(color: Colors.white),
      displaySmall: TextStyle(color: Colors.white),

      headlineLarge: TextStyle(color: Colors.white),
      headlineMedium: TextStyle(color: Colors.white),
      headlineSmall: TextStyle(color: Colors.white),

      titleLarge: TextStyle(color: Colors.white),
      titleMedium: TextStyle(color: Colors.white),
      titleSmall: TextStyle(color: Colors.white),

      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
      bodySmall: TextStyle(color: Colors.white),

      labelLarge: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
      labelMedium: TextStyle(color: Colors.white, fontSize: 15),
      labelSmall: TextStyle(color: Colors.white, fontSize: 10),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          return Colors.black; // <-- teks hitam
        }),
        textStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),

        backgroundColor: const WidgetStatePropertyAll(
          Color.fromARGB(255, 248, 246, 246),
        ),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return Colors.white.withValues(alpha: 0.05);
          }
          if (states.contains(WidgetState.pressed)) {
            return Colors.white.withValues(alpha: 0.10);
          }
          return null;
        }),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.white,
    ),
  
  );
}
