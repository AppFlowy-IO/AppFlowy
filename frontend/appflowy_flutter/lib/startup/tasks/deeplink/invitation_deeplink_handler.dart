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
  static const invitationCallbackEmail = 'email';

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

    final containsEmail =
        uri.queryParameters.containsKey(invitationCallbackEmail);
    if (!containsEmail) {
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
    final email = uri.queryParameters[invitationCallbackEmail];
    if (workspaceId == null) {
      return FlowyResult.failure(
        FlowyError(
          msg: 'Workspace ID is required',
        ),
      );
    }

    if (email == null) {
      return FlowyResult.failure(
        FlowyError(
          msg: 'Email is required',
        ),
      );
    }

    openWorkspaceNotifier.value = WorkspaceNotifyValue(
      workspaceId: workspaceId,
      email: email,
    );

    return FlowyResult.success(null);
  }
}
