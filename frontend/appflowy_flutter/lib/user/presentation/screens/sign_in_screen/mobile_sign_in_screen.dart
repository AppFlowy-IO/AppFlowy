import 'package:flutter/material.dart';

import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/setting/launch_settings_page.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/magic_link_sign_in_buttons.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/widgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:go_router/go_router.dart';

class MobileSignInScreen extends StatelessWidget {
  const MobileSignInScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const double spacing = 16;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 40),
        child: Column(
          children: [
            const Spacer(flex: 4),
            _buildLogo(),
            const VSpace(spacing * 2),
            _buildWelcomeText(),
            _buildAppNameText(colorScheme),
            const VSpace(spacing * 2),
            const SignInWithMagicLinkButtons(),
            const VSpace(spacing),
            if (isAuthEnabled) _buildThirdPartySignInButtons(colorScheme),
            const VSpace(spacing),
            const SignInAnonymousButtonV2(),
            const VSpace(spacing),
            _buildSettingsButton(context),
            if (!isAuthEnabled) const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeText() {
    return FlowyText(
      LocaleKeys.welcomeTo.tr(),
      textAlign: TextAlign.center,
      fontSize: 32,
      fontWeight: FontWeight.w700,
    );
  }

  Widget _buildLogo() {
    return const FlowySvg(
      FlowySvgs.flowy_logo_xl,
      size: Size.square(64),
      blendMode: null,
    );
  }

  Widget _buildAppNameText(ColorScheme colorScheme) {
    return FlowyText(
      LocaleKeys.appName.tr(),
      textAlign: TextAlign.center,
      fontSize: 32,
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
                color: colorScheme.onSecondary,
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const VSpace(16),
        const ThirdPartySignInButtons(),
      ],
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    return FlowyButton(
      text: FlowyText(
        LocaleKeys.signIn_settings.tr(),
        textAlign: TextAlign.center,
        fontSize: 12.0,
        fontWeight: FontWeight.w500,
        decoration: TextDecoration.underline,
      ),
      onTap: () {
        context.push(MobileLaunchSettingsPage.routeName);
      },
    );
  }
}
