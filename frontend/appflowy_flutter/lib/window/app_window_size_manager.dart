import 'dart:convert';
import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';

class WindowSizeManager {
  static const double minWindowHeight = 400.0;
  static const double minWindowWidth = 600.0;

  Future<void> saveSize(
    double currentWindowHeight,
    double currentWindowWidth,
  ) async {
    final windowSize = {
      'height': currentWindowHeight < minWindowHeight
          ? minWindowHeight
          : currentWindowHeight,
      'width': currentWindowWidth < minWindowWidth
          ? minWindowWidth
          : currentWindowWidth,
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('windowSize', json.encode(windowSize));
  }

  Future<Size> getSize() async {
    final prefs = await SharedPreferences.getInstance();
    const defaultWindowSize = '{"height": 600.0, "width": 800.0}';
    final windowSize = json.decode(
      prefs.getString('windowSize') ?? defaultWindowSize,
    );

    return Size(windowSize['width']!, windowSize['height']!);
  }
}
