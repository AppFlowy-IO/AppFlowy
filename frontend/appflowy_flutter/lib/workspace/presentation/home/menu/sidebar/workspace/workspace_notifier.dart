// Workaround for open workspace from invitation deep link
import 'package:flutter/material.dart';

ValueNotifier<WorkspaceNotifyValue?> openWorkspaceNotifier =
    ValueNotifier(null);

class WorkspaceNotifyValue {
  WorkspaceNotifyValue({this.workspaceId, this.userId});

  final String? workspaceId;
  final String? userId;
}
