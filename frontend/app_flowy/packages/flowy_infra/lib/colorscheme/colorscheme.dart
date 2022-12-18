import 'package:flutter/material.dart';

import 'default_colorscheme.dart';
import 'dandelion.dart';

@immutable
abstract class FlowyColorScheme {
  final Color surface;
  final Color hover;
  final Color selector;
  final Color red;
  final Color yellow;
  final Color green;
  final Color shader1;
  final Color shader2;
  final Color shader3;
  final Color shader4;
  final Color shader5;
  final Color shader6;
  final Color shader7;
  final Color bg1;
  final Color bg2;
  final Color bg3;
  final Color bg4;
  final Color tint1;
  final Color tint2;
  final Color tint3;
  final Color tint4;
  final Color tint5;
  final Color tint6;
  final Color tint7;
  final Color tint8;
  final Color tint9;
  final Color main1;
  final Color main2;
  final Color shadow;

  const FlowyColorScheme({
    required this.surface,
    required this.hover,
    required this.selector,
    required this.red,
    required this.yellow,
    required this.green,
    required this.shader1,
    required this.shader2,
    required this.shader3,
    required this.shader4,
    required this.shader5,
    required this.shader6,
    required this.shader7,
    required this.bg1,
    required this.bg2,
    required this.bg3,
    required this.bg4,
    required this.tint1,
    required this.tint2,
    required this.tint3,
    required this.tint4,
    required this.tint5,
    required this.tint6,
    required this.tint7,
    required this.tint8,
    required this.tint9,
    required this.main1,
    required this.main2,
    required this.shadow,
  });

  factory FlowyColorScheme.builtIn(String themeName, Brightness brightness) {
    if (themeName == 'Dandelion Community Theme') {
      switch (brightness) {
        case Brightness.light:
          return const DandelionColorScheme.light();
        case Brightness.dark:
          return const DandelionColorScheme.dark();
      }
    }
    switch (brightness) {
      case Brightness.light:
        return const DefaultColorScheme.light();
      case Brightness.dark:
        return const DefaultColorScheme.dark();
    }
  }

  // factory FlowyColorScheme.fromJson(Map<String, dynamic> json, Brightness brightness) {
  //   // load Json

  //   return FlowyColorScheme(brightness...);
  // }
}
