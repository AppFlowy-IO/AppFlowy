enum ActionType {
  openView,
}

class NotificationAction {
  const NotificationAction({
    this.type = ActionType.openView,
    required this.objectId,
  });

  final ActionType type;

  final String objectId;
}
