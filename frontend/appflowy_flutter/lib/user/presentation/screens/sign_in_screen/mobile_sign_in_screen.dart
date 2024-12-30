import 'dart:io';

import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/setting/launch_settings_page.dart';
import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/widgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class MobileSignInScreen extends StatelessWidget {
  const MobileSignInScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const double spacing = 16;
    final colorScheme = Theme.of(context).colorScheme;
    return BlocBuilder<SignInBloc, SignInState>(
      builder: (context, state) {
        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: Padding(
            padding: const EdgeInsets.symmetric(vertical: 38, horizontal: 40),
            child: Column(
              children: [
                const Spacer(flex: 4),
                _buildLogo(),
                const VSpace(spacing),
                _buildAppNameText(colorScheme),
                const VSpace(spacing * 2),
                const SignInWithMagicLinkButtons(),
                const VSpace(spacing),
                if (isAuthEnabled) _buildThirdPartySignInButtons(colorScheme),
                const VSpace(spacing * 1.5),
                const SignInAgreement(),
                const VSpace(spacing),
                if (!isAuthEnabled) const Spacer(flex: 2),
                const Spacer(flex: 2),
                const Spacer(),
                Expanded(child: _buildSettingsButton(context)),
                if (Platform.isAndroid) const Spacer(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogo() {
    return const FlowySvg(
      FlowySvgs.flowy_logo_xl,
      size: Size.square(56),
      blendMode: null,
    );
  }

  Widget _buildAppNameText(ColorScheme colorScheme) {
    return FlowyText(
      LocaleKeys.appName.tr(),
      textAlign: TextAlign.center,
      fontSize: 28,
      color: const Color(0xFF00BCF0),
      fontWeight: FontWeight.w700,
    );
  }

  Widget _buildThirdPartySignInButtons(ColorScheme colorScheme) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: FlowyText(
                LocaleKeys.signIn_or.tr(),
                fontSize: 12,
                color: colorScheme.onSecondary,
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const VSpace(16),
        // expand third-party sign in buttons on Android by default.
        // on iOS, the github and discord buttons are collapsed by default.
        ThirdPartySignInButtons(
          expanded: Platform.isAndroid,
        ),
      ],
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FlowyButton(
          useIntrinsicWidth: true,
          text: FlowyText(
            LocaleKeys.signIn_settings.tr(),
            textAlign: TextAlign.center,
            fontSize: 12.0,
            // fontWeight: FontWeight.w500,
            color: Colors.grey,
            decoration: TextDecoration.underline,
          ),
          onTap: () {
            context.push(MobileLaunchSettingsPage.routeName);
          },
        ),
        const HSpace(24),
        const SignInAnonymousButtonV2(),
      ],
    );
  }
}
