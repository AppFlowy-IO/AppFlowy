import 'package:flutter/material.dart';

class AppFlowyBrandColorScheme {
  const AppFlowyBrandColorScheme({
    required this.skyline,
    required this.aqua,
    required this.violet,
    required this.amethyst,
    required this.berry,
    required this.coral,
    required this.golden,
    required this.amber,
    required this.lemon,
  });

  final Color skyline;
  final Color aqua;
  final Color violet;
  final Color amethyst;
  final Color berry;
  final Color coral;
  final Color golden;
  final Color amber;
  final Color lemon;

  AppFlowyBrandColorScheme lerp(
    AppFlowyBrandColorScheme other,
    double t,
  ) {
    return AppFlowyBrandColorScheme(
      skyline: Color.lerp(skyline, other.skyline, t)!,
      aqua: Color.lerp(aqua, other.aqua, t)!,
      violet: Color.lerp(violet, other.violet, t)!,
      amethyst: Color.lerp(amethyst, other.amethyst, t)!,
      berry: Color.lerp(berry, other.berry, t)!,
      coral: Color.lerp(coral, other.coral, t)!,
      golden: Color.lerp(golden, other.golden, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      lemon: Color.lerp(lemon, other.lemon, t)!,
    );
  }
}
