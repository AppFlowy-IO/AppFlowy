import 'package:appflowy/features/share_tab/data/models/models.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';

class ShareTabState {
  factory ShareTabState.initial() => const ShareTabState();

  const ShareTabState({
    this.currentUser,
    this.users = const [],
    this.availableUsers = const [],
    this.isLoading = false,
    this.errorMessage = '',
    this.shareLink = '',
    this.generalAccessRole,
    this.linkCopied = false,
    this.initialResult,
    this.shareResult,
    this.removeResult,
    this.updateAccessLevelResult,
    this.turnIntoMemberResult,
  });

  final UserProfilePB? currentUser;
  final SharedUsers users;
  final SharedUsers availableUsers;
  final bool isLoading;
  final String errorMessage;
  final String shareLink;
  final ShareAccessLevel? generalAccessRole;
  final bool linkCopied;
  final FlowyResult<void, FlowyError>? initialResult;
  final FlowyResult<void, FlowyError>? shareResult;
  final FlowyResult<void, FlowyError>? removeResult;
  final FlowyResult<void, FlowyError>? updateAccessLevelResult;
  final FlowyResult<void, FlowyError>? turnIntoMemberResult;

  ShareTabState copyWith({
    UserProfilePB? currentUser,
    SharedUsers? users,
    SharedUsers? availableUsers,
    bool? isLoading,
    String? errorMessage,
    String? shareLink,
    ShareAccessLevel? generalAccessRole,
    bool? linkCopied,
    FlowyResult<void, FlowyError>? initialResult,
    FlowyResult<void, FlowyError>? shareResult,
    FlowyResult<void, FlowyError>? removeResult,
    FlowyResult<void, FlowyError>? updateAccessLevelResult,
    FlowyResult<void, FlowyError>? turnIntoMemberResult,
  }) {
    return ShareTabState(
      currentUser: currentUser ?? this.currentUser,
      users: users ?? this.users,
      availableUsers: availableUsers ?? this.availableUsers,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      shareLink: shareLink ?? this.shareLink,
      generalAccessRole: generalAccessRole ?? this.generalAccessRole,
      linkCopied: linkCopied ?? this.linkCopied,
      initialResult: initialResult ?? this.initialResult,
      shareResult: shareResult ?? this.shareResult,
      removeResult: removeResult ?? this.removeResult,
      updateAccessLevelResult:
          updateAccessLevelResult ?? this.updateAccessLevelResult,
      turnIntoMemberResult: turnIntoMemberResult ?? this.turnIntoMemberResult,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShareTabState &&
        other.currentUser == currentUser &&
        other.users == users &&
        other.availableUsers == availableUsers &&
        other.isLoading == isLoading &&
        other.errorMessage == errorMessage &&
        other.shareLink == shareLink &&
        other.generalAccessRole == generalAccessRole &&
        other.linkCopied == linkCopied &&
        other.initialResult == initialResult &&
        other.shareResult == shareResult &&
        other.removeResult == removeResult &&
        other.updateAccessLevelResult == updateAccessLevelResult &&
        other.turnIntoMemberResult == turnIntoMemberResult;
  }

  @override
  int get hashCode {
    return Object.hash(
      currentUser,
      users,
      availableUsers,
      isLoading,
      errorMessage,
      shareLink,
      generalAccessRole,
      linkCopied,
      initialResult,
      shareResult,
      removeResult,
      updateAccessLevelResult,
      turnIntoMemberResult,
    );
  }

  @override
  String toString() {
    return 'ShareTabState(currentUser: $currentUser, users: $users, availableUsers: $availableUsers, isLoading: $isLoading, errorMessage: $errorMessage, shareLink: $shareLink, generalAccessRole: $generalAccessRole, linkCopied: $linkCopied, initialResult: $initialResult, shareResult: $shareResult, removeResult: $removeResult, updateAccessLevelResult: $updateAccessLevelResult, turnIntoMemberResult: $turnIntoMemberResult)';
  }
}
