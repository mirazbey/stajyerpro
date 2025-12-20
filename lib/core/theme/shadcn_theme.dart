// Shadcn/UI Inspired Theme System for Flutter
// Material You + Shadcn + GetWidget Fusion
// Bu dosya modern, tutarlı ve erişilebilir bir UI sistemi sağlar.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shadcn-inspired Color System
class ShadcnColors {
  // Background colors
  static const Color background = Color(0xFF09090B);       // zinc-950
  static const Color backgroundAlt = Color(0xFF18181B);    // zinc-900
  static const Color foreground = Color(0xFFFAFAFA);       // zinc-50
  
  // Card colors
  static const Color card = Color(0xFF18181B);             // zinc-900
  static const Color cardForeground = Color(0xFFFAFAFA);   // zinc-50
  
  // Popover colors
  static const Color popover = Color(0xFF18181B);          // zinc-900
  static const Color popoverForeground = Color(0xFFFAFAFA);// zinc-50
  
  // Primary colors - Indigo based
  static const Color primary = Color(0xFF6366F1);          // indigo-500
  static const Color primaryForeground = Color(0xFFFFFFFF);
  static const Color primaryHover = Color(0xFF4F46E5);     // indigo-600
  static const Color primaryMuted = Color(0xFF312E81);     // indigo-900
  
  // Secondary colors
  static const Color secondary = Color(0xFF27272A);        // zinc-800
  static const Color secondaryForeground = Color(0xFFFAFAFA);
  static const Color secondaryHover = Color(0xFF3F3F46);   // zinc-700
  
  // Muted colors
  static const Color muted = Color(0xFF27272A);            // zinc-800
  static const Color mutedForeground = Color(0xFFA1A1AA);  // zinc-400
  
  // Accent colors
  static const Color accent = Color(0xFF27272A);           // zinc-800
  static const Color accentForeground = Color(0xFFFAFAFA);
  
  // Destructive colors
  static const Color destructive = Color(0xFFEF4444);      // red-500
  static const Color destructiveForeground = Color(0xFFFAFAFA);
  
  // Border & Input
  static const Color border = Color(0xFF27272A);           // zinc-800
  static const Color input = Color(0xFF27272A);            // zinc-800
  static const Color ring = Color(0xFF6366F1);             // indigo-500
  
  // Status colors
  static const Color success = Color(0xFF22C55E);          // green-500
  static const Color successMuted = Color(0xFF14532D);     // green-900
  static const Color warning = Color(0xFFF59E0B);          // amber-500
  static const Color warningMuted = Color(0xFF78350F);     // amber-900
  static const Color error = Color(0xFFEF4444);            // red-500
  static const Color errorMuted = Color(0xFF7F1D1D);       // red-900
  static const Color info = Color(0xFF3B82F6);             // blue-500
  static const Color infoMuted = Color(0xFF1E3A8A);        // blue-900
  
  // Chart colors
  static const Color chart1 = Color(0xFF6366F1);           // indigo
  static const Color chart2 = Color(0xFF8B5CF6);           // violet
  static const Color chart3 = Color(0xFFEC4899);           // pink
  static const Color chart4 = Color(0xFF14B8A6);           // teal
  static const Color chart5 = Color(0xFFF97316);           // orange
}

/// Shadcn-inspired Typography
class ShadcnTypography {
  static const String fontFamily = 'Inter';
  
  // Display
  static TextStyle displayLarge = const TextStyle(
    fontFamily: fontFamily,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.1,
    color: ShadcnColors.foreground,
  );
  
  static TextStyle displayMedium = const TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    height: 1.2,
    color: ShadcnColors.foreground,
  );
  
  static TextStyle displaySmall = const TextStyle(
    fontFamily: fontFamily,
    fontSize: 30,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.25,
    height: 1.2,
    color: ShadcnColors.foreground,
  );
  
  // Headings
  static TextStyle h1 = const TextStyle(
    fontFamily: fontFamily,
    fontSize: 30,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
    color: ShadcnColors.foreground,
  );
  
  static TextStyle h2 = const TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.25,
    height: 1.3,
    color: ShadcnColors.foreground,
  );
  
  static TextStyle h3 = const TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.15,
    height: 1.4,
    color: ShadcnColors.foreground,
  );
  
  static TextStyle h4 = const TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: ShadcnColors.foreground,
  );
  
  // Body
  static TextStyle bodyLarge = const TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: ShadcnColors.foreground,
  );
  
  static TextStyle bodyMedium = const TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: ShadcnColors.foreground,
  );
  
  static TextStyle bodySmall = const TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: ShadcnColors.mutedForeground,
  );
  
  // Labels
  static TextStyle labelLarge = const TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.4,
    color: ShadcnColors.foreground,
  );
  
  static TextStyle labelMedium = const TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.4,
    color: ShadcnColors.foreground,
  );
  
  static TextStyle labelSmall = const TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.4,
    color: ShadcnColors.mutedForeground,
  );
  
  // Code
  static TextStyle code = const TextStyle(
    fontFamily: 'JetBrains Mono',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: ShadcnColors.foreground,
  );
}

/// Shadcn-inspired Spacing System
class ShadcnSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 48.0;
  static const double massive = 64.0;
}

/// Shadcn-inspired Border Radius
class ShadcnRadius {
  static const double none = 0.0;
  static const double xs = 2.0;
  static const double sm = 4.0;
  static const double md = 6.0;
  static const double lg = 8.0;
  static const double xl = 12.0;
  static const double xxl = 16.0;
  static const double full = 9999.0;
  
