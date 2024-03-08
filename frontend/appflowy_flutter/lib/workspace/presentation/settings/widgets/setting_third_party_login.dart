import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:appflowy/user/presentation/router.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/widgets.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/snap_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingThirdPartyLogin extends StatelessWidget {
  const SettingThirdPartyLogin({required this.didLogin, super.key});

  final VoidCallback didLogin;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SignInBloc>(),
      child: BlocConsumer<SignInBloc, SignInState>(
        listener: (context, state) {
          final successOrFail = state.successOrFail;
          if (successOrFail != null) {
            _handleSuccessOrFail(successOrFail, context);
          }
        },
        builder: (_, state) {
          final indicator = state.isSubmitting
              ? const LinearProgressIndicator(minHeight: 1)
              : const SizedBox.shrink();

          final promptMessage = state.isSubmitting
              ? FlowyText.medium(
                  LocaleKeys.signIn_syncPromptMessage.tr(),
                  maxLines: null,
                )
              : const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  FlowyText.medium(
                    LocaleKeys.signIn_signInWith.tr(),
                    fontSize: 16,
                  ),
                  const HSpace(6),
                ],
              ),
              const VSpace(6),
              promptMessage,
              const VSpace(6),
              indicator,
              const VSpace(6),
              if (isAuthEnabled) const ThirdPartySignInButtons(),
              const VSpace(6),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleSuccessOrFail(
    FlowyResult<UserProfilePB, FlowyError> result,
    BuildContext context,
  ) async {
    result.fold(
      (user) async {
        if (user.encryptionType == EncryptionTypePB.Symmetric) {
          getIt<AuthRouter>().pushEncryptionScreen(context, user);
        } else {
          didLogin();
          await runAppFlowy();
        }
      },
      (error) => showSnapBar(context, error.msg),
    );
  }
}
