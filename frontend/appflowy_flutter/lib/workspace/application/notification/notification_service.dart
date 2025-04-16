import 'package:flutter/foundation.dart';
import 'package:local_notifier/local_notifier.dart';

/// The app name used in the local notification.
///
/// DO NOT Use i18n here, because the i18n plugin is not ready
///   before the local notification is initialized.
const _localNotifierAppName = 'AppFlowy';

/// Manages Local Notifications
///
/// Currently supports:
///  - MacOS
///  - Windows
///  - Linux
///
class NotificationService {
  static Future<void> initialize() async {
    await localNotifier.setup(
      appName: _localNotifierAppName,
      // Don't create a shortcut on Windows, because the setup.exe will create a shortcut
      shortcutPolicy: ShortcutPolicy.requireNoCreate,
    );
  }
}

/// Creates and shows a Notification
///
class NotificationMessage {
  NotificationMessage({
    required String title,
    required String body,
    String? identifier,
    VoidCallback? onClick,
  }) {
    _notification = LocalNotification(
      identifier: identifier,
      title: title,
      body: body,
    )..onClick = onClick;

    _show();
  }

  late final LocalNotification _notification;

  void _show() => _notification.show();
}
