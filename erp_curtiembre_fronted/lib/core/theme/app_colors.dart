// app_colors.dart

import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color primary = Color(0xFFE8590C);
  static const Color primaryAlt = Color(0xFFFF7A2F);
  static const Color primarySoft = Color(0xFFFFE7D8);

  static const Color background = Color(0xFFF3F4F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFF8F9FA);

  static const Color text = Color(0xFF25262A);
  static const Color textSecondary = Color(0xFF6F737A);

  static const Color success = Color(0xFF4F7A45);
  static const Color successSoft = Color(0xFFE4F0E0);

  static const Color warning = Color(0xFFD99A22);
  static const Color warningSoft = Color(0xFFF9E8BF);

  static const Color error = Color(0xFFB54735);
  static const Color errorSoft = Color(0xFFF9DFDA);
}

abstract final class AppDarkColors {
  static const Color primary = Color(0xFFFF7A2F);
  static const Color primaryAlt = Color(0xFFFF9A61);
  static const Color primarySoft = Color(0xFF5A2D16);

  static const Color background = Color(0xFF191A1D);
  static const Color surface = Color(0xFF242529);
  static const Color card = Color(0xFF2C2E33);

  static const Color text = Color(0xFFF1F1F3);
  static const Color textSecondary = Color(0xFFA0A3AA);

  static const Color success = Color(0xFF8DBF7A);
  static const Color successSoft = Color(0xFF223321);

  static const Color warning = Color(0xFFE7B955);
  static const Color warningSoft = Color(0xFF423317);

  static const Color error = Color(0xFFE47669);
  static const Color errorSoft = Color(0xFF45211C);
}
