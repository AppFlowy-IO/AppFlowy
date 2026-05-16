import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';

enum WorkspaceActionType {
  none,
  create,
  delete,
  open,
  rename,
  updateIcon,
  fetchWorkspaces,
  leave,
  fetchSubscriptionInfo,
}

class WorkspaceActionResult {
  const WorkspaceActionResult({
    required this.actionType,
    required this.isLoading,
    required this.result,
  });

  final WorkspaceActionType actionType;
  final bool isLoading;
  final FlowyResult<void, FlowyError>? result;

  @override
  String toString() {
    return 'WorkspaceActionResult(actionType: $actionType, isLoading: $isLoading, result: $result)';
  }
}

class UserWorkspaceState {
  factory UserWorkspaceState.initial(UserProfilePB userProfile) =>
      UserWorkspaceState(
        userProfile: userProfile,
      );

  const UserWorkspaceState({
    this.currentWorkspace,
    this.workspaces = const [],
    this.actionResult,
    this.isCollabWorkspaceOn = false,
    required this.userProfile,
    this.workspaceSubscriptionInfo,
  });

  final UserWorkspacePB? currentWorkspace;
  final List<UserWorkspacePB> workspaces;
  final WorkspaceActionResult? actionResult;
  final bool isCollabWorkspaceOn;
  final UserProfilePB userProfile;
  final WorkspaceSubscriptionInfoPB? workspaceSubscriptionInfo;

  UserWorkspaceState copyWith({
    UserWorkspacePB? currentWorkspace,
    List<UserWorkspacePB>? workspaces,
    WorkspaceActionResult? actionResult,
    bool? isCollabWorkspaceOn,
    UserProfilePB? userProfile,
    WorkspaceSubscriptionInfoPB? workspaceSubscriptionInfo,
  }) {
    return UserWorkspaceState(
      currentWorkspace: currentWorkspace ?? this.currentWorkspace,
      workspaces: workspaces ?? this.workspaces,
      actionResult: actionResult ?? this.actionResult,
      isCollabWorkspaceOn: isCollabWorkspaceOn ?? this.isCollabWorkspaceOn,
      userProfile: userProfile ?? this.userProfile,
      workspaceSubscriptionInfo:
          workspaceSubscriptionInfo ?? this.workspaceSubscriptionInfo,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserWorkspaceState &&
        other.currentWorkspace == currentWorkspace &&
        other.workspaces == workspaces &&
        other.actionResult == actionResult &&
        other.isCollabWorkspaceOn == isCollabWorkspaceOn &&
        other.userProfile == userProfile &&
        other.workspaceSubscriptionInfo == workspaceSubscriptionInfo;
  }

  @override
  int get hashCode {
    return Object.hash(
      currentWorkspace,
      workspaces,
      actionResult,
      isCollabWorkspaceOn,
      userProfile,
      workspaceSubscriptionInfo,
    );
  }

  @override
  String toString() {
    return 'WorkspaceState(currentWorkspace: $currentWorkspace, workspaces: $workspaces, actionResult: $actionResult, isCollabWorkspaceOn: $isCollabWorkspaceOn, userProfile: $userProfile, workspaceSubscriptionInfo: $workspaceSubscriptionInfo)';
  }
}
