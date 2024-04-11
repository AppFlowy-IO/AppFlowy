import 'package:flutter/foundation.dart';
import 'package:local_notifier/local_notifier.dart';

const _appName = "AppFlowy";

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
      appName: _appName,
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
