import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/base/emoji/emoji_picker.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/workspace/application/user/settings_user_bloc.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_alert_dialog.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_category.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_category_spacer.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_header.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_input_field.dart';
import 'package:appflowy/workspace/presentation/settings/shared/single_setting_action.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/setting_third_party_login.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy/workspace/presentation/widgets/user_avatar.dart';
import 'package:appflowy_backend/protobuf/flowy-user/auth.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsAccountView extends StatefulWidget {
  const SettingsAccountView({
    super.key,
    required this.userProfile,
    required this.didLogin,
    required this.didLogout,
  });

  final UserProfilePB userProfile;

  // Called when the user signs in from the setting dialog
  final VoidCallback didLogin;

  // Called when the user logout in the setting dialog
  final VoidCallback didLogout;

  @override
  State<SettingsAccountView> createState() => _SettingsAccountViewState();
}

class _SettingsAccountViewState extends State<SettingsAccountView> {
  late String userName = widget.userProfile.name;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsUserViewBloc>(
      create: (context) =>
          getIt<SettingsUserViewBloc>(param1: widget.userProfile)
            ..add(const SettingsUserEvent.initial()),
      child: BlocBuilder<SettingsUserViewBloc, SettingsUserState>(
        builder: (context, state) {
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SettingsHeader(
                  title: LocaleKeys.settings_account_title.tr(),
                  description: LocaleKeys.settings_account_description.tr(),
                ),
                SettingsCategory(
                  title: LocaleKeys.settings_account_general_title.tr(),
                  children: [
                    _UserProfileSetting(
                      name: userName,
                      iconUrl: state.userProfile.iconUrl,
                      onSave: (newName) {
                        // Pseudo change the name to update the UI before the backend
                        // processes the request. This is to give the user a sense of
                        // immediate feedback, and avoid UI flickering.
                        setState(() => userName = newName);
                        context
                            .read<SettingsUserViewBloc>()
                            .add(SettingsUserEvent.updateUserName(newName));
                      },
                    ),
                  ],
                ),
                // Only show change email if the user is authenticated and not using local auth
                if (isAuthEnabled &&
                    state.userProfile.authenticator !=
                        AuthenticatorPB.Local) ...[
                  const SettingsCategorySpacer(),
                  SettingsCategory(
                    title: LocaleKeys.settings_account_email_title.tr(),
                    children: [
                      SingleSettingAction(
                        label: state.userProfile.email,
                        buttonLabel: LocaleKeys
                            .settings_account_email_actions_change
                            .tr(),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],

                /// TODO: Uncomment and finish implementation when we have the feature
                // const SettingsCategorySpacer(),
                // SettingsCategory(
                //   title: 'Account & security',
                //   children: [
                //     SingleSettingAction(
                //       label: '**********',
                //       buttonLabel: 'Change password',
                //       onPressed: () {},
                //     ),
                //     SingleSettingAction(
                //       label: '2-step authentication',
                //       buttonLabel: 'Enable 2FA',
                //       onPressed: () {},
                //     ),
                //   ],
                // ),
                const SettingsCategorySpacer(),
                SettingsCategory(
                  title: LocaleKeys.settings_account_keys_title.tr(),
                  children: [
                    SettingsInputField(
                      label: LocaleKeys.settings_account_keys_openAILabel.tr(),
                      tooltip:
                          LocaleKeys.settings_account_keys_openAITooltip.tr(),
                      value: state.userProfile.openaiKey,
                      obscureText: true,
                      onSave: (key) => context
                          .read<SettingsUserViewBloc>()
                          .add(SettingsUserEvent.updateUserOpenAIKey(key)),
                    ),
                  ],
                ),
                const SettingsCategorySpacer(),
                SettingsCategory(
                  title: LocaleKeys.settings_account_login_title.tr(),
                  children: [
                    if (state.userProfile.authenticator ==
                        AuthenticatorPB.Local) ...[
                      _SignInButton(
                        userProfile: state.userProfile,
                        didLogin: widget.didLogin,
                      ),
                    ] else ...[
                      _SignOutButton(
                        userProfile: state.userProfile,
                        didLogout: widget.didLogout,
                      ),
                    ],
                  ],
                ),

                /// TODO: Uncomment and finish implementation when we have the feature
                // const SettingsCategorySpacer(),
                // SettingsSubcategory(
                //   title: 'Delete account',
                //   children: [
                //     SingleSettingAction(
                //       label:
                //           'Permanently delete your account and remove access from all teamspaces.',
                //       labelMaxLines: 4,
                //       onPressed: () {},
                //       buttonLabel: 'Delete my account',
                //       isDangerous: true,
                //       fontSize: 12,
                //     ),
                //   ],
                // ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SignInButton extends StatelessWidget {
  const _SignInButton({
    required this.userProfile,
    required this.didLogin,
  });

  final UserProfilePB userProfile;
  final VoidCallback didLogin;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 48,
          child: FlowyTextButton(
            LocaleKeys.settings_account_login_loginLabel.tr(),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            fontWeight: FontWeight.w600,
            radius: BorderRadius.circular(12),
            fillColor: Theme.of(context).colorScheme.primary,
            hoverColor: const Color(0xFF005483),
            fontHoverColor: Colors.white,
            onPressed: () {
              SettingsAlertDialog(
                title: LocaleKeys.settings_account_login_loginLabel.tr(),
                children: [
                  SettingThirdPartyLogin(
                    didLogin: didLogin,
                  ),
                ],
              ).show(context);
            },
          ),
        ),
      ],
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({
    required this.userProfile,
    required this.didLogout,
  });

  final UserProfilePB userProfile;
  final VoidCallback didLogout;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 48,
          child: FlowyTextButton(
            LocaleKeys.settings_account_login_logoutLabel.tr(),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            fontWeight: FontWeight.w600,
            radius: BorderRadius.circular(12),
            fillColor: Theme.of(context).colorScheme.primary,
            hoverColor: const Color(0xFF005483),
            fontHoverColor: Colors.white,
            onPressed: () {
              SettingsAlertDialog(
                title: LocaleKeys.settings_account_login_logoutLabel,
                subtitle: switch (userProfile.encryptionType) {
                  EncryptionTypePB.Symmetric =>
                    LocaleKeys.settings_menu_selfEncryptionLogoutPrompt.tr(),
                  _ => LocaleKeys.settings_menu_logoutPrompt.tr(),
                },
                confirm: () async {
                  await getIt<AuthService>().signOut();
                  didLogout();
                },
              ).show(context);
            },
          ),
        ),
      ],
    );
  }
}

