import 'dart:async';

import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/base/emoji/emoji_picker.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/util/debounce.dart';
import 'package:appflowy/workspace/application/user/settings_user_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy/workspace/presentation/widgets/user_avatar.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'setting_third_party_login.dart';

const defaultUserAvatar = '1F600';
const _iconSize = Size(60, 60);

class SettingsUserView extends StatelessWidget {
  SettingsUserView(
    this.user, {
    required this.didLogin,
    required this.didLogout,
    required this.didOpenUser,
  }) : super(key: ValueKey(user.id));

  // Called when the user login in the setting dialog
  final VoidCallback didLogin;
  // Called when the user logout in the setting dialog
  final VoidCallback didLogout;
  // Called when the user open a historical user in the setting dialog
  final VoidCallback didOpenUser;
  final UserProfilePB user;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsUserViewBloc>(
      create: (context) => getIt<SettingsUserViewBloc>(param1: user)
        ..add(const SettingsUserEvent.initial()),
      child: BlocBuilder<SettingsUserViewBloc, SettingsUserState>(
        builder: (context, state) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildUserIconSetting(context),
              if (isAuthEnabled &&
                  user.authenticator != AuthenticatorPB.Local) ...[
                const VSpace(12),
                UserEmailInput(user.email),
              ],
              const VSpace(12),
              _renderCurrentOpenaiKey(context),
              const VSpace(12),
              _renderCurrentStabilityAIKey(context),
              const VSpace(12),
              _renderLoginOrLogoutButton(context, state),
              const VSpace(12),
            ],
          ),
        ),
      ),
    );
  }

  Row _buildUserIconSetting(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _showIconPickerDialog(context),
          child: FlowyHover(
            style: const HoverStyle.transparent(),
            builder: (context, onHover) {
              Widget avatar = UserAvatar(
                iconUrl: user.iconUrl,
                name: user.name,
                isLarge: true,
              );

              if (onHover) {
                avatar = _avatarOverlay(
                  context: context,
                  hasIcon: user.iconUrl.isNotEmpty,
                  child: avatar,
                );
              }

              return avatar;
            },
          ),
        ),
        const HSpace(12),
        Flexible(child: _renderUserNameInput(context)),
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

  /// Renders either a login or logout button based on the user's authentication status, or nothing if Supabase is not enabled.
  ///
  /// This function checks the current user's authentication type and Supabase
  /// configuration to determine whether to render a third-party login button
  /// or a logout button.
  Widget _renderLoginOrLogoutButton(
    BuildContext context,
    SettingsUserState state,
  ) {
    if (!isAuthEnabled) {
      return const SizedBox.shrink();
    }

    // If the user is logged in locally, render a third-party login button.
    if (state.userProfile.authenticator == AuthenticatorPB.Local) {
      return SettingThirdPartyLogin(didLogin: didLogin);
    }

    return SettingLogoutButton(user: user, didLogout: didLogout);
  }

  Widget _renderUserNameInput(BuildContext context) {
    final String name =
        context.read<SettingsUserViewBloc>().state.userProfile.name;
    return UserNameInput(name);
  }

  Widget _renderCurrentOpenaiKey(BuildContext context) {
    final String accessKey =
        context.read<SettingsUserViewBloc>().state.userProfile.openaiKey;
    return _AIAccessKeyInput(
      accessKey: accessKey,
      title: 'OpenAI Key',
      hintText: LocaleKeys.settings_user_pleaseInputYourOpenAIKey.tr(),
      callback: (key) => context
          .read<SettingsUserViewBloc>()
          .add(SettingsUserEvent.updateUserOpenAIKey(key)),
    );
  }

  Widget _renderCurrentStabilityAIKey(BuildContext context) {
    final String accessKey =
        context.read<SettingsUserViewBloc>().state.userProfile.stabilityAiKey;
    return _AIAccessKeyInput(
      accessKey: accessKey,
      title: 'Stability AI Key',
      hintText: LocaleKeys.settings_user_pleaseInputYourStabilityAIKey.tr(),
      callback: (key) => context
          .read<SettingsUserViewBloc>()
          .add(SettingsUserEvent.updateUserStabilityAIKey(key)),
    );
  }

  Widget _avatarOverlay({
    required BuildContext context,
    required bool hasIcon,
    required Widget child,
  }) =>
      FlowyTooltip(
        message: LocaleKeys.settings_user_tooltipSelectIcon.tr(),
        child: Stack(
          children: [
            Container(
              width: 56,
              height: 56,
              foregroundDecoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withOpacity(hasIcon ? 0.8 : 0.5),
                shape: BoxShape.circle,
              ),
              child: child,
            ),
            const Positioned(
              top: 0,
              left: 0,
              bottom: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: FlowySvg(FlowySvgs.emoji_s),
                ),
              ),
            ),
          ],
        ),
      );
}

@visibleForTesting
class UserNameInput extends StatefulWidget {
  const UserNameInput(this.name, {super.key});

  final String name;

  @override
  UserNameInputState createState() => UserNameInputState();
}

class UserNameInputState extends State<UserNameInput> {
  late TextEditingController _controller;

  Timer? _debounce;
  final Duration _debounceDuration = const Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: LocaleKeys.settings_user_name.tr(),
        labelStyle: Theme.of(context)
            .textTheme
            .titleMedium!
            .copyWith(fontWeight: FontWeight.w500),
        enabledBorder: UnderlineInputBorder(
          borderSide:
              BorderSide(color: Theme.of(context).colorScheme.onBackground),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
      ),
      onChanged: (val) {
        if (_debounce?.isActive ?? false) {
          _debounce!.cancel();
        }

        _debounce = Timer(_debounceDuration, () {
          context
              .read<SettingsUserViewBloc>()
              .add(SettingsUserEvent.updateUserName(val));
        });
      },
    );
  }
}

