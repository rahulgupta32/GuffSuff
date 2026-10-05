import 'package:flutter/material.dart';

class AppColors {
  // Light Mode Colors
  static const Color lightSurfacePrimary = Color(0xFFFFFFFF);
  static const Color lightSurfaceSecondary = Color(0xFFF8FAFC);
  static const Color lightSurfaceElevated = Color(0xFFFFFFFF);
  static const Color lightContentPrimary = Color(0xFF0F172A);
  static const Color lightContentSecondary = Color(0xFF475569);
  static const Color lightContentMuted = Color(0xFF94A3B8);
  static const Color lightBorderSubtle = Color(0xFFE2E8F0);
  static const Color lightInteractiveDisabled = Color(0xFFCBD5E1);

  // Dark Mode Colors
  static const Color darkSurfacePrimary = Color(0xFF0F172A);
  static const Color darkSurfaceSecondary = Color(0xFF1E293B);
  static const Color darkSurfaceElevated = Color(0xFF334155);
  static const Color darkContentPrimary = Color(0xFFF8FAFC);
  static const Color darkContentSecondary = Color(0xFF94A3B8);
  static const Color darkContentMuted = Color(0xFF64748B);
  static const Color darkBorderSubtle = Color(0xFF334155);
  static const Color darkInteractiveDisabled = Color(0xFF475569);

  // Core Brand & Interactive Tokens (Shared)
  static const Color brandPrimary = Color(0xFF0F294A); // Deep Navy / Ink
  static const Color brandSecondary = Color(0xFF991B1B); // Restrained Crimson
  static const Color interactivePrimary = Color(0xFF0284C7); // Action Blue
  static const Color interactivePressed = Color(0xFF0369A1); // Deep Action Blue

  // Status & Feedback Tokens
  static const Color danger = Color(0xFFDC2626);
  static const Color warning = Color(0xFFD97706);
  static const Color success = Color(0xFF16A34A);
}

class AppTypography {
  static const TextStyle display = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: -0.3,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.2,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static const TextStyle metadata = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    height: 1.3,
  );
}

class AppSpacing {
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;
  static const double s40 = 40.0;
}

class AppRadii {
  static const double small = 4.0;
  static const double medium = 8.0;
  static const double large = 12.0;
  static const double bubble = 16.0;
  static const double full = 999.0;

  static const BorderRadius borderSmall = BorderRadius.all(
    Radius.circular(small),
  );
  static const BorderRadius borderMedium = BorderRadius.all(
    Radius.circular(medium),
  );
  static const BorderRadius borderLarge = BorderRadius.all(
    Radius.circular(large),
  );
  static const BorderRadius borderBubble = BorderRadius.all(
    Radius.circular(bubble),
  );
  static const BorderRadius borderFull = BorderRadius.all(
    Radius.circular(full),
  );
}
