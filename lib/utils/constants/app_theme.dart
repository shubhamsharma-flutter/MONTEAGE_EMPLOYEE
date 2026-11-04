import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'color_constants.dart';

class AppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColor.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColor.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColor.primaryTint,
      onPrimaryContainer: AppColor.primaryDark,
      secondary: AppColor.accent,
      onSecondary: Colors.white,
      secondaryContainer: AppColor.accentTint,
      onSecondaryContainer: AppColor.textPrimary,
      error: AppColor.danger,
      surface: AppColor.surface,
      onSurface: AppColor.textPrimary,
      onSurfaceVariant: AppColor.textSecondary,
      surfaceContainerHighest: AppColor.surfaceVariant,
      outline: AppColor.borderStrong,
      outlineVariant: AppColor.border,
    );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    const buttonPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 14);
    final buttonText = GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w700,
    );

    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColor.background,
      // Built by hand: GoogleFonts.interTextTheme() returns material_ui's
      // TextTheme, which ThemeData doesn't accept.
      textTheme: TextTheme(
        bodyLarge: GoogleFonts.inter(color: AppColor.textPrimary),
        bodyMedium: GoogleFonts.inter(color: AppColor.textPrimary),
        bodySmall: GoogleFonts.inter(color: AppColor.textSecondary),
        labelLarge: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: AppColor.textPrimary,
        ),
        titleSmall: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: AppColor.textPrimary,
        ),
        headlineSmall: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          color: AppColor.textPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          color: AppColor.textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          color: AppColor.textPrimary,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColor.primary,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColor.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColor.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColor.surface,
        hintStyle: GoogleFonts.inter(color: AppColor.textMuted, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: AppColor.textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: inputBorder(AppColor.border),
        enabledBorder: inputBorder(AppColor.border),
        focusedBorder: inputBorder(AppColor.primary, 1.5),
        errorBorder: inputBorder(AppColor.danger),
        focusedErrorBorder: inputBorder(AppColor.danger, 1.5),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColor.primary,
          foregroundColor: Colors.white,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColor.primary,
          side: const BorderSide(color: AppColor.borderStrong),
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColor.primary,
          textStyle: buttonText,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColor.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: AppColor.textPrimary,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          height: 1.4,
          color: AppColor.textSecondary,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColor.surface,
        surfaceTintColor: Colors.transparent,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColor.surface,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: const DividerThemeData(color: AppColor.border, space: 1),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColor.primary,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColor.surface,
        selectedColor: AppColor.primaryTint,
        side: const BorderSide(color: AppColor.border),
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColor.textPrimary,
        ),
      ),
    );
  }
}
