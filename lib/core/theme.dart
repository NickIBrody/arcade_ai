import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color background = Color(0xFF07060A);
  static const Color surface = Color(0xFF0F0D16);
  static const Color surfaceHigh = Color(0xFF161320);
  static const Color stroke = Color(0xFF221E30);

  static const Color violet = Color(0xFF8B5CF6);
  static const Color violetDeep = Color(0xFF6D28D9);
  static const Color violetSoft = Color(0xFFA78BFA);
  static const Color glow = Color(0x558B5CF6);

  static const Color textPrimary = Color(0xFFF4F2F8);
  static const Color textSecondary = Color(0xFF9A93AD);
  static const Color textFaint = Color(0xFF5C5670);

  static const Color danger = Color(0xFFF43F5E);
  static const Color success = Color(0xFF34D399);

  static const LinearGradient violetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [violet, violetDeep],
  );

  static const RadialGradient ambient = RadialGradient(
    center: Alignment(-0.6, -0.9),
    radius: 1.4,
    colors: [Color(0x335B21B6), Color(0x00000000)],
  );
}

class AppRadii {
  static const double sm = 12;
  static const double md = 18;
  static const double lg = 26;
  static const double pill = 999;
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.2,
        color: AppColors.textPrimary,
      ),
      displaySmall: GoogleFonts.spaceGrotesk(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.6,
        color: AppColors.textPrimary,
      ),
      titleMedium: GoogleFonts.spaceGrotesk(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 15.5,
        height: 1.5,
        color: AppColors.textPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        height: 1.5,
        color: AppColors.textSecondary,
      ),
      labelSmall: GoogleFonts.jetBrainsMono(
        fontSize: 11.5,
        letterSpacing: 0.4,
        color: AppColors.textFaint,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.surface,
        primary: AppColors.violet,
        secondary: AppColors.violetSoft,
        error: AppColors.danger,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: textTheme,
      splashColor: AppColors.glow,
      highlightColor: Colors.transparent,
      dividerColor: AppColors.stroke,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
    );
  }
}

const String kRepo = 'NickIBrody/arcade_ai';
const String kRepoUrl = 'https://github.com/NickIBrody/arcade_ai';
const String kAppVersion = '1.1.1';