@visibleForTesting
class UserEmailInput extends StatefulWidget {
  const UserEmailInput(this.email, {super.key});

  final String email;

  @override
  UserEmailInputState createState() => UserEmailInputState();
}

class UserEmailInputState extends State<UserEmailInput> {
  late TextEditingController _controller;

  Timer? _debounce;
  final Duration _debounceDuration = const Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.email);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: LocaleKeys.settings_user_email.tr(),
        labelStyle: Theme.of(context)
            .textTheme
            .titleMedium!
            .copyWith(fontWeight: FontWeight.w500),
        enabledBorder: UnderlineInputBorder(
          borderSide:
              BorderSide(color: Theme.of(context).colorScheme.onBackground),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
      ),
      onChanged: (val) {
        if (_debounce?.isActive ?? false) {
          _debounce!.cancel();
        }

        _debounce = Timer(_debounceDuration, () {
          context
              .read<SettingsUserViewBloc>()
              .add(SettingsUserEvent.updateUserEmail(val));
        });
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}

class _AIAccessKeyInput extends StatefulWidget {
  const _AIAccessKeyInput({
    required this.accessKey,
    required this.title,
    required this.hintText,
    required this.callback,
  });

  final String accessKey;
  final String title;
  final String hintText;
  final void Function(String key) callback;

  @override
  State<_AIAccessKeyInput> createState() => _AIAccessKeyInputState();
}

class _AIAccessKeyInputState extends State<_AIAccessKeyInput> {
  bool visible = false;
  final textEditingController = TextEditingController();
  final debounce = Debounce();

  @override
  void initState() {
    super.initState();
    textEditingController.text = widget.accessKey;
  }

  @override
  void dispose() {
    textEditingController.dispose();
    debounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: textEditingController,
      obscureText: !visible,
      decoration: InputDecoration(
        enabledBorder: UnderlineInputBorder(
          borderSide:
              BorderSide(color: Theme.of(context).colorScheme.onBackground),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
        labelText: widget.title,
        labelStyle: Theme.of(context)
            .textTheme
            .titleMedium!
            .copyWith(fontWeight: FontWeight.w500),
        hintText: widget.hintText,
        suffixIcon: FlowyIconButton(
          width: 40,
          height: 40,
          hoverColor: Theme.of(context).colorScheme.secondaryContainer,
          icon: Icon(
            visible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              visible = !visible;
            });
          },
        ),
      ),
      onChanged: (value) {
        debounce.call(() {
          widget.callback(value);
        });
      },
    );
  }
}

typedef SelectIconCallback = void Function(String iconUrl, bool isSelected);

final builtInSVGIcons = [
  '1F9CC',
  '1F9DB',
  '1F9DD-200D-2642-FE0F',
  '1F9DE-200D-2642-FE0F',
  '1F9DF',
  '1F42F',
  '1F43A',
  '1F431',
  '1F435',
  '1F600',
  '1F984',
];

// REMOVE this widget in next version 0.3.10
class IconGallery extends StatelessWidget {
  const IconGallery({
    super.key,
    required this.selectedIcon,
    required this.onSelectIcon,
    this.defaultOption,
  });

  final String selectedIcon;
  final SelectIconCallback onSelectIcon;
  final Widget? defaultOption;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: const EdgeInsets.all(20),
      crossAxisCount: 5,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      children: [
        if (defaultOption != null) defaultOption!,
        ...builtInSVGIcons.mapIndexed(
          (int index, String iconUrl) => IconOption(
            emoji: FlowySvgData('emoji/$iconUrl'),
            iconUrl: iconUrl,
            onSelectIcon: onSelectIcon,
            isSelected: iconUrl == selectedIcon,
          ),
        ),
      ],
    );
  }
}

class IconOption extends StatelessWidget {
  IconOption({
    required this.emoji,
    required this.iconUrl,
    required this.onSelectIcon,
    required this.isSelected,
  }) : super(key: ValueKey(emoji));

  final FlowySvgData emoji;
  final String iconUrl;
  final SelectIconCallback onSelectIcon;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: Corners.s8Border,
      hoverColor: Theme.of(context).colorScheme.tertiaryContainer,
      onTap: () => onSelectIcon(iconUrl, isSelected),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: Corners.s8Border,
        ),
        child: FlowySvg(
          emoji,
          size: _iconSize,
          blendMode: null,
        ),
      ),
    );
  }
}

class SettingLogoutButton extends StatelessWidget {
  const SettingLogoutButton({
    super.key,
    required this.user,
    required this.didLogout,
  });

  final UserProfilePB user;
  final VoidCallback didLogout;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 160,
        child: FlowyButton(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 2.0),
          text: FlowyText.medium(
            LocaleKeys.settings_menu_logout.tr(),
            fontSize: 13,
            textAlign: TextAlign.center,
          ),
          onTap: () {
            NavigatorAlertDialog(
              title: logoutPromptMessage(),
              confirm: () async {
                await getIt<AuthService>().signOut();
                didLogout();
              },
            ).show(context);
          },
        ),
      ),
    );
  }

  String logoutPromptMessage() {
    switch (user.encryptionType) {
      case EncryptionTypePB.Symmetric:
        return LocaleKeys.settings_menu_selfEncryptionLogoutPrompt.tr();
      default:
        return LocaleKeys.settings_menu_logoutPrompt.tr();
    }
  }
}
