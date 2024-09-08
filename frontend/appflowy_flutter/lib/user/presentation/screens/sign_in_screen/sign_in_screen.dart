import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:appflowy/user/presentation/router.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/desktop_sign_in_screen.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/mobile_loading_screen.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/mobile_sign_in_screen.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../helpers/helpers.dart';

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
          final isLoading = context.read<SignInBloc>().state.isSubmitting;
          if (PlatformExtension.isMobile) {
            return isLoading
                ? const MobileLoadingScreen()
                : const MobileSignInScreen();
          }
          return const DesktopSignInScreen();
        },
      ),
    );
  }

  void _showSignInError(BuildContext context, SignInState state) {
    final successOrFail = state.successOrFail;
    if (successOrFail != null) {
      handleUserProfileResult(
        successOrFail,
        context,
        getIt<AuthRouter>(),
      );
    }
  }
}
