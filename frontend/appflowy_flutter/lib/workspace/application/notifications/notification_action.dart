enum ActionType {
  openView,
  jumpToBlock,
  openRow,
}

class ActionArgumentKeys {
  static String view = "view";
  static String nodePath = "node_path";
  static String rowId = "row_id";
}

/// A [NotificationAction] is used to communicate with the
/// [NotificationActionBloc] to perform actions based on an event
/// triggered by pressing a notification, such as opening a specific
/// view and jumping to a specific block.
///
class NotificationAction {
  const NotificationAction({
    this.type = ActionType.openView,
    this.arguments,
    required this.objectId,
  });

  final ActionType type;

  final String objectId;
  final Map<String, dynamic>? arguments;

  NotificationAction copyWith({
    ActionType? type,
    String? objectId,
    Map<String, dynamic>? arguments,
  }) =>
      NotificationAction(
        type: type ?? this.type,
        objectId: objectId ?? this.objectId,
        arguments: arguments ?? this.arguments,
      );
}
