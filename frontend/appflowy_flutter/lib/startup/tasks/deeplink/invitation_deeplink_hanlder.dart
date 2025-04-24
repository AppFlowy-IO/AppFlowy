import 'dart:async';

import 'package:appflowy/startup/tasks/deeplink/deeplink_handler.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/workspace_notifier.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';

// invitation callback deeplink example:
// appflowy-flutter://invitation-callback?workspace_id=b2d11122-1fc8-474d-9ef1-ec12fea7ffe8&user_id=275966408418922496
class InvitationDeepLinkHandler extends DeepLinkHandler<void> {
  static const invitationCallbackHost = 'invitation-callback';
  static const invitationCallbackWorkspaceId = 'workspace_id';
  static const invitationCallbackUserId = 'user_id';
  @override
  bool canHandle(Uri uri) {
    final isInvitationCallback = uri.host == invitationCallbackHost;
    if (!isInvitationCallback) {
      return false;
    }

    final containsWorkspaceId =
        uri.queryParameters.containsKey(invitationCallbackWorkspaceId);
    if (!containsWorkspaceId) {
      return false;
    }

    final containsUserId =
        uri.queryParameters.containsKey(invitationCallbackUserId);
    if (!containsUserId) {
      return false;
    }

    return true;
  }

  @override
  Future<FlowyResult<void, FlowyError>> handle({
    required Uri uri,
    required DeepLinkStateHandler onStateChange,
  }) async {
    final workspaceId = uri.queryParameters[invitationCallbackWorkspaceId];
    final userId = uri.queryParameters[invitationCallbackUserId];
    if (workspaceId == null) {
      return FlowyResult.failure(
        FlowyError(
          msg: 'Workspace ID is required',
        ),
      );
    }

    if (userId == null) {
      return FlowyResult.failure(
        FlowyError(
          msg: 'User ID is required',
        ),
      );
    }

    openWorkspaceNotifier.value = WorkspaceNotifyValue(
      workspaceId: workspaceId,
      userId: userId,
    );

    return FlowyResult.success(null);
  }
}
