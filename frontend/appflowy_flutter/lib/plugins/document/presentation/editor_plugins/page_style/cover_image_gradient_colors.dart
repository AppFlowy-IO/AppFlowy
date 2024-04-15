import 'package:flutter/material.dart';

enum FlowyGradientColor {
  gradient1,
  gradient2,
  gradient3,
  gradient4,
  gradient5,
  gradient6,
  gradient7;

  String get id {
    // DON'T change this name because it's saved in the database!
    switch (this) {
      case FlowyGradientColor.gradient1:
        return 'appflowy_them_color_gradient1';
      case FlowyGradientColor.gradient2:
        return 'appflowy_them_color_gradient2';
      case FlowyGradientColor.gradient3:
        return 'appflowy_them_color_gradient3';
      case FlowyGradientColor.gradient4:
        return 'appflowy_them_color_gradient4';
      case FlowyGradientColor.gradient5:
        return 'appflowy_them_color_gradient5';
      case FlowyGradientColor.gradient6:
        return 'appflowy_them_color_gradient6';
      case FlowyGradientColor.gradient7:
        return 'appflowy_them_color_gradient7';
    }
  }

  LinearGradient get linear {
    switch (this) {
      case FlowyGradientColor.gradient1:
        return const LinearGradient(
          begin: Alignment(-0.35, -0.94),
          end: Alignment(0.35, 0.94),
          colors: [Color(0xFF34BDAF), Color(0xFFB682D4)],
        );
      case FlowyGradientColor.gradient2:
        return const LinearGradient(
          begin: Alignment(0.00, -1.00),
          end: Alignment(0, 1),
          colors: [Color(0xFF4CC2CC), Color(0xFFE17570)],
        );
      case FlowyGradientColor.gradient3:
        return const LinearGradient(
          begin: Alignment(0.00, -1.00),
          end: Alignment(0, 1),
          colors: [Color(0xFFAF70E0), Color(0xFFED7196)],
        );
      case FlowyGradientColor.gradient4:
        return const LinearGradient(
          begin: Alignment(0.00, -1.00),
          end: Alignment(0, 1),
          colors: [Color(0xFFA348D6), Color(0xFF44A7DE)],
        );
      case FlowyGradientColor.gradient5:
        return const LinearGradient(
          begin: Alignment(0.38, -0.93),
          end: Alignment(-0.38, 0.93),
          colors: [Color(0xFF5749C9), Color(0xFFBB4997)],
        );
      case FlowyGradientColor.gradient6:
        return const LinearGradient(
          begin: Alignment(0.00, -1.00),
          end: Alignment(0, 1),
          colors: [Color(0xFF036FFA), Color(0xFF00B8E5)],
        );
      case FlowyGradientColor.gradient7:
        return const LinearGradient(
          begin: Alignment(0.62, -0.79),
          end: Alignment(-0.62, 0.79),
          colors: [Color(0xFFF0C6CF), Color(0xFFDECCE2), Color(0xFFCAD3F9)],
        );
    }
  }
}
