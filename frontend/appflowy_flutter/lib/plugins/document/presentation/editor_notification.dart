import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

enum EditorNotificationType {
  none,
  undo,
  redo,
  exitEditing,
}

class EditorNotification {
  const EditorNotification({
    required this.type,
  });

  EditorNotification.undo() : type = EditorNotificationType.undo;
  EditorNotification.redo() : type = EditorNotificationType.redo;
  EditorNotification.exitEditing() : type = EditorNotificationType.exitEditing;

  static final PropertyValueNotifier<EditorNotificationType> _notifier =
      PropertyValueNotifier(
    EditorNotificationType.none,
  );

  final EditorNotificationType type;

  void post() {
    _notifier.value = type;
  }

  static void addListener(ValueChanged<EditorNotificationType> listener) {
    _notifier.addListener(() {
      listener(_notifier.value);
    });
  }

  static void removeListener(ValueChanged<EditorNotificationType> listener) {
    _notifier.removeListener(() {
      listener(_notifier.value);
    });
  }

  static void dispose() {
    _notifier.dispose();
  }
}
