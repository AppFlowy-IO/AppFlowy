import 'package:flutter/foundation.dart' show TargetPlatform, kIsWeb;

extension TargetPlatformHelper on TargetPlatform {
  /// Convenience function to check if the app is running on a desktop computer.
  ///
  /// Easily check if on desktop by checking `defaultTargetPlatform.isDesktop`.
  bool get isDesktop =>
      !kIsWeb &&
      (this == TargetPlatform.linux ||
          this == TargetPlatform.macOS ||
          this == TargetPlatform.windows);
}
