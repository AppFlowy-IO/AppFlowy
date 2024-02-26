import 'package:appflowy/user/presentation/helpers/helpers.dart';
import 'package:appflowy/user/presentation/presentation.dart';
import 'package:appflowy_backend/protobuf/flowy-error/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter/material.dart';

void handleUserProfileResult(
  FlowyResult<UserProfilePB, FlowyError> userProfileResult,
  BuildContext context,
  AuthRouter authRouter,
) {
  userProfileResult.fold(
    (userProfile) {
      if (userProfile.encryptionType == EncryptionTypePB.Symmetric) {
        authRouter.pushEncryptionScreen(context, userProfile);
      } else {
        authRouter.goHomeScreen(context, userProfile);
      }
    },
    (error) {
      handleOpenWorkspaceError(context, error);
    },
  );
}
