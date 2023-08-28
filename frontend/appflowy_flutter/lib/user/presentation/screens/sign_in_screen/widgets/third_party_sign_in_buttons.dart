import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ThirdPartySignInButtons extends StatelessWidget {
  final bool isMobile;
  final Alignment contentAlignment;

  /// Used in DesktopSignInScreen and MobileSignInScreen
  const ThirdPartySignInButtons({
    super.key,
    required this.isMobile,
    this.contentAlignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    // Leave for future implementation
    // final isDarkMode =
    //     MediaQuery.of(context).platformBrightness == Brightness.dark;
    if (isMobile) {
      return _ThirdPartySignInButton(
        isMobile: true,
        icon: FlowySvgs.google_mark_xl,
        labelText: LocaleKeys.signIn_LogInWithGoogle.tr(),
        onPressed: () {
          _signInWithGoogle(context);
        },
        contentAlignment: contentAlignment,
      );
    }
    return Column(
      children: [
        _ThirdPartySignInButton(
          key: const Key('signInWithGoogleButton'),
          isMobile: false,
          icon: FlowySvgs.google_mark_xl,
          labelText: LocaleKeys.signIn_LogInWithGoogle.tr(),
          contentAlignment: contentAlignment,
          onPressed: () {
            _signInWithGoogle(context);
          },
        ),
        // Leave for future implementation
        // const SizedBox(height: 8),
        // _ThirdPartySignInButton(
        //   icon: isDarkMode
        //       ? FlowySvgs.github_mark_white_xl
        //       : FlowySvgs.github_mark_black_xl,
        //   labelText: LocaleKeys.signIn_LogInWithGithub.tr(),
        //   contentAlignment: contentAlignment,
        //   onPressed: () {
        //     getIt<KeyValueStorage>().set(KVKeys.loginType, 'supabase');
        //     context
        //         .read<SignInBloc>()
        //         .add(const SignInEvent.signedInWithOAuth('github'));
        //   },
        // ),
        // const SizedBox(height: 8),
        // _ThirdPartySignInButton(
        //   icon: isDarkMode
        //       ? FlowySvgs.discord_mark_white_xl
        //       : FlowySvgs.discord_mark_blurple_xl,
        //   labelText: LocaleKeys.signIn_LogInWithDiscord.tr(),
        //   contentAlignment: contentAlignment,
        //   onPressed: () {
        //     getIt<KeyValueStorage>().set(KVKeys.loginType, 'supabase');
        //     context
        //         .read<SignInBloc>()
        //         .add(const SignInEvent.signedInWithOAuth('discord'));
        //   },
        // ),
      ],
    );
  }
}

class _ThirdPartySignInButton extends StatelessWidget {
  const _ThirdPartySignInButton({
    super.key,
    required this.isMobile,
    required this.icon,
    required this.labelText,
    required this.onPressed,
    required this.contentAlignment,
  });

  final bool isMobile;
  final FlowySvgData icon;
  final String labelText;
  final Alignment contentAlignment;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context);
    if (isMobile) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: OutlinedButton.icon(
          icon: FlowySvg(
            icon,
            size: const Size.square(18),
            blendMode: null,
          ),
          label: Text(labelText),
          style: ButtonStyle(
            alignment: contentAlignment,
          ),
          onPressed: onPressed,
        ),
      );
    }
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: FlowySvg(
          icon,
          size: const Size.square(24),
          blendMode: null,
        ),
        label: FlowyText(
          labelText,
          fontSize: 14,
        ),
        style: ButtonStyle(
          alignment: contentAlignment,
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
