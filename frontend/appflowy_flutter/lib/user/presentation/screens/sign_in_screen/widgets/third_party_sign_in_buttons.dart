import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:appflowy/user/presentation/presentation.dart';
import 'package:appflowy/util/platform_extension.dart';
import 'package:appflowy/workspace/application/appearance.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ThirdPartySignInButtons extends StatelessWidget {
  /// Used in DesktopSignInScreen, MobileSignInScreen and SettingThirdPartyLogin
  const ThirdPartySignInButtons({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Get themeMode from AppearanceSettingsCubit
    // When user changes themeMode, it changes the state in AppearanceSettingsCubit, but the themeMode for the MaterialApp won't change, it only got updated(get value from AppearanceSettingsCubit) when user open the app again. Thus, we should get themeMode from AppearanceSettingsCubit rather than MediaQuery.
    final isDarkMode =
        context.read<AppearanceSettingsCubit>().state.themeMode ==
            ThemeMode.dark;

    return Column(
      children: [
        _ThirdPartySignInButton(
          key: const Key('signInWithGoogleButton'),
          icon: FlowySvgs.google_mark_xl,
          labelText: LocaleKeys.signIn_LogInWithGoogle.tr(),
          onPressed: () {
            _signInWithGoogle(context);
          },
        ),
        const VSpace(8),
        _ThirdPartySignInButton(
          icon: isDarkMode
              ? FlowySvgs.github_mark_white_xl
              : FlowySvgs.github_mark_black_xl,
          labelText: LocaleKeys.signIn_LogInWithGithub.tr(),
          onPressed: () {
            _signInWithGithub(context);
          },
        ),
        const VSpace(8),
        _ThirdPartySignInButton(
          icon: isDarkMode
              ? FlowySvgs.discord_mark_white_xl
              : FlowySvgs.discord_mark_blurple_xl,
          labelText: LocaleKeys.signIn_LogInWithDiscord.tr(),
          onPressed: () {
            _signInWithDiscord(context);
          },
        ),
      ],
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
    final style = Theme.of(context);
    final isMobile = PlatformExtension.isMobile;
    if (isMobile) {
      // Use LayoutBuilder to get the maxWidth of parent widget(Column) and set the icon occupied area to 1/4 of maxWidth.
      return LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              icon: Container(
                width: constraints.maxWidth / 4,
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 24,
                  child: FlowySvg(
                    icon,
                    blendMode: null,
                  ),
                ),
              ),
              label: Container(
                padding: const EdgeInsets.only(left: 4),
                alignment: Alignment.centerLeft,
                child: Text(labelText),
              ),
              onPressed: onPressed,
            ),
          );
        },
      );
    }
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
          overlayColor: MaterialStateProperty.resolveWith<Color?>(
            (states) {
              if (states.contains(MaterialState.hovered)) {
                return style.colorScheme.onSecondaryContainer;
              }
              return null;
            },
          ),
          shape: MaterialStateProperty.all(
            const RoundedRectangleBorder(
              borderRadius: Corners.s6Border,
            ),
          ),
          side: MaterialStateProperty.all(
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
  getIt<KeyValueStorage>().set(KVKeys.loginType, 'supabase');
  context.read<SignInBloc>().add(
        const SignInEvent.signedInWithOAuth('google'),
      );
}

void _signInWithGithub(BuildContext context) {
  getIt<KeyValueStorage>().set(KVKeys.loginType, 'supabase');
  context.read<SignInBloc>().add(const SignInEvent.signedInWithOAuth('github'));
}

void _signInWithDiscord(BuildContext context) {
  getIt<KeyValueStorage>().set(KVKeys.loginType, 'supabase');
  context
      .read<SignInBloc>()
      .add(const SignInEvent.signedInWithOAuth('discord'));
}
