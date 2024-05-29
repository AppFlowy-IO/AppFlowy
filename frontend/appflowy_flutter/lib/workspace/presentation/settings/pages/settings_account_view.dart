import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/base/icon/icon_picker.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/workspace/application/user/settings_user_bloc.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_alert_dialog.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_category.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_input_field.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/setting_third_party_login.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy/workspace/presentation/widgets/user_avatar.dart';
import 'package:appflowy_backend/protobuf/flowy-user/auth.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
          return SettingsBody(
            title: LocaleKeys.settings_accountPage_title.tr(),
            description: LocaleKeys.settings_accountPage_description.tr(),
            children: [
              SettingsCategory(
                title: LocaleKeys.settings_accountPage_general_title.tr(),
                children: [
                  UserProfileSetting(
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

              // Only show email if the user is authenticated and not using local auth
              if (isAuthEnabled &&
                  state.userProfile.authenticator != AuthenticatorPB.Local) ...[
                SettingsCategory(
                  title: LocaleKeys.settings_accountPage_email_title.tr(),
                  children: [
                    FlowyText.regular(state.userProfile.email),
                    // Enable when/if we need change email feature
                    // SingleSettingAction(
                    //   label: state.userProfile.email,
                    //   buttonLabel: LocaleKeys
                    //       .settings_accountPage_email_actions_change
                    //       .tr(),
                    //   onPressed: () => SettingsAlertDialog(
                    //     title: LocaleKeys
                    //         .settings_accountPage_email_actions_change
                    //         .tr(),
                    //     confirmLabel: LocaleKeys.button_save.tr(),
                    //     confirm: () {
                    //       context.read<SettingsUserViewBloc>().add(
                    //             SettingsUserEvent.updateUserEmail(
                    //               _emailController.text,
                    //             ),
                    //           );
                    //       Navigator.of(context).pop();
                    //     },
                    //     children: [
                    //       SettingsInputField(
                    //         label: LocaleKeys.settings_accountPage_email_title
                    //             .tr(),
                    //         value: state.userProfile.email,
                    //         hideActions: true,
                    //         textController: _emailController,
                    //       ),
                    //     ],
                    //   ).show(context),
                    // ),
                  ],
                ),
              ],

              /// Enable when we have change password feature and 2FA
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
              SettingsCategory(
                title: LocaleKeys.settings_accountPage_keys_title.tr(),
                children: [
                  SettingsInputField(
                    label:
                        LocaleKeys.settings_accountPage_keys_openAILabel.tr(),
                    tooltip:
                        LocaleKeys.settings_accountPage_keys_openAITooltip.tr(),
                    placeholder:
                        LocaleKeys.settings_accountPage_keys_openAIHint.tr(),
                    value: state.userProfile.openaiKey,
                    obscureText: true,
                    onSave: (key) => context
                        .read<SettingsUserViewBloc>()
                        .add(SettingsUserEvent.updateUserOpenAIKey(key)),
                  ),
                  SettingsInputField(
                    label: LocaleKeys.settings_accountPage_keys_stabilityAILabel
                        .tr(),
                    tooltip: LocaleKeys
                        .settings_accountPage_keys_stabilityAITooltip
                        .tr(),
                    placeholder: LocaleKeys
                        .settings_accountPage_keys_stabilityAIHint
                        .tr(),
                    value: state.userProfile.stabilityAiKey,
                    obscureText: true,
                    onSave: (key) => context
                        .read<SettingsUserViewBloc>()
                        .add(SettingsUserEvent.updateUserStabilityAIKey(key)),
                  ),
                ],
              ),
              SettingsCategory(
                title: LocaleKeys.settings_accountPage_login_title.tr(),
                children: [
                  SignInOutButton(
                    userProfile: state.userProfile,
                    onAction:
                        state.userProfile.authenticator == AuthenticatorPB.Local
                            ? widget.didLogin
                            : widget.didLogout,
                    signIn: state.userProfile.authenticator ==
                        AuthenticatorPB.Local,
                  ),
                ],
              ),

              /// Enable when we can delete accounts
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
          );
        },
      ),
    );
  }
}

