import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/user/presentation/router.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/workspace.pb.dart';
import 'package:flutter/material.dart';

void handleOpenWorkspaceError(BuildContext context, FlowyError error) {
  Log.error(error);
  switch (error.code) {
    case ErrorCode.WorkspaceDataNotSync:
      final userFolder = UserFolderPB.fromBuffer(error.payload);
      getIt<AuthRouter>().pushWorkspaceErrorScreen(context, userFolder, error);
      break;
    case ErrorCode.InvalidEncryptSecret:
    case ErrorCode.HttpError:
      showToastNotification(
        context,
        message: error.msg,
        type: ToastificationType.error,
      );
      break;
    default:
      showToastNotification(
        context,
        message: error.msg,
        type: ToastificationType.error,
        callbacks: ToastificationCallbacks(
          onDismissed: (_) {
            getIt<AuthService>().signOut();
            runAppFlowy();
          },
        ),
      );
  }
}
