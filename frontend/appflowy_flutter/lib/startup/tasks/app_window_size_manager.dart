import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/startup/startup.dart';

class WindowSizeManager {
  static const double minWindowHeight = 400.0;
  static const double minWindowWidth = 600.0;

  Future<void> saveSize(Size size) async {
    final windowSize = {
      'height': max(size.height, minWindowHeight),
      'width': max(size.width, minWindowWidth),
    };

    await getIt<KeyValueStorage>().set(
      KVKeys.windowSize,
      jsonEncode(windowSize),
    );
  }

  Future<Size> getSize() async {
    const defaultWindowSize = '{"height": 600.0, "width": 800.0}';
    final windowSize = await getIt<KeyValueStorage>().get(KVKeys.windowSize);
    final size = json.decode(
      windowSize.fold(
        (l) => defaultWindowSize,
        (r) => r,
      ),
    );
    return Size(size['width']!, size['height']!);
  }
}
