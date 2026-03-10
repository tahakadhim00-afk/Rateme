import 'package:flutter/material.dart';

class AppColors {
  // Dark cinema background palette
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF0E0E0E);
  static const Color surfaceVariant = Color(0xFF1C1C1E);
  static const Color card = Color(0xFF161616);

  // Accent — golden cinema feel
  static const Color primary = Color(0xFFFEC720);
  static const Color primaryDark = Color(0xFFD4A800);
  static const Color primaryLight = Color(0xFFFFD84D);

  // Secondary — deep red
  static const Color secondary = Color(0xFFE63946);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color textMuted = Color(0xFF666666);

  // Borders & dividers
  static const Color border = Color(0xFF333333);
  static const Color divider = Color(0xFF222222);

  // Status
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFEF5350);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFE8B84B), Color(0xFFC99A2E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backdropGradient = LinearGradient(
    colors: [Colors.transparent, Color(0xFF000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

/// Theme-aware colors — use `AppThemeColors.of(context).xxx` instead of
/// the raw `AppColors` constants for surface/text/border colors.
class AppThemeColors {
  final Color surface;
  final Color surfaceVariant;
  final Color card;
  final Color background;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color divider;

  const AppThemeColors._({
    required this.surface,
    required this.surfaceVariant,
    required this.card,
    required this.background,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.divider,
  });

  static AppThemeColors of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? _dark : _light;
  }

  static const _dark = AppThemeColors._(
    surface: AppColors.surface,
    surfaceVariant: AppColors.surfaceVariant,
    card: AppColors.card,
    background: AppColors.background,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textMuted: AppColors.textMuted,
    border: AppColors.border,
    divider: AppColors.divider,
  );

  static const _light = AppThemeColors._(
    surface: Colors.white,
    surfaceVariant: Color(0xFFEAEAF0),
    card: Colors.white,
    background: Color(0xFFF2F2F7),
    textPrimary: Color(0xFF0D0D17),
    textSecondary: Color(0xFF5A5A72),
    textMuted: Color(0xFF9A9AB0),
    border: Color(0xFFE0E0EC),
    divider: Color(0xFFE0E0EC),
  );
}

const _poppins = 'Poppins';

class AppTheme {
  static ThemeData get lightTheme {
    final base = ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF2F2F7),
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: Colors.white,
        error: AppColors.error,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: Color(0xFF0D0D17),
      ),
      textTheme: base.textTheme.apply(fontFamily: _poppins).copyWith(
        displayLarge: const TextStyle(fontFamily: _poppins, fontSize: 32, fontWeight: FontWeight.w700, color: Color(0xFF0D0D17), letterSpacing: -0.5),
        displayMedium: const TextStyle(fontFamily: _poppins, fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF0D0D17), letterSpacing: -0.3),
        displaySmall: const TextStyle(fontFamily: _poppins, fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFF0D0D17)),
        headlineMedium: const TextStyle(fontFamily: _poppins, fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF0D0D17)),
        headlineSmall: const TextStyle(fontFamily: _poppins, fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF0D0D17)),
        titleLarge: const TextStyle(fontFamily: _poppins, fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0D0D17)),
        titleMedium: const TextStyle(fontFamily: _poppins, fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF0D0D17)),
        bodyLarge: const TextStyle(fontFamily: _poppins, fontSize: 15, fontWeight: FontWeight.w400, color: Color(0xFF0D0D17), height: 1.6),
        bodyMedium: const TextStyle(fontFamily: _poppins, fontSize: 13, fontWeight: FontWeight.w400, color: Color(0xFF5A5A72), height: 1.5),
        labelLarge: const TextStyle(fontFamily: _poppins, fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0D0D17), letterSpacing: 0.2),
        labelSmall: const TextStyle(fontFamily: _poppins, fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF9A9AB0), letterSpacing: 0.5),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF2F2F7),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontFamily: _poppins, fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF0D0D17)),
        iconTheme: IconThemeData(color: Color(0xFF0D0D17)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontFamily: _poppins, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE0E0EC), width: 0.5),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE0E0EC),
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFEAEAF0),
        hintStyle: const TextStyle(fontFamily: _poppins, color: Color(0xFF9A9AB0), fontSize: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Color(0xFF9A9AB0),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: base.textTheme.apply(fontFamily: _poppins).copyWith(
        displayLarge: const TextStyle(fontFamily: _poppins, fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.5),
        displayMedium: const TextStyle(fontFamily: _poppins, fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.3),
        displaySmall: const TextStyle(fontFamily: _poppins, fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        headlineMedium: const TextStyle(fontFamily: _poppins, fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        headlineSmall: const TextStyle(fontFamily: _poppins, fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleLarge: const TextStyle(fontFamily: _poppins, fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleMedium: const TextStyle(fontFamily: _poppins, fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        bodyLarge: const TextStyle(fontFamily: _poppins, fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.textPrimary, height: 1.6),
        bodyMedium: const TextStyle(fontFamily: _poppins, fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.5),
        labelLarge: const TextStyle(fontFamily: _poppins, fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: 0.2),
        labelSmall: const TextStyle(fontFamily: _poppins, fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textMuted, letterSpacing: 0.5),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontFamily: _poppins, fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        hintStyle: const TextStyle(fontFamily: _poppins, color: AppColors.textMuted, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        labelStyle: const TextStyle(
          fontFamily: _poppins,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        checkmarkColor: AppColors.primary,
      ),
    );
  }
}
