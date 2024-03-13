import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/widgets/show_flowy_mobile_confirm_dialog.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/sign_in_or_logout_button.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/widgets.dart';
import 'package:appflowy_backend/log.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserSessionSettingGroup extends StatelessWidget {
  const UserSessionSettingGroup({
    super.key,
    required this.showThirdPartyLogin,
  });

  final bool showThirdPartyLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showThirdPartyLogin) ...[
          BlocProvider(
            create: (context) => getIt<SignInBloc>(),
            child: BlocConsumer<SignInBloc, SignInState>(
              listener: (context, state) {
                state.successOrFail?.fold(
                  (result) => runAppFlowy(),
                  (e) => Log.error(e),
                );
              },
              builder: (context, state) {
                return const ThirdPartySignInButtons();
              },
            ),
          ),
          const VSpace(8),
        ],
        MobileSignInOrLogoutButton(
          labelText: LocaleKeys.settings_menu_logout.tr(),
          onPressed: () async {
            await showFlowyMobileConfirmDialog(
              context,
              content: FlowyText(
                LocaleKeys.settings_menu_logoutPrompt.tr(),
              ),
              actionButtonTitle: LocaleKeys.button_yes.tr(),
              actionButtonColor: Theme.of(context).colorScheme.error,
              onActionButtonPressed: () async {
                await getIt<AuthService>().signOut();
                await runAppFlowy();
              },
            );
          },
        ),
      ],
    );
  }
}
