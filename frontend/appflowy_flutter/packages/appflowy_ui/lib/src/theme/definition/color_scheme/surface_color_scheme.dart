import 'package:flutter/material.dart';

class AppFlowySurfaceColorScheme {
  const AppFlowySurfaceColorScheme({
    required this.primary,
    required this.primaryHover,
    required this.layer01,
    required this.layer01Hover,
    required this.layer02,
    required this.layer02Hover,
    required this.layer03,
    required this.layer03Hover,
    required this.layer04,
    required this.layer04Hover,
    required this.inverse,
    required this.secondary,
    required this.overlay,
  });

  final Color primary;
  final Color primaryHover;
  final Color layer01;
  final Color layer01Hover;
  final Color layer02;
  final Color layer02Hover;
  final Color layer03;
  final Color layer03Hover;
  final Color layer04;
  final Color layer04Hover;
  final Color inverse;
  final Color secondary;
  final Color overlay;

  AppFlowySurfaceColorScheme lerp(
    AppFlowySurfaceColorScheme other,
    double t,
  ) {
    return AppFlowySurfaceColorScheme(
      primary: Color.lerp(
        primary,
        other.primary,
        t,
      )!,
      primaryHover: Color.lerp(
        primaryHover,
        other.primaryHover,
        t,
      )!,
      layer01: Color.lerp(
        layer01,
        other.layer01,
        t,
      )!,
      layer01Hover: Color.lerp(
        layer01Hover,
        other.layer01Hover,
        t,
      )!,
      layer02: Color.lerp(
        layer02,
        other.layer02,
        t,
      )!,
      layer02Hover: Color.lerp(
        layer02Hover,
        other.layer02Hover,
        t,
      )!,
      layer03: Color.lerp(
        layer03,
        other.layer03,
        t,
      )!,
      layer03Hover: Color.lerp(
        layer03Hover,
        other.layer03Hover,
        t,
      )!,
      layer04: Color.lerp(
        layer04,
        other.layer04,
        t,
      )!,
      layer04Hover: Color.lerp(
        layer04Hover,
        other.layer04Hover,
        t,
      )!,
      inverse: Color.lerp(
        inverse,
        other.inverse,
        t,
      )!,
      secondary: Color.lerp(
        secondary,
        other.secondary,
        t,
      )!,
      overlay: Color.lerp(
        overlay,
        other.overlay,
        t,
      )!,
    );
  }
}
