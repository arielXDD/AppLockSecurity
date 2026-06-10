import 'package:flutter/material.dart';

class AppStyle {
  static const bg = Color(0xFFF7F8FC);
  static const card = Colors.white;
  static const text = Color(0xFF10132B);
  static const muted = Color(0xFF6B7280);
  static const primary = Color(0xFF5D55F6);
  static const primarySoft = Color(0xFFEDEBFF);
  static const line = Color(0xFFE8EAF3);
  static const success = Color(0xFF22C55E);
  static const danger = Color(0xFFEF4444);

  static const shadow = [
    BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 10)),
  ];

  static LinearGradient get primaryGradient => const LinearGradient(
    colors: [Color(0xFF5D55F6), Color(0xFF7A6CFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
