import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/widgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
            const Spacer(
              flex: 4,
            ),
            const FlowySvg(
              FlowySvgs.flowy_logo_xl,
              size: Size.square(64),
              blendMode: null,
            ),
            const VSpace(spacing * 2),
            // Welcome to
            FlowyText(
              LocaleKeys.welcomeTo.tr(),
              textAlign: TextAlign.center,
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
            // AppFlowy
            FlowyText(
              LocaleKeys.appName.tr(),
              textAlign: TextAlign.center,
              fontSize: 32,
              color: const Color(0xFF00BCF0),
              fontWeight: FontWeight.w700,
            ),
            const VSpace(spacing),
            const Spacer(
              flex: 2,
            ),

            // disable anonymous sign in release mode.
            if (kDebugMode) ...[
              const SignInAnonymousButton(),
              const VSpace(spacing),
            ],

            // if the cloud env is enabled, show the third-party sign in buttons.
            if (isAuthEnabled) ...[
              if (kDebugMode) ...[
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
                const VSpace(spacing),
              ],
              const ThirdPartySignInButtons(),
            ],
            if (!isAuthEnabled)
              const Spacer(
                flex: 2,
              ),
            const VSpace(spacing),
          ],
        ),
      ),
    );
  }
}
