import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/widgets/show_flowy_mobile_confirm_dialog.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/widgets.dart';
import 'package:appflowy/workspace/presentation/settings/pages/account/account_deletion.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserSessionSettingGroup extends StatelessWidget {
  const UserSessionSettingGroup({
    super.key,
    required this.userProfile,
    required this.showThirdPartyLogin,
  });

  final UserProfilePB userProfile;
  final bool showThirdPartyLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // third party sign in buttons
        if (showThirdPartyLogin) _buildThirdPartySignInButtons(context),
        const VSpace(8.0),

        // logout button
        MobileLogoutButton(
          text: LocaleKeys.settings_menu_logout.tr(),
          onPressed: () async => _showLogoutDialog(),
        ),

        // delete account button
        // only show the delete account button in cloud mode
        if (userProfile.authenticator == AuthenticatorPB.AppFlowyCloud) ...[
          const VSpace(16.0),
          MobileLogoutButton(
            text: LocaleKeys.button_deleteAccount.tr(),
            textColor: Theme.of(context).colorScheme.error,
            onPressed: () => _showDeleteAccountDialog(context),
          ),
        ],
      ],
    );
  }

  Widget _buildThirdPartySignInButtons(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SignInBloc>(),
      child: BlocConsumer<SignInBloc, SignInState>(
        listener: (context, state) {
          state.successOrFail?.fold(
            (result) => runAppFlowy(),
            (e) => Log.error(e),
          );
        },
        builder: (context, state) {
          return const ThirdPartySignInButtons(
            expanded: true,
          );
        },
      ),
    );
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    return showMobileBottomSheet(
      context,
      useRootNavigator: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => const _DeleteAccountBottomSheet(),
    );
  }

  Future<void> _showLogoutDialog() async {
    return showFlowyCupertinoConfirmDialog(
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
  }
}

class _DeleteAccountBottomSheet extends StatefulWidget {
  const _DeleteAccountBottomSheet();

  @override
  State<_DeleteAccountBottomSheet> createState() =>
      _DeleteAccountBottomSheetState();
}

class _DeleteAccountBottomSheetState extends State<_DeleteAccountBottomSheet> {
  final controller = TextEditingController();
  final isChecked = ValueNotifier(false);

  @override
  void dispose() {
    controller.dispose();
    isChecked.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const VSpace(18.0),
          const FlowySvg(
            FlowySvgs.icon_warning_xl,
            blendMode: null,
          ),
          const VSpace(12.0),
          FlowyText(
            LocaleKeys.newSettings_myAccount_deleteAccount_title.tr(),
            fontSize: 20.0,
            fontWeight: FontWeight.w500,
          ),
          const VSpace(12.0),
          FlowyText(
            LocaleKeys.newSettings_myAccount_deleteAccount_confirmHint1.tr(),
            fontSize: 14.0,
            fontWeight: FontWeight.w400,
            maxLines: 10,
          ),
          const VSpace(18.0),
          SizedBox(
            height: 36.0,
            child: FlowyTextField(
              controller: controller,
              textStyle: const TextStyle(fontSize: 14.0),
              hintStyle: const TextStyle(fontSize: 14.0),
              hintText: LocaleKeys
                  .newSettings_myAccount_deleteAccount_confirmHint3
                  .tr(),
            ),
          ),
          const VSpace(18.0),
          _buildCheckbox(),
          const VSpace(18.0),
          MobileLogoutButton(
            text: LocaleKeys.button_deleteAccount.tr(),
            textColor: Theme.of(context).colorScheme.error,
            onPressed: () => deleteMyAccount(
              context,
              controller.text.trim(),
              isChecked.value,
            ),
          ),
          const VSpace(12.0),
          MobileLogoutButton(
            text: LocaleKeys.button_cancel.tr(),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const VSpace(36.0),
        ],
      ),
    );
  }

  Widget _buildCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => isChecked.value = !isChecked.value,
          child: ValueListenableBuilder<bool>(
            valueListenable: isChecked,
            builder: (context, isChecked, _) {
              return Padding(
                padding: const EdgeInsets.all(1.0),
                child: FlowySvg(
                  isChecked ? FlowySvgs.check_filled_s : FlowySvgs.uncheck_s,
                  size: const Size.square(16.0),
                  blendMode: isChecked ? null : BlendMode.srcIn,
                ),
              );
            },
          ),
        ),
        const HSpace(6.0),
        Expanded(
          child: FlowyText.regular(
            LocaleKeys.newSettings_myAccount_deleteAccount_confirmHint2.tr(),
            fontSize: 14.0,
            figmaLineHeight: 18.0,
            maxLines: 3,
          ),
        ),
      ],
    );
  }
}
