import 'package:appflowy/user/presentation/helpers/helpers.dart';
import 'package:appflowy/user/presentation/presentation.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/protobuf/flowy-error/protobuf.dart';
import 'package:flutter/material.dart';

void handleSuccessOrFail(
  Either<UserProfilePB, FlowyError> result,
  BuildContext context,
  AuthRouter router,
) {
  result.fold(
    (user) {
      if (user.encryptionType == EncryptionTypePB.Symmetric) {
        router.pushEncryptionScreen(context, user);
      } else {
        router.pushHomeScreen(context, user);
      }
    },
    (error) {
      handleOpenWorkspaceError(context, error);
    },
  );
}
