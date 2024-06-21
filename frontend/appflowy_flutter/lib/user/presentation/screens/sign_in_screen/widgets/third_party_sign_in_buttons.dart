import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:appflowy/user/presentation/presentation.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/sign_in_or_logout_button.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ThirdPartySignInButtons extends StatelessWidget {
  /// Used in DesktopSignInScreen, MobileSignInScreen and SettingThirdPartyLogin
  const ThirdPartySignInButtons({super.key});

  @override
  Widget build(BuildContext context) {
    // Get themeMode from AppearanceSettingsCubit
    // When user changes themeMode, it changes the state in AppearanceSettingsCubit, but the themeMode for the MaterialApp won't change, it only got updated(get value from AppearanceSettingsCubit) when user open the app again. Thus, we should get themeMode from AppearanceSettingsCubit rather than MediaQuery.

    final themeModeFromCubit =
        context.watch<AppearanceSettingsCubit>().state.themeMode;

    final isDarkMode = themeModeFromCubit == ThemeMode.system
        ? MediaQuery.of(context).platformBrightness == Brightness.dark
        : themeModeFromCubit == ThemeMode.dark;

    return BlocBuilder<SignInBloc, SignInState>(
      builder: (context, state) {
        final (googleText, githubText, discordText) = switch (state.loginType) {
          LoginType.signIn => (
              LocaleKeys.signIn_signInWithGoogle.tr(),
              LocaleKeys.signIn_signInWithGithub.tr(),
              LocaleKeys.signIn_signInWithDiscord.tr()
            ),
          LoginType.signUp => (
              LocaleKeys.signIn_signUpWithGoogle.tr(),
              LocaleKeys.signIn_signUpWithGithub.tr(),
              LocaleKeys.signIn_signUpWithDiscord.tr()
            ),
        };
        return Column(
          children: [
            _ThirdPartySignInButton(
              key: const Key('signInWithGoogleButton'),
              icon: FlowySvgs.google_mark_xl,
              labelText: googleText,
              onPressed: () {
                _signInWithGoogle(context);
              },
            ),
            const VSpace(8),
            _ThirdPartySignInButton(
              icon: isDarkMode
                  ? FlowySvgs.github_mark_white_xl
                  : FlowySvgs.github_mark_black_xl,
              labelText: githubText,
              onPressed: () {
                _signInWithGithub(context);
              },
            ),
            const VSpace(8),
            _ThirdPartySignInButton(
              icon: isDarkMode
                  ? FlowySvgs.discord_mark_white_xl
                  : FlowySvgs.discord_mark_blurple_xl,
              labelText: discordText,
              onPressed: () {
                _signInWithDiscord(context);
              },
            ),
          ],
        );
      },
    );
  }
}

class _ThirdPartySignInButton extends StatelessWidget {
  /// Build button based on current Platform(mobile or desktop).
  const _ThirdPartySignInButton({
    super.key,
    required this.icon,
    required this.labelText,
    required this.onPressed,
  });

  final FlowySvgData icon;
  final String labelText;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (PlatformExtension.isMobile) {
      return MobileSignInOrLogoutButton(
        icon: icon,
        labelText: labelText,
        onPressed: onPressed,
      );
    } else {
      return _DesktopSignInButton(
        icon: icon,
        labelText: labelText,
        onPressed: onPressed,
      );
    }
  }
}

class _DesktopSignInButton extends StatelessWidget {
  const _DesktopSignInButton({
    required this.icon,
    required this.labelText,
    required this.onPressed,
  });

  final FlowySvgData icon;
  final String labelText;

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
              icon,
              blendMode: null,
            ),
          ),
        ),
        label: Container(
          padding: const EdgeInsets.only(left: 8),
          alignment: Alignment.centerLeft,
          child: FlowyText(
            labelText,
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

void _signInWithGoogle(BuildContext context) {
  context.read<SignInBloc>().add(
        const SignInEvent.signedInWithOAuth('google'),
      );
}

void _signInWithGithub(BuildContext context) {
  context.read<SignInBloc>().add(const SignInEvent.signedInWithOAuth('github'));
}

void _signInWithDiscord(BuildContext context) {
  context
      .read<SignInBloc>()
      .add(const SignInEvent.signedInWithOAuth('discord'));
}
