import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/widgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class MobileSignInScreen extends StatelessWidget {
  const MobileSignInScreen({super.key, required this.isLoading});
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    const double spacing = 16;
    // Welcome to Appflowy
    final welcomeString = LocaleKeys.welcomeText.tr();
    final style = Theme.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: isLoading
          ? // TODO(yijing): improve loading effect in the future
          const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Signing in...'),
                  VSpace(spacing),
                  CircularProgressIndicator(),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.fromLTRB(50, 0, 50, 30),
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
                  Text(
                    welcomeString.substring(0, welcomeString.length - 8),
                    style: style.textTheme.displayMedium,
                    textAlign: TextAlign.center,
                  ),
                  // Appflowy
                  Text(
                    welcomeString.substring(welcomeString.length - 8),
                    style: style.textTheme.displayLarge,
                    textAlign: TextAlign.center,
                  ),
                  const VSpace(spacing),
                  // TODO(yijing): confirm the subtitle before release app
                  Text(
                    'You are in charge of your data and customizations.',
                    style: style.textTheme.bodyMedium?.copyWith(
                      color: style.colorScheme.onSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(
                    flex: 2,
                  ),
                  const SignInAnonymousButton(),
                  const VSpace(spacing),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          LocaleKeys.signIn_or.tr(),
                          style: style.textTheme.bodyMedium?.copyWith(
                            color: style.colorScheme.onSecondary,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const VSpace(spacing),
                  if (isAuthEnabled) const ThirdPartySignInButtons(),
                  const VSpace(spacing),
                ],
              ),
            ),
    );
  }
}