@visibleForTesting
class SignInOutButton extends StatelessWidget {
  const SignInOutButton({
    super.key,
    required this.userProfile,
    required this.onAction,
    this.signIn = true,
  });

  final UserProfilePB userProfile;
  final VoidCallback onAction;
  final bool signIn;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 48,
          child: FlowyTextButton(
            signIn
                ? LocaleKeys.settings_accountPage_login_loginLabel.tr()
                : LocaleKeys.settings_accountPage_login_logoutLabel.tr(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            fontWeight: FontWeight.w600,
            radius: BorderRadius.circular(12),
            fillColor: Theme.of(context).colorScheme.primary,
            hoverColor: const Color(0xFF005483),
            fontHoverColor: Colors.white,
            onPressed: () => SettingsAlertDialog(
              title: signIn
                  ? LocaleKeys.settings_accountPage_login_loginLabel.tr()
                  : LocaleKeys.settings_accountPage_login_logoutLabel.tr(),
              subtitle: signIn
                  ? null
                  : switch (userProfile.encryptionType) {
                      EncryptionTypePB.Symmetric => LocaleKeys
                          .settings_menu_selfEncryptionLogoutPrompt
                          .tr(),
                      _ => LocaleKeys.settings_menu_logoutPrompt.tr(),
                    },
              implyLeading: signIn,
              confirm: !signIn
                  ? () async {
                      await getIt<AuthService>().signOut();
                      onAction();
                    }
                  : null,
              children:
                  signIn ? [SettingThirdPartyLogin(didLogin: onAction)] : null,
            ).show(context),
          ),
        ),
      ],
    );
  }
}

@visibleForTesting
class UserProfileSetting extends StatefulWidget {
  const UserProfileSetting({
    super.key,
    required this.name,
    required this.iconUrl,
    this.onSave,
  });

  final String name;
  final String iconUrl;
  final void Function(String)? onSave;

  @override
  State<UserProfileSetting> createState() => _UserProfileSettingState();
}

class _UserProfileSettingState extends State<UserProfileSetting> {
  late final _nameController = TextEditingController(text: widget.name);
  late final FocusNode focusNode;
  bool isEditing = false;
  bool isHovering = false;

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode(
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape &&
            isEditing &&
            mounted) {
          setState(() => isEditing = false);
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
    )..addListener(() {
        if (!focusNode.hasFocus && isEditing && mounted) {
          widget.onSave?.call(_nameController.text);
          setState(() => isEditing = false);
        }
      });
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
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _showIconPickerDialog(context),
          child: FlowyHover(
            resetHoverOnRebuild: false,
            onHover: (state) => setState(() => isHovering = state),
            style: HoverStyle(
              hoverColor: Colors.transparent,
              borderRadius: BorderRadius.circular(100),
            ),
            child: FlowyTooltip(
              message: LocaleKeys
                  .settings_accountPage_general_changeProfilePicture
                  .tr(),
              child: UserAvatar(
                iconUrl: widget.iconUrl,
                name: widget.name,
                size: 48,
                fontSize: 24,
                isHovering: isHovering,
              ),
            ),
          ),
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
              textController: _nameController,
              value: widget.name,
              focusNode: focusNode..requestFocus(),
              onCancel: () => setState(() => isEditing = false),
              onSave: (val) {
                widget.onSave?.call(val);
                setState(() => isEditing = false);
              },
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
        children: [
          Container(
            height: 380,
            width: 360,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: FlowyIconPicker(
              onSelected: (r) {
                context
                    .read<SettingsUserViewBloc>()
                    .add(SettingsUserEvent.updateUserIcon(iconUrl: r.emoji));
                Navigator.of(dialogContext).pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}
