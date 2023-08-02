import 'package:appflowy/startup/entry_point.dart';
import 'package:appflowy/startup/launch_configuration.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:appflowy/user/presentation/sign_in_screen.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_infra_ui/style_widget/snap_bar.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingThirdPartyLogin extends StatelessWidget {
  final VoidCallback didLogin;
  const SettingThirdPartyLogin({required this.didLogin, super.key});

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
        builder: (_, __) => const ThirdPartySignInButtons(),
      ),
    );
  }

  Future<void> _handleSuccessOrFail(
    Either<UserProfilePB, FlowyError> result,
    BuildContext context,
  ) async {
    result.fold(
      (user) async {
        didLogin();
        await FlowyRunner.run(
          FlowyApp(),
          integrationEnv(),
          config: const LaunchConfiguration(
            autoRegistrationSupported: true,
          ),
        );
      },
      (error) => showSnapBar(context, error.msg),
    );
  }
}
