import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:appflowy/user/presentation/router.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/desktop_sign_in_screen.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/mobile_sign_in_screen.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:universal_platform/universal_platform.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  static const routeName = '/SignInScreen';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SignInBloc>(),
      child: BlocConsumer<SignInBloc, SignInState>(
        listener: _showSignInError,
        builder: (context, state) {
          return UniversalPlatform.isDesktop
              ? const DesktopSignInScreen()
              : const MobileSignInScreen();
        },
      ),
    );
  }

  void _showSignInError(BuildContext context, SignInState state) {
    final successOrFail = state.successOrFail;
    if (successOrFail != null) {
      successOrFail.fold(
        (userProfile) {
          if (userProfile.encryptionType == EncryptionTypePB.Symmetric) {
            getIt<AuthRouter>().pushEncryptionScreen(context, userProfile);
          } else {
            getIt<AuthRouter>().goHomeScreen(context, userProfile);
          }
        },
        (error) {
          Log.error('Sign in error: $error');
        },
      );
    }
  }
}
