enum ActionType {
  openView,
}

/// A [NotificationAction] is used to communicate with the
/// [NotificationActionBloc] to perform actions based on an event
/// triggered by pressing a notification, such as opening a specific
/// view and jumping to a specific block.
///
class NotificationAction {
  const NotificationAction({
    this.type = ActionType.openView,
    required this.objectId,
  });

  final ActionType type;

  final String objectId;
}