  static BorderRadius get borderNone => BorderRadius.circular(none);
  static BorderRadius get borderSm => BorderRadius.circular(sm);
  static BorderRadius get borderMd => BorderRadius.circular(md);
  static BorderRadius get borderLg => BorderRadius.circular(lg);
  static BorderRadius get borderXl => BorderRadius.circular(xl);
  static BorderRadius get borderXxl => BorderRadius.circular(xxl);
  static BorderRadius get borderFull => BorderRadius.circular(full);
}

/// Shadcn-inspired Shadows
class ShadcnShadows {
  static List<BoxShadow> get none => [];
  
  static List<BoxShadow> get sm => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];
  
  static List<BoxShadow> get md => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 6,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get lg => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 15,
      offset: const Offset(0, 10),
    ),
  ];
  
  static List<BoxShadow> get xl => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 25,
      offset: const Offset(0, 20),
    ),
  ];
  
  // Glow effects
  static List<BoxShadow> glowPrimary([double opacity = 0.4]) => [
    BoxShadow(
      color: ShadcnColors.primary.withOpacity(opacity),
      blurRadius: 20,
      spreadRadius: -2,
    ),
  ];
  
  static List<BoxShadow> glowSuccess([double opacity = 0.4]) => [
    BoxShadow(
      color: ShadcnColors.success.withOpacity(opacity),
      blurRadius: 20,
      spreadRadius: -2,
    ),
  ];
  
  static List<BoxShadow> glowError([double opacity = 0.4]) => [
    BoxShadow(
      color: ShadcnColors.error.withOpacity(opacity),
      blurRadius: 20,
      spreadRadius: -2,
    ),
  ];
}

/// Shadcn-inspired Animation Durations
class ShadcnDurations {
  static const Duration fastest = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 300);
  static const Duration slower = Duration(milliseconds: 400);
  static const Duration slowest = Duration(milliseconds: 500);
}

/// Shadcn-inspired Animation Curves
class ShadcnCurves {
  static const Curve linear = Curves.linear;
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve spring = Curves.elasticOut;
  static const Curve bounce = Curves.bounceOut;
}

/// Complete Theme Data Builder
class ShadcnTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: ShadcnColors.primary,
        onPrimary: ShadcnColors.primaryForeground,
        secondary: ShadcnColors.secondary,
        onSecondary: ShadcnColors.secondaryForeground,
        surface: ShadcnColors.card,
        onSurface: ShadcnColors.cardForeground,
        error: ShadcnColors.destructive,
        onError: ShadcnColors.destructiveForeground,
      ),
      
      // Scaffold
      scaffoldBackgroundColor: ShadcnColors.background,
      
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: ShadcnColors.background,
        foregroundColor: ShadcnColors.foreground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: ShadcnTypography.h4,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: ShadcnColors.background,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),
      
      // Card
      cardTheme: CardThemeData(
        color: ShadcnColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: ShadcnRadius.borderLg,
          side: const BorderSide(color: ShadcnColors.border),
        ),
      ),
      
      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ShadcnColors.primary,
          foregroundColor: ShadcnColors.primaryForeground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: ShadcnRadius.borderMd,
          ),
          textStyle: ShadcnTypography.labelLarge,
        ),
      ),
      
      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ShadcnColors.foreground,
          side: const BorderSide(color: ShadcnColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: ShadcnRadius.borderMd,
          ),
          textStyle: ShadcnTypography.labelLarge,
        ),
      ),
      
      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ShadcnColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: ShadcnRadius.borderMd,
          ),
          textStyle: ShadcnTypography.labelLarge,
        ),
      ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ShadcnColors.input,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: ShadcnRadius.borderMd,
          borderSide: const BorderSide(color: ShadcnColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: ShadcnRadius.borderMd,
          borderSide: const BorderSide(color: ShadcnColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: ShadcnRadius.borderMd,
          borderSide: const BorderSide(color: ShadcnColors.ring, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: ShadcnRadius.borderMd,
          borderSide: const BorderSide(color: ShadcnColors.destructive),
        ),
        hintStyle: ShadcnTypography.bodyMedium.copyWith(
          color: ShadcnColors.mutedForeground,
        ),
        labelStyle: ShadcnTypography.labelMedium,
      ),
      
      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: ShadcnColors.secondary,
        labelStyle: ShadcnTypography.labelSmall,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: ShadcnRadius.borderFull,
          side: const BorderSide(color: ShadcnColors.border),
        ),
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: ShadcnColors.card,
        selectedItemColor: ShadcnColors.primary,
        unselectedItemColor: ShadcnColors.mutedForeground,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      
      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: ShadcnColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: ShadcnRadius.borderLg,
        ),
        titleTextStyle: ShadcnTypography.h4,
        contentTextStyle: ShadcnTypography.bodyMedium,
      ),
      
      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: ShadcnColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      
      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ShadcnColors.card,
        contentTextStyle: ShadcnTypography.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: ShadcnRadius.borderMd,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: ShadcnColors.primary,
        linearTrackColor: ShadcnColors.secondary,
        circularTrackColor: ShadcnColors.secondary,
      ),
      
      // Divider
      dividerTheme: const DividerThemeData(
        color: ShadcnColors.border,
        thickness: 1,
      ),
      
      // Icon
      iconTheme: const IconThemeData(
        color: ShadcnColors.foreground,
        size: 24,
      ),
      
      // Text Selection
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: ShadcnColors.primary,
        selectionColor: ShadcnColors.primary.withOpacity(0.3),
        selectionHandleColor: ShadcnColors.primary,
      ),
    );
  }
}
