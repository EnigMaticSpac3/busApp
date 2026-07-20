import 'package:flutter/material.dart';

class AppShadows {
  // elevation-1: cards, stop cards
  static const shadowSm = BoxShadow(
    offset: Offset(0, 1),
    blurRadius: 3,
    color: Color.fromRGBO(0, 31, 48, 0.08),
  );

  // elevation-2: search bar flotante
  static const shadowMd = BoxShadow(
    offset: Offset(0, 4),
    blurRadius: 12,
    color: Color.fromRGBO(0, 31, 48, 0.10),
  );

  // elevation-3: FAB, bottom sheet
  static const shadowLg = BoxShadow(
    offset: Offset(0, 8),
    blurRadius: 24,
    color: Color.fromRGBO(0, 31, 48, 0.12),
  );
}
