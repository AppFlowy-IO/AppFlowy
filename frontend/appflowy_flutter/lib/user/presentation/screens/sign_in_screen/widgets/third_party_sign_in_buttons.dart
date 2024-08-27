import 'dart:io';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:appflowy/user/presentation/presentation.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'third_party_sign_in_button.dart';

@visibleForTesting
const Key signInWithGoogleButtonKey = Key('signInWithGoogleButton');

class ThirdPartySignInButtons extends StatefulWidget {
  /// Used in DesktopSignInScreen, MobileSignInScreen and SettingThirdPartyLogin
  const ThirdPartySignInButtons({
    super.key,
    this.expanded = false,
  });

  final bool expanded;

  @override
  State<ThirdPartySignInButtons> createState() =>
      _ThirdPartySignInButtonsState();
}

class _ThirdPartySignInButtonsState extends State<ThirdPartySignInButtons> {
  bool expanded = false;

  @override
  void initState() {
    super.initState();

    expanded = widget.expanded;
  }

  @override
  Widget build(BuildContext context) {
    if (PlatformExtension.isDesktopOrWeb) {
      const padding = 16.0;
      return Column(
        children: [
          _DesktopSignInButton(
            key: signInWithGoogleButtonKey,
            type: ThirdPartySignInButtonType.google,
            onPressed: () {
              _signInWithGoogle(context);
            },
          ),
          const VSpace(padding),
          _DesktopSignInButton(
            type: ThirdPartySignInButtonType.github,
            onPressed: () {
              _signInWithGithub(context);
            },
          ),
          const VSpace(padding),
          _DesktopSignInButton(
            type: ThirdPartySignInButtonType.discord,
            onPressed: () {
              _signInWithDiscord(context);
            },
          ),
        ],
      );
    } else {
      const padding = 8.0;
      return BlocBuilder<SignInBloc, SignInState>(
        builder: (context, state) {
          return Column(
            children: [
              if (Platform.isIOS) ...[
                MobileThirdPartySignInButton(
                  type: ThirdPartySignInButtonType.apple,
                  onPressed: () {
                    _signInWithApple(context);
                  },
                ),
                const VSpace(padding),
              ],
              MobileThirdPartySignInButton(
                type: ThirdPartySignInButtonType.google,
                onPressed: () {
                  _signInWithGoogle(context);
                },
              ),
              if (expanded) ...[
                const VSpace(padding),
                MobileThirdPartySignInButton(
                  type: ThirdPartySignInButtonType.github,
                  onPressed: () {
                    _signInWithGithub(context);
                  },
                ),
                const VSpace(padding),
                MobileThirdPartySignInButton(
                  type: ThirdPartySignInButtonType.discord,
                  onPressed: () {
                    _signInWithDiscord(context);
                  },
                ),
              ],
              if (!expanded) ...[
                const VSpace(padding * 2),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      expanded = !expanded;
                    });
                  },
                  child: FlowyText(
                    LocaleKeys.signIn_continueAnotherWay.tr(),
                    color: Theme.of(context).colorScheme.onSurface,
                    decoration: TextDecoration.underline,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          );
        },
      );
    }
  }

  void _signInWithApple(BuildContext context) {
    context.read<SignInBloc>().add(
          const SignInEvent.signedInWithOAuth('apple'),
        );
  }

  void _signInWithGoogle(BuildContext context) {
    context.read<SignInBloc>().add(
          const SignInEvent.signedInWithOAuth('google'),
        );
  }

  void _signInWithGithub(BuildContext context) {
    context
        .read<SignInBloc>()
        .add(const SignInEvent.signedInWithOAuth('github'));
  }

  void _signInWithDiscord(BuildContext context) {
    context
        .read<SignInBloc>()
        .add(const SignInEvent.signedInWithOAuth('discord'));
  }
}

class _DesktopSignInButton extends StatelessWidget {
  const _DesktopSignInButton({
    super.key,
    required this.type,
    required this.onPressed,
  });

  final ThirdPartySignInButtonType type;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context);
    // In desktop, the width of button is limited by [AuthFormContainer]
    return SizedBox(
      height: 48,
      width: AuthFormContainer.width,
      child: OutlinedButton.icon(
        // In order to align all the labels vertically in a relatively centered position to the button, we use a fixed width container to wrap the icon(align to the right), then use another container to align the label to left.
        icon: Container(
          width: AuthFormContainer.width / 4,
          alignment: Alignment.centerRight,
          child: SizedBox(
            // Some icons are not square, so we just use a fixed width here.
            width: 24,
            child: FlowySvg(
              type.icon,
              blendMode: type.blendMode,
            ),
          ),
        ),
        label: Container(
          padding: const EdgeInsets.only(left: 8),
          alignment: Alignment.centerLeft,
          child: FlowyText(
            type.labelText,
            fontSize: 14,
          ),
        ),
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.resolveWith<Color?>(
            (states) {
              if (states.contains(WidgetState.hovered)) {
                return style.colorScheme.onSecondaryContainer;
              }
              return null;
            },
          ),
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(
              borderRadius: Corners.s6Border,
            ),
          ),
          side: WidgetStateProperty.all(
            BorderSide(
              color: style.dividerColor,
            ),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
