import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFF1FAE57);
  static const Color primaryDark = Color(0xFF128A43);
  static const Color primarySoft = Color(0xFFEAF9F0);
  static const Color background = Color(0xFFF4F8F5);
  static const Color card = Colors.white;
  static const Color textMain = Color(0xFF191F28);
  static const Color textSub = Color(0xFF6B7684);
  static const Color border = Color(0xFFE3EAE5);
}

class AppFontSettings {
  static final ValueNotifier<double> scale = ValueNotifier<double>(1.1);
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.primary,
        surface: AppColors.card,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    final roundedTextTheme = GoogleFonts.notoSansKrTextTheme(
      base.textTheme,
    ).apply(
      bodyColor: AppColors.textMain,
      displayColor: AppColors.textMain,
    );

    return base.copyWith(
      textTheme: roundedTextTheme.copyWith(
        bodyLarge: roundedTextTheme.bodyLarge?.copyWith(
          fontSize: 21,
          fontWeight: FontWeight.w800,
        ),
        bodyMedium: roundedTextTheme.bodyMedium?.copyWith(
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
        bodySmall: roundedTextTheme.bodySmall?.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: roundedTextTheme.titleLarge?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
        titleMedium: roundedTextTheme.titleMedium?.copyWith(
          fontSize: 21,
          fontWeight: FontWeight.w900,
        ),
        titleSmall: roundedTextTheme.titleSmall?.copyWith(
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
        labelLarge: roundedTextTheme.labelLarge?.copyWith(
          fontSize: 19,
          fontWeight: FontWeight.w900,
        ),
        labelMedium: roundedTextTheme.labelMedium?.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
        labelSmall: roundedTextTheme.labelSmall?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      primaryTextTheme: roundedTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.notoSansKr(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          color: AppColors.textMain,
        ),
        iconTheme: const IconThemeData(color: AppColors.textMain, size: 28),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        hintStyle: const TextStyle(
          fontSize: 20,
          color: AppColors.textSub,
          fontWeight: FontWeight.w700,
        ),
        labelStyle: const TextStyle(
          fontSize: 19,
          color: AppColors.textSub,
          fontWeight: FontWeight.w800,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 58),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          side: const BorderSide(color: AppColors.border),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textMain,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSub,
        selectedLabelStyle:
            TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        unselectedLabelStyle:
            TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
