import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/widgets/show_flowy_mobile_confirm_dialog.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/user/application/sign_in_bloc.dart';
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
            await showFlowyCupertinoConfirmDialog(
              title: LocaleKeys.settings_menu_logoutPrompt.tr(),
              leftButton: FlowyText(
                LocaleKeys.button_cancel.tr(),
                fontSize: 17.0,
                figmaLineHeight: 24.0,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF007AFF),
              ),
              rightButton: FlowyText(
                LocaleKeys.button_logout.tr(),
                fontSize: 17.0,
                figmaLineHeight: 24.0,
                fontWeight: FontWeight.w400,
                color: const Color(0xFFFE0220),
              ),
              onRightButtonPressed: (context) async {
                Navigator.of(context).pop();
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