class _UserProfileSetting extends StatefulWidget {
  const _UserProfileSetting({
    required this.name,
    required this.iconUrl,
    this.onSave,
  });

  final String name;
  final String iconUrl;
  final void Function(String)? onSave;

  @override
  State<_UserProfileSetting> createState() => _UserProfileSettingState();
}

class _UserProfileSettingState extends State<_UserProfileSetting> {
  late final FocusNode focusNode;
  bool isEditing = false;
  bool isHoveringProfileImage = false;

  @override
  void initState() {
    focusNode = FocusNode(
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape &&
            isEditing) {
          setState(() => isEditing = false);
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
    );
    super.initState();
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _showIconPickerDialog(context),
              child: FlowyHover(
                resetHoverOnRebuild: false,
                onHover: (isHovering) =>
                    setState(() => isHoveringProfileImage = isHovering),
                style: HoverStyle(
                  hoverColor: Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    UserAvatar(
                      iconUrl: widget.iconUrl,
                      name: widget.name,
                      isLarge: true,
                      isHovering: isHoveringProfileImage,
                    ),
                    const VSpace(4),
                    FlowyText.regular(
                      LocaleKeys.settings_account_general_changeProfilePicture
                          .tr(),
                      color: AFThemeExtension.of(context).textColor,
                    ),
                  ],
                ),
              ),
            ),
            if (widget.iconUrl.isNotEmpty)
              Positioned(
                right: 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context
                      .read<SettingsUserViewBloc>()
                      .add(const SettingsUserEvent.removeUserIcon()),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: FlowyHover(
                      resetHoverOnRebuild: false,
                      style: const HoverStyle(
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                        hoverColor: Color(0xFF005483),
                      ),
                      builder: (_, isHovering) => Padding(
                        padding: const EdgeInsets.all(4),
                        child: FlowySvg(
                          FlowySvgs.close_s,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const HSpace(16),
        if (!isEditing) ...[
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: FlowyText.medium(
                    widget.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const HSpace(4),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => isEditing = true),
                  child: const FlowyHover(
                    resetHoverOnRebuild: false,
                    child: Padding(
                      padding: EdgeInsets.all(4),
                      child: FlowySvg(FlowySvgs.edit_s),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Flexible(
            child: SettingsInputField(
              value: widget.name,
              focusNode: focusNode..requestFocus(),
              onSave: (val) {
                widget.onSave?.call(val);
                setState(() => isEditing = false);
              },
              onCancel: () => setState(() => isEditing = false),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _showIconPickerDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: FlowyText.medium(
          LocaleKeys.settings_user_selectAnIcon.tr(),
          fontSize: FontSizes.s16,
        ),
        children: [
          Container(
            height: 380,
            width: 360,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: FlowyEmojiPicker(
              onEmojiSelected: (_, emoji) {
                context
                    .read<SettingsUserViewBloc>()
                    .add(SettingsUserEvent.updateUserIcon(iconUrl: emoji));
                Navigator.of(dialogContext).pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}
