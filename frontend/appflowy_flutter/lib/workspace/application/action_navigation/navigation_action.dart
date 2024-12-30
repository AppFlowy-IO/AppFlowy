enum ActionType {
  openView,
  jumpToBlock,
  openRow,
}

class ActionArgumentKeys {
  static String view = "view";
  static String nodePath = "node_path";
  static String blockId = "block_id";
  static String rowId = "row_id";
}

/// A [NavigationAction] is used to communicate with the
/// [ActionNavigationBloc] to perform actions based on an event
/// triggered by pressing a notification, such as opening a specific
/// view and jumping to a specific block.
///
class NavigationAction {
  const NavigationAction({
    this.type = ActionType.openView,
    this.arguments,
    required this.objectId,
  });

  final ActionType type;

  final String objectId;
  final Map<String, dynamic>? arguments;

  NavigationAction copyWith({
    ActionType? type,
    String? objectId,
    Map<String, dynamic>? arguments,
  }) =>
      NavigationAction(
        type: type ?? this.type,
        objectId: objectId ?? this.objectId,
        arguments: arguments ?? this.arguments,
      );
}
