import 'package:flutter/material.dart';

class AppFlowySurfaceColorScheme {
  const AppFlowySurfaceColorScheme({
    required this.primary,
    required this.primaryHover,
    required this.secondary,
    required this.overlay,
  });

  final Color primary;
  final Color primaryHover;
  final Color secondary;
  final Color overlay;

  AppFlowySurfaceColorScheme lerp(
    AppFlowySurfaceColorScheme other,
    double t,
  ) {
    return AppFlowySurfaceColorScheme(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryHover: Color.lerp(primaryHover, other.primaryHover, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
    );
  }
}
