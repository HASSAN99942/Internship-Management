import 'package:flutter/material.dart';
import 'colors.dart';
import 'typography.dart';

const _shape = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(12)),
);

ThemeData get lightTheme => ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: kPrimaryLight,
        onPrimary: kOnPrimaryLight,
        surface: kSurfaceLight,
        onSurface: kOnSurfaceLight,
        surfaceContainerHighest: kSurfaceVariantLight,
        outline: kOutlineLight,
        error: kDestructive,
        onError: kDestructiveFg,
      ),
      textTheme: buildTextTheme(kOnSurfaceLight, kMutedLight),
      cardTheme: CardThemeData(
        color: kCardLight,
        shape: _shape,
        elevation: 1,
        shadowColor: Colors.black12,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryLight,
          foregroundColor: kOnPrimaryLight,
          shape: _shape,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: kPrimaryLight,
          side: const BorderSide(color: kOutlineLight),
          shape: _shape,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kSurfaceVariantLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kOutlineLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kOutlineLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimaryLight, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      scaffoldBackgroundColor: kSurfaceVariantLight,
      dividerColor: kOutlineLight,
    );

ThemeData get darkTheme => ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: kPrimaryDark,
        onPrimary: kOnPrimaryDark,
        surface: kSurfaceDark,
        onSurface: kOnSurfaceDark,
        surfaceContainerHighest: kCardDark,
        outline: kOutlineDark,
        error: kDestructive,
        onError: kDestructiveFg,
      ),
      textTheme: buildTextTheme(kOnSurfaceDark, kMutedDark),
      cardTheme: CardThemeData(
        color: kCardDark,
        shape: _shape,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryDark,
          foregroundColor: kOnPrimaryDark,
          shape: _shape,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: kPrimaryDark,
          side: const BorderSide(color: kOutlineDark),
          shape: _shape,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kCardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kOutlineDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kOutlineDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimaryDark, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      scaffoldBackgroundColor: kSurfaceDark,
      dividerColor: kOutlineDark,
    );
