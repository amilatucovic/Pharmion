import 'package:flutter/material.dart';

class AppColors {
  static const kTeal       = Color(0xFF03989E);
  static const kTealLight  = Color(0xFFE0F7F4);
  static const kTealDark   = Color(0xFF026E73);
  static const kBg         = Color(0xFFF4F7FA);
  static const kTextDark   = Color(0xFF1E293B);
  static const kTextMid    = Color(0xFF64748B);
  static const kTextLight  = Color(0xFF94A3B8);
  static const kBorder     = Color(0xFFE2E8F0);
  static const kWhite      = Colors.white;
  static const kError      = Color(0xFFDC2626);
  static const kErrorLight = Color(0xFFFEE2E2);
  static const kSuccess    = Color(0xFF059669);
  static const kWarning    = Color(0xFFD97706);
  static const kSurface    = Color(0xFFF8FAFC);
}

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.kTeal,
      primary: AppColors.kTeal,
      surface: AppColors.kBg,
      error: AppColors.kError,
    ),
    scaffoldBackgroundColor: AppColors.kBg,
    fontFamily: 'Nunito',

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.kWhite,
      foregroundColor: AppColors.kTextDark,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.kTextDark,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: IconThemeData(color: AppColors.kTextDark),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.kTeal,
        foregroundColor: AppColors.kWhite,
        elevation: 0,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.kTeal,
        side: const BorderSide(color: AppColors.kTeal),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.kWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.kTeal, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.kError),
      ),
      hintStyle: const TextStyle(color: AppColors.kTextLight, fontSize: 14),
      labelStyle: const TextStyle(color: AppColors.kTextMid, fontSize: 14),
    ),

    cardTheme: CardThemeData(
      color: AppColors.kWhite,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.kBorder),
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.kBorder,
      thickness: 1,
      space: 1,
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.kWhite,
      selectedItemColor: AppColors.kTeal,
      unselectedItemColor: AppColors.kTextLight,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 11),
    ),
  );
}