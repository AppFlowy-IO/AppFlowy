import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:appflowy/user/presentation/router.dart';
import 'package:appflowy/util/platform_extension.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/workspace.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/desktop_sign_in_screen.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/mobile_sign_in_screen.dart';
import 'package:flowy_infra_ui/style_widget/snap_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({
    super.key,
    required this.router,
  });

  static const routeName = '/SignInScreen';
  final AuthRouter router;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SignInBloc>(),
      child: BlocConsumer<SignInBloc, SignInState>(
        listener: (context, state) {
          state.successOrFail.fold(
            () => null,
            (result) => _handleSuccessOrFail(result, context),
          );
        },
        builder: (_, __) {
          if (PlatformExtension.isMobile) {
            return const MobileSignInScreen();
          }
          return const DesktopSignInScreen();
        },
      ),
    );
  }

  void _handleSuccessOrFail(
    Either<UserProfilePB, FlowyError> result,
    BuildContext context,
  ) {
    result.fold(
      (user) {
        if (user.encryptionType == EncryptionTypePB.Symmetric) {
          router.pushEncryptionScreen(context, user);
        } else {
          router.pushWorkspaceStartScreen(context, user);
        }
      },
      (error) {
        handleOpenWorkspaceError(context, error);
      },
    );
  }
}

void handleOpenWorkspaceError(BuildContext context, FlowyError error) {
  if (error.code == ErrorCode.WorkspaceDataNotSync) {
    final userFolder = UserFolderPB.fromBuffer(error.payload);
    getIt<AuthRouter>().pushWorkspaceErrorScreen(context, userFolder, error);
  } else {
    Log.error(error);
    showSnapBar(
      context,
      error.msg,
      onClosed: () {
        getIt<AuthService>().signOut();
        runAppFlowy();
      },
    );
  }
}
