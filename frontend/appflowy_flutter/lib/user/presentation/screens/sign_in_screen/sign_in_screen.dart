import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:appflowy/user/presentation/router.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/desktop_sign_in_screen.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/mobile_sign_in_screen.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../helpers/helpers.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({
    super.key,
  });

  static const routeName = '/SignInScreen';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SignInBloc>(),
      child: BlocConsumer<SignInBloc, SignInState>(
        listener: (context, state) {
          state.successOrFail.fold(
            () => null,
            (userProfileResult) => handleUserProfileResult(
              userProfileResult,
              context,
              getIt<AuthRouter>(),
            ),
          );
        },
        builder: (context, state) {
          // When user is logining through 3rd party, a loading widget will appear on the screen. [isLoading] is used to control it is on or not.
          final isLoading = context.read<SignInBloc>().state.isSubmitting;
          if (PlatformExtension.isMobile) {
            return MobileSignInScreen(
              isLoading: isLoading,
            );
          }
          return DesktopSignInScreen(
            isLoading: isLoading,
          );
        },
      ),
    );
  }
}
