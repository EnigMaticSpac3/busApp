import 'package:flutter/material.dart';

class AppShadows {
  static const shadowSm = BoxShadow(
    offset: Offset(0, 2),
    blurRadius: 8,
    color: Color.fromRGBO(0, 0, 0, 0.08),
  );

  static const shadowMd = BoxShadow(
    offset: Offset(0, 4),
    blurRadius: 12,
    color: Color.fromRGBO(0, 0, 0, 0.10),
  );

  static const shadowLg = BoxShadow(
    offset: Offset(0, 6),
    blurRadius: 16,
    color: Color.fromRGBO(0, 0, 0, 0.12),
  );
}
