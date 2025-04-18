import 'package:flutter/material.dart';

class AppFlowySurfaceColorScheme {
  const AppFlowySurfaceColorScheme({
    required this.primary,
    required this.overlay,
  });

  final Color primary;
  final Color overlay;

  AppFlowySurfaceColorScheme lerp(
    AppFlowySurfaceColorScheme other,
    double t,
  ) {
    return AppFlowySurfaceColorScheme(
      primary: Color.lerp(primary, other.primary, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
    );
  }
}
