import 'dart:convert';
import 'dart:ui';

import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/startup/startup.dart';

class WindowSizeManager {
  static const double minWindowHeight = 640.0;
  static const double minWindowWidth = 960.0;
  // Preventing failed assertion due to Texture Descriptor Validation
  static const double maxWindowHeight = 8192.0;
  static const double maxWindowWidth = 8192.0;

  static const double maxScaleFactor = 2.0;
  static const double minScaleFactor = 0.5;

  static const width = 'width';
  static const height = 'height';

  static const String dx = 'dx';
  static const String dy = 'dy';

  Future<void> setSize(Size size) async {
    final windowSize = {
      height: size.height.clamp(minWindowHeight, maxWindowHeight),
      width: size.width.clamp(minWindowWidth, maxWindowWidth),
    };

    await getIt<KeyValueStorage>().set(
      KVKeys.windowSize,
      jsonEncode(windowSize),
    );
  }

  Future<Size> getSize() async {
    final defaultWindowSize = jsonEncode(
      {WindowSizeManager.height: 600.0, WindowSizeManager.width: 800.0},
    );
    final windowSize = await getIt<KeyValueStorage>().get(KVKeys.windowSize);
    final size = json.decode(
      windowSize ?? defaultWindowSize,
    );
    final double width = size[WindowSizeManager.width] ?? minWindowWidth;
    final double height = size[WindowSizeManager.height] ?? minWindowHeight;
    return Size(
      width.clamp(minWindowWidth, maxWindowWidth),
      height.clamp(minWindowHeight, maxWindowHeight),
    );
  }

  Future<void> setPosition(Offset offset) async {
    await getIt<KeyValueStorage>().set(
      KVKeys.windowPosition,
      jsonEncode({
        dx: offset.dx,
        dy: offset.dy,
      }),
    );
  }

  Future<Offset?> getPosition() async {
    final position = await getIt<KeyValueStorage>().get(KVKeys.windowPosition);
    if (position == null) {
      return null;
    }
    final offset = json.decode(position);
    return Offset(offset[dx], offset[dy]);
  }

  Future<double> getScaleFactor() async {
    final scaleFactor = await getIt<KeyValueStorage>().getWithFormat<double>(
          KVKeys.scaleFactor,
          (value) => double.tryParse(value) ?? 1.0,
        ) ??
        1.0;
    return scaleFactor.clamp(minScaleFactor, maxScaleFactor);
  }

  Future<void> setScaleFactor(double scaleFactor) async {
    await getIt<KeyValueStorage>().set(
      KVKeys.scaleFactor,
      '${scaleFactor.clamp(minScaleFactor, maxScaleFactor)}',
    );
  }

  /// Set the window maximized status
  Future<void> setWindowMaximized(bool isMaximized) async {
    await getIt<KeyValueStorage>()
        .set(KVKeys.windowMaximized, isMaximized.toString());
  }

  /// Get the window maximized status
  Future<bool> getWindowMaximized() async {
    return await getIt<KeyValueStorage>().getWithFormat<bool>(
          KVKeys.windowMaximized,
          (v) => bool.tryParse(v) ?? false,
        ) ??
        false;
  }
}
