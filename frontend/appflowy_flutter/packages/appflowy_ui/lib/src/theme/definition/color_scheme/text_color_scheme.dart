import 'package:flutter/material.dart';

class AppFlowyTextColorScheme {
  const AppFlowyTextColorScheme({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.quaternary,
    required this.onFill,
    required this.action,
    required this.actionHover,
    required this.info,
    required this.infoHover,
    required this.success,
    required this.successHover,
    required this.warning,
    required this.warningHover,
    required this.error,
    required this.errorHover,
    required this.featured,
    required this.featuredHover,
  });

  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color quaternary;
  final Color onFill;
  final Color action;
  final Color actionHover;
  final Color info;
  final Color infoHover;
  final Color success;
  final Color successHover;
  final Color warning;
  final Color warningHover;
  final Color error;
  final Color errorHover;
  final Color featured;
  final Color featuredHover;

  AppFlowyTextColorScheme lerp(
    AppFlowyTextColorScheme other,
    double t,
  ) {
    return AppFlowyTextColorScheme(
      primary: Color.lerp(
        primary,
        other.primary,
        t,
      )!,
      secondary: Color.lerp(
        secondary,
        other.secondary,
        t,
      )!,
      tertiary: Color.lerp(
        tertiary,
        other.tertiary,
        t,
      )!,
      quaternary: Color.lerp(
        quaternary,
        other.quaternary,
        t,
      )!,
      onFill: Color.lerp(
        onFill,
        other.onFill,
        t,
      )!,
      action: Color.lerp(
        action,
        other.action,
        t,
      )!,
      actionHover: Color.lerp(
        actionHover,
        other.actionHover,
        t,
      )!,
      info: Color.lerp(
        info,
        other.info,
        t,
      )!,
      infoHover: Color.lerp(
        infoHover,
        other.infoHover,
        t,
      )!,
      success: Color.lerp(
        success,
        other.success,
        t,
      )!,
      successHover: Color.lerp(
        successHover,
        other.successHover,
        t,
      )!,
      warning: Color.lerp(
        warning,
        other.warning,
        t,
      )!,
      warningHover: Color.lerp(
        warningHover,
        other.warningHover,
        t,
      )!,
      error: Color.lerp(
        error,
        other.error,
        t,
      )!,
      errorHover: Color.lerp(
        errorHover,
        other.errorHover,
        t,
      )!,
      featured: Color.lerp(
        featured,
        other.featured,
        t,
      )!,
      featuredHover: Color.lerp(
        featuredHover,
        other.featuredHover,
        t,
      )!,
    );
  }
}
