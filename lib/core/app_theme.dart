import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        error: AppColors.error,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.onErrorContainer,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
      ),
      textTheme: TextTheme(
        // Headlines & Display (Space Grotesk)
        displayLarge: GoogleFonts.spaceGrotesk(
          fontSize: 56.sp,
          fontWeight: FontWeight.bold,
          height: 1.14,
          color: AppColors.onSurface,
        ),
        headlineLarge: GoogleFonts.spaceGrotesk(
          fontSize: 32.sp,
          fontWeight: FontWeight.w600,
          height: 1.25,
          color: AppColors.onSurface,
        ),
        headlineMedium: GoogleFonts.spaceGrotesk(
          fontSize: 28.sp,
          fontWeight: FontWeight.w600,
          height: 1.28,
          color: AppColors.onSurface,
        ),
        headlineSmall: GoogleFonts.spaceGrotesk(
          fontSize: 24.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),

        // Titles & Body (Manrope)
        titleLarge: GoogleFonts.manrope(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          color: AppColors.onSurface,
        ),
        titleMedium: GoogleFonts.manrope(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          height: 1.33,
          color: AppColors.onSurface,
        ),
        titleSmall: GoogleFonts.manrope(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        bodyLarge: GoogleFonts.manrope(
          fontSize: 16.sp,
          fontWeight: FontWeight.normal,
          height: 1.5,
          color: AppColors.onSurface,
        ),
        bodyMedium: GoogleFonts.manrope(
          fontSize: 14.sp,
          height: 1.43,
          color: AppColors.onSurfaceVariant,
        ),
        bodySmall: GoogleFonts.manrope(
          fontSize: 12.sp,
          color: AppColors.onSurfaceVariant,
        ),

        // Labels & Monospace (JetBrains Mono)
        labelLarge: GoogleFonts.jetBrainsMono(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurface,
        ),
        labelMedium: GoogleFonts.jetBrainsMono(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurfaceVariant,
        ),
        labelSmall: GoogleFonts.jetBrainsMono(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.05,
          color: AppColors.onSurfaceVariant,
        ),
      ),
      scaffoldBackgroundColor: AppColors.background,
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: const BorderSide(color: AppColors.outlineVariant),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 56.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
