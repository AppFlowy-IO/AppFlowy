import 'dart:async';

import 'package:appflowy/startup/tasks/deeplink/deeplink_handler.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/sidebar_workspace.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';

// appflowy-flutter://invitation-callback?workspace_id=b2d11122-1fc8-474d-9ef1-ec12fea7ffe8

class InvitationDeepLinkHandler extends DeepLinkHandler<void> {
  static const invitationCallbackHost = 'invitation-callback';
  static const invitationCallbackWorkspaceId = 'workspace_id';

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

    return true;
  }

  @override
  Future<FlowyResult<void, FlowyError>> handle({
    required Uri uri,
    required DeepLinkStateHandler onStateChange,
  }) async {
    final workspaceId = uri.queryParameters[invitationCallbackWorkspaceId];
    if (workspaceId == null) {
      return FlowyResult.failure(
        FlowyError(
          msg: 'Workspace ID is required',
        ),
      );
    }

    openWorkspaceIdNotifier.value = workspaceId;

    return FlowyResult.success(null);
  }
}
