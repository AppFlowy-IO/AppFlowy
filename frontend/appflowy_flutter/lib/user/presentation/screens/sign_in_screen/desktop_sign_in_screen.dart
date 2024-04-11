import 'package:appflowy/core/frameless_window.dart';
import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/magic_link_sign_in_buttons.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/widgets.dart';
import 'package:appflowy/user/presentation/widgets/widgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class DesktopSignInScreen extends StatelessWidget {
  const DesktopSignInScreen({super.key, required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    const indicatorMinHeight = 4.0;
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size(double.infinity, 60),
        child: MoveWindowDetector(),
      ),
      body: Center(
        child: AuthFormContainer(
          children: [
            FlowyLogoTitle(
              title: LocaleKeys.welcomeText.tr(),
              logoSize: const Size(60, 60),
            ),
            const VSpace(30),

            // const SignInAnonymousButton(),
            const SignInWithMagicLinkButtons(),

            // third-party sign in.
            const VSpace(20),

            if (isAuthEnabled) ...[
              const _OrDivider(),
              const VSpace(10),
              const ThirdPartySignInButtons(),
            ],
            const VSpace(20),

            // anonymous sign in
            const SignInAnonymousButtonV2(),

            // loading status
            const VSpace(indicatorMinHeight),
            isLoading
                ? const LinearProgressIndicator(
                    minHeight: indicatorMinHeight,
                  )
                : const VSpace(indicatorMinHeight),
            const VSpace(20),
          ],
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Flexible(
          child: Divider(
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: FlowyText.regular(LocaleKeys.signIn_or.tr()),
        ),
        const Flexible(
          child: Divider(
            thickness: 1,
          ),
        ),
      ],
    );
  }
}
