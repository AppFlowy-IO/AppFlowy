import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/entry_point.dart';
import 'package:appflowy/startup/launch_configuration.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:appflowy/user/presentation/sign_in_screen.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
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
        builder: (_, __) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FlowyText.medium(
              LocaleKeys.signIn_signInWith.tr(),
              fontSize: 16,
            ),
            const VSpace(6),
            const ThirdPartySignInButtons(
              mainAxisAlignment: MainAxisAlignment.start,
            ),
          ],
        ),
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
