import 'package:flutter/material.dart';

class AppTypography {
  AppTypography._();

  static const _base = 'Nunito';

  static const displayLarge = TextStyle(
    fontFamily: _base,
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  static const headlineMedium = TextStyle(
    fontFamily: _base,
    fontSize: 20,
    fontWeight: FontWeight.w800,
  );

  static const titleMedium = TextStyle(
    fontFamily: _base,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  static const bodyMedium = TextStyle(
    fontFamily: _base,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  static const bodySmall = TextStyle(
    fontFamily: _base,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const labelMedium = TextStyle(
    fontFamily: _base,
    fontSize: 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
  );
}
