import 'dart:io';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/user/application/sign_in_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:universal_platform/universal_platform.dart';

import 'third_party_sign_in_button.dart';

typedef _SignInCallback = void Function(ThirdPartySignInButtonType signInType);

@visibleForTesting
const Key signInWithGoogleButtonKey = Key('signInWithGoogleButton');

class ThirdPartySignInButtons extends StatelessWidget {
  /// Used in DesktopSignInScreen, MobileSignInScreen and SettingThirdPartyLogin
  const ThirdPartySignInButtons({
    super.key,
    this.expanded = false,
  });

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    if (UniversalPlatform.isDesktopOrWeb) {
      return _DesktopThirdPartySignIn(
        onSignIn: (type) => _signIn(context, type.provider),
      );
    } else {
      return _MobileThirdPartySignIn(
        isExpanded: expanded,
        onSignIn: (type) => _signIn(context, type.provider),
      );
    }
  }

  void _signIn(BuildContext context, String provider) {
    context.read<SignInBloc>().add(
          SignInEvent.signedInWithOAuth(provider),
        );
  }
}

class _DesktopThirdPartySignIn extends StatefulWidget {
  const _DesktopThirdPartySignIn({
    required this.onSignIn,
  });

  final _SignInCallback onSignIn;

  @override
  State<_DesktopThirdPartySignIn> createState() =>
      _DesktopThirdPartySignInState();
}

class _DesktopThirdPartySignInState extends State<_DesktopThirdPartySignIn> {
  static const padding = 12.0;

  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DesktopSignInButton(
          key: signInWithGoogleButtonKey,
          type: ThirdPartySignInButtonType.google,
          onPressed: () => widget.onSignIn(ThirdPartySignInButtonType.google),
        ),
        const VSpace(padding),
        DesktopSignInButton(
          type: ThirdPartySignInButtonType.apple,
          onPressed: () => widget.onSignIn(ThirdPartySignInButtonType.apple),
        ),
        ...isExpanded ? _buildExpandedButtons() : _buildCollapsedButtons(),
      ],
    );
  }

  List<Widget> _buildExpandedButtons() {
    return [
      const VSpace(padding * 1.5),
      DesktopSignInButton(
        type: ThirdPartySignInButtonType.github,
        onPressed: () => widget.onSignIn(ThirdPartySignInButtonType.github),
      ),
      const VSpace(padding),
      DesktopSignInButton(
        type: ThirdPartySignInButtonType.discord,
        onPressed: () => widget.onSignIn(ThirdPartySignInButtonType.discord),
      ),
    ];
  }

  List<Widget> _buildCollapsedButtons() {
    return [
      const VSpace(padding),
      MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            setState(() {
              isExpanded = !isExpanded;
            });
          },
          child: FlowyText(
            LocaleKeys.signIn_continueAnotherWay.tr(),
            color: Theme.of(context).colorScheme.onSurface,
            decoration: TextDecoration.underline,
            fontSize: 14,
          ),
        ),
      ),
    ];
  }
}

class _MobileThirdPartySignIn extends StatefulWidget {
  const _MobileThirdPartySignIn({
    required this.isExpanded,
    required this.onSignIn,
  });

  final bool isExpanded;
  final _SignInCallback onSignIn;

  @override
  State<_MobileThirdPartySignIn> createState() =>
      _MobileThirdPartySignInState();
}

class _MobileThirdPartySignInState extends State<_MobileThirdPartySignIn> {
  static const padding = 8.0;

  bool isExpanded = false;

  @override
  void initState() {
    super.initState();

    isExpanded = widget.isExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // only display apple sign in button on iOS
        if (Platform.isIOS) ...[
          MobileThirdPartySignInButton(
            type: ThirdPartySignInButtonType.apple,
            onPressed: () => widget.onSignIn(ThirdPartySignInButtonType.apple),
          ),
          const VSpace(padding),
        ],
        MobileThirdPartySignInButton(
          key: signInWithGoogleButtonKey,
          type: ThirdPartySignInButtonType.google,
          onPressed: () => widget.onSignIn(ThirdPartySignInButtonType.google),
        ),
        ...isExpanded ? _buildExpandedButtons() : _buildCollapsedButtons(),
      ],
    );
  }

  List<Widget> _buildExpandedButtons() {
    return [
      const VSpace(padding),
      MobileThirdPartySignInButton(
        type: ThirdPartySignInButtonType.github,
        onPressed: () => widget.onSignIn(ThirdPartySignInButtonType.github),
      ),
      const VSpace(padding),
      MobileThirdPartySignInButton(
        type: ThirdPartySignInButtonType.discord,
        onPressed: () => widget.onSignIn(ThirdPartySignInButtonType.discord),
      ),
    ];
  }

  List<Widget> _buildCollapsedButtons() {
    return [
      const VSpace(padding * 2),
      GestureDetector(
        onTap: () {
          setState(() {
            isExpanded = !isExpanded;
          });
        },
        child: FlowyText(
          LocaleKeys.signIn_continueAnotherWay.tr(),
          color: Theme.of(context).colorScheme.onSurface,
          decoration: TextDecoration.underline,
          fontSize: 14,
        ),
      ),
    ];
  }
}
