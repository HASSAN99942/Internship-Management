import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

TextTheme buildTextTheme(Color onSurface, Color muted) {
  final heading = GoogleFonts.spaceGroteskTextTheme().copyWith(
    displayLarge: GoogleFonts.spaceGrotesk(
      fontSize: 57, fontWeight: FontWeight.w700, color: onSurface, height: 1.12,
    ),
    displayMedium: GoogleFonts.spaceGrotesk(
      fontSize: 45, fontWeight: FontWeight.w700, color: onSurface, height: 1.16,
    ),
    displaySmall: GoogleFonts.spaceGrotesk(
      fontSize: 36, fontWeight: FontWeight.w700, color: onSurface, height: 1.22,
    ),
    headlineLarge: GoogleFonts.spaceGrotesk(
      fontSize: 32, fontWeight: FontWeight.w700, color: onSurface, height: 1.25,
    ),
    headlineMedium: GoogleFonts.spaceGrotesk(
      fontSize: 28, fontWeight: FontWeight.w600, color: onSurface, height: 1.29,
    ),
    headlineSmall: GoogleFonts.spaceGrotesk(
      fontSize: 24, fontWeight: FontWeight.w600, color: onSurface, height: 1.33,
    ),
    titleLarge: GoogleFonts.spaceGrotesk(
      fontSize: 22, fontWeight: FontWeight.w600, color: onSurface, height: 1.27,
    ),
    titleMedium: GoogleFonts.spaceGrotesk(
      fontSize: 16, fontWeight: FontWeight.w600, color: onSurface, height: 1.50,
    ),
    titleSmall: GoogleFonts.spaceGrotesk(
      fontSize: 14, fontWeight: FontWeight.w600, color: onSurface, height: 1.43,
    ),
  );

  final body = GoogleFonts.interTextTheme().copyWith(
    bodyLarge: GoogleFonts.inter(
      fontSize: 16, fontWeight: FontWeight.w400, color: onSurface, height: 1.65,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14, fontWeight: FontWeight.w400, color: onSurface, height: 1.65,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 12, fontWeight: FontWeight.w400, color: muted, height: 1.65,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: 14, fontWeight: FontWeight.w500, color: onSurface, height: 1.43,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 12, fontWeight: FontWeight.w500, color: onSurface, height: 1.33,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 11, fontWeight: FontWeight.w500, color: muted, height: 1.45,
    ),
  );

  return heading.merge(body);
}
