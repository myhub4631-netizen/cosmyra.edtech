import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Cosmyra Edu Phase 1 Design System Tokens & Theme Architecture
class AppColors {
  // Brand Primaries
  static const Color primary = Color(0xFF4F46E5); // Electric Indigo
  static const Color primaryHover = Color(0xFF4338CA);
  static const Color primaryLight = Color(0xFFEEF2FF);
  static const Color primaryBorder = Color(0xFFC7D2FE);

  // Accents & Badges
  static const Color emerald = Color(0xFF10B981); // Emerald Green
  static const Color emeraldLight = Color(0xFFECFDF5);
  static const Color emeraldBorder = Color(0xFFA7F3D0);

  static const Color amber = Color(0xFFF59E0B); // Warm Gold
  static const Color amberLight = Color(0xFFFEF3C7);
  static const Color amberBorder = Color(0xFFFDE68A);

  static const Color rose = Color(0xFFF43F5E);
  static const Color roseLight = Color(0xFFFFE4E6);

  static const Color purple = Color(0xFF8B5CF6);
  static const Color purpleLight = Color(0xFFF5F3FF);

  // Neutrals (Cool Slate Canvas)
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderSubtle = Color(0xFFF1F5F9);

  // Text Hierarchy
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
}

class AppGradients {
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0B1329)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppShadows {
  static final List<BoxShadow> soft = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static final List<BoxShadow> medium = [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.06),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: const Color(0xFF4F46E5).withValues(alpha: 0.03),
      blurRadius: 30,
      offset: const Offset(0, 10),
    ),
  ];

  static final List<BoxShadow> glowing = [
    BoxShadow(
      color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
}

class AppTypography {
  static TextStyle displayHeading({Color color = AppColors.textPrimary}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 26,
      fontWeight: FontWeight.w800,
      color: color,
      height: 1.2,
      letterSpacing: -0.5,
    );
  }

  static TextStyle titleBold({Color color = AppColors.textPrimary, double size = 18}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: color,
      height: 1.25,
    );
  }

  static TextStyle bodyMedium({Color color = AppColors.textSecondary, double size = 13.5}) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: FontWeight.w400,
      color: color,
      height: 1.5,
    );
  }

  static TextStyle labelBold({Color color = AppColors.primary, double size = 11.5}) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: color,
      letterSpacing: 0.2,
    );
  }
}

class AppButtonStyles {
  static ButtonStyle primary({double borderRadius = 10}) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
      textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
    );
  }

  static ButtonStyle success({double borderRadius = 10}) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.emerald,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
      textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
    );
  }

  static ButtonStyle secondary({double borderRadius = 10}) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryLight,
      foregroundColor: AppColors.primary,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
      textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
    );
  }

  static ButtonStyle outline({double borderRadius = 10, Color color = AppColors.primary}) {
    return OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color, width: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
      textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
    );
  }
}

class AppGlass {
  static Widget blurContainer({
    required Widget child,
    double blur = 12.0,
    Color color = Colors.white,
    double opacity = 0.85,
    BorderRadius? borderRadius,
    Border? border,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: opacity),
            borderRadius: borderRadius ?? BorderRadius.circular(16),
            border: border ?? Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class AppWidgets {
  static Widget buildPillBadge({
    required String label,
    required Color bg,
    required Color text,
    Color? border,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: border != null ? Border.all(color: border) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: text),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: text,
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildCardContainer({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? color,
    BorderRadius? borderRadius,
    List<BoxShadow>? shadows,
    Border? border,
  }) {
    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: border ?? Border.all(color: AppColors.border),
        boxShadow: shadows ?? AppShadows.soft,
      ),
      child: child,
    );
  }
}

class AppDesignSystem {
  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.emerald,
        surface: AppColors.surface,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: AppButtonStyles.primary()),
      outlinedButtonTheme: OutlinedButtonThemeData(style: AppButtonStyles.outline()),
    );
  }
}
