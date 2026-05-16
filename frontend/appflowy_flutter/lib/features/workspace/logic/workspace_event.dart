import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';

sealed class UserWorkspaceEvent {
  UserWorkspaceEvent();

  // Factory functions for creating events
  factory UserWorkspaceEvent.initialize() => WorkspaceEventInitialize();

  factory UserWorkspaceEvent.fetchWorkspaces({
    String? initialWorkspaceId,
  }) =>
      WorkspaceEventFetchWorkspaces(initialWorkspaceId: initialWorkspaceId);

  factory UserWorkspaceEvent.createWorkspace({
    required String name,
    required WorkspaceTypePB workspaceType,
  }) =>
      WorkspaceEventCreateWorkspace(name: name, workspaceType: workspaceType);

  factory UserWorkspaceEvent.deleteWorkspace({
    required String workspaceId,
  }) =>
      WorkspaceEventDeleteWorkspace(workspaceId: workspaceId);

  factory UserWorkspaceEvent.openWorkspace({
    required String workspaceId,
    required WorkspaceTypePB workspaceType,
  }) =>
      WorkspaceEventOpenWorkspace(
        workspaceId: workspaceId,
        workspaceType: workspaceType,
      );

  factory UserWorkspaceEvent.renameWorkspace({
    required String workspaceId,
    required String name,
  }) =>
      WorkspaceEventRenameWorkspace(workspaceId: workspaceId, name: name);

  factory UserWorkspaceEvent.updateWorkspaceIcon({
    required String workspaceId,
    required String icon,
  }) =>
      WorkspaceEventUpdateWorkspaceIcon(
        workspaceId: workspaceId,
        icon: icon,
      );

  factory UserWorkspaceEvent.leaveWorkspace({
    required String workspaceId,
  }) =>
      WorkspaceEventLeaveWorkspace(workspaceId: workspaceId);

  factory UserWorkspaceEvent.fetchWorkspaceSubscriptionInfo({
    required String workspaceId,
  }) =>
      WorkspaceEventFetchWorkspaceSubscriptionInfo(workspaceId: workspaceId);

  factory UserWorkspaceEvent.updateWorkspaceSubscriptionInfo({
    required String workspaceId,
    required WorkspaceSubscriptionInfoPB subscriptionInfo,
  }) =>
      WorkspaceEventUpdateWorkspaceSubscriptionInfo(
        workspaceId: workspaceId,
        subscriptionInfo: subscriptionInfo,
      );

  factory UserWorkspaceEvent.emitWorkspaces({
    required List<UserWorkspacePB> workspaces,
  }) =>
      WorkspaceEventEmitWorkspaces(workspaces: workspaces);

  factory UserWorkspaceEvent.emitUserProfile({
    required UserProfilePB userProfile,
  }) =>
      WorkspaceEventEmitUserProfile(userProfile: userProfile);

  factory UserWorkspaceEvent.emitCurrentWorkspace({
    required UserWorkspacePB workspace,
  }) =>
      WorkspaceEventEmitCurrentWorkspace(workspace: workspace);
}

/// Initializes the workspace bloc.
class WorkspaceEventInitialize extends UserWorkspaceEvent {
  WorkspaceEventInitialize();
}

/// Fetches the list of workspaces for the current user.
class WorkspaceEventFetchWorkspaces extends UserWorkspaceEvent {
  WorkspaceEventFetchWorkspaces({
    this.initialWorkspaceId,
  });

  final String? initialWorkspaceId;
}

/// Creates a new workspace.
class WorkspaceEventCreateWorkspace extends UserWorkspaceEvent {
  WorkspaceEventCreateWorkspace({
    required this.name,
    required this.workspaceType,
  });

  final String name;
  final WorkspaceTypePB workspaceType;
}

/// Deletes a workspace.
class WorkspaceEventDeleteWorkspace extends UserWorkspaceEvent {
  WorkspaceEventDeleteWorkspace({
    required this.workspaceId,
  });

  final String workspaceId;
}

/// Opens a workspace.
class WorkspaceEventOpenWorkspace extends UserWorkspaceEvent {
  WorkspaceEventOpenWorkspace({
    required this.workspaceId,
    required this.workspaceType,
  });

  final String workspaceId;
  final WorkspaceTypePB workspaceType;
}

/// Renames a workspace.
class WorkspaceEventRenameWorkspace extends UserWorkspaceEvent {
  WorkspaceEventRenameWorkspace({
    required this.workspaceId,
    required this.name,
  });

  final String workspaceId;
  final String name;
}

/// Updates workspace icon.
class WorkspaceEventUpdateWorkspaceIcon extends UserWorkspaceEvent {
  WorkspaceEventUpdateWorkspaceIcon({
    required this.workspaceId,
    required this.icon,
  });

  final String workspaceId;
  final String icon;
}

/// Leaves a workspace.
class WorkspaceEventLeaveWorkspace extends UserWorkspaceEvent {
  WorkspaceEventLeaveWorkspace({
    required this.workspaceId,
  });

  final String workspaceId;
}

/// Fetches workspace subscription info.
class WorkspaceEventFetchWorkspaceSubscriptionInfo extends UserWorkspaceEvent {
  WorkspaceEventFetchWorkspaceSubscriptionInfo({
    required this.workspaceId,
  });

  final String workspaceId;
}

/// Updates workspace subscription info.
class WorkspaceEventUpdateWorkspaceSubscriptionInfo extends UserWorkspaceEvent {
  WorkspaceEventUpdateWorkspaceSubscriptionInfo({
    required this.workspaceId,
    required this.subscriptionInfo,
  });

  final String workspaceId;
  final WorkspaceSubscriptionInfoPB subscriptionInfo;
}

class WorkspaceEventEmitWorkspaces extends UserWorkspaceEvent {
  WorkspaceEventEmitWorkspaces({
    required this.workspaces,
  });

  final List<UserWorkspacePB> workspaces;
}

class WorkspaceEventEmitUserProfile extends UserWorkspaceEvent {
  WorkspaceEventEmitUserProfile({
    required this.userProfile,
  });

  final UserProfilePB userProfile;
}

class WorkspaceEventEmitCurrentWorkspace extends UserWorkspaceEvent {
  WorkspaceEventEmitCurrentWorkspace({
    required this.workspace,
  });

  final UserWorkspacePB workspace;
}
