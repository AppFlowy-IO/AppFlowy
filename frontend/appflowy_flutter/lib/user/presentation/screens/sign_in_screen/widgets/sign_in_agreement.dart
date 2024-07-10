import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:appflowy/core/helpers/url_launcher.dart';

class SignInAgreement extends StatelessWidget {
  const SignInAgreement({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: [
          TextSpan(
            text: '${LocaleKeys.web_signInAgreement.tr()} ',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          TextSpan(
            text: '${LocaleKeys.web_termOfUse.tr()} ',
            style: const TextStyle(color: Colors.blue, fontSize: 12),
            mouseCursor: SystemMouseCursors.click,
            recognizer: TapGestureRecognizer()
              ..onTap = () => afLaunchUrlString('https://appflowy.io/terms'),
          ),
          TextSpan(
            text: '${LocaleKeys.web_and.tr()} ',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          TextSpan(
              text: LocaleKeys.web_privacyPolicy.tr(),
              style: const TextStyle(color: Colors.blue, fontSize: 12),
              mouseCursor: SystemMouseCursors.click,
              recognizer: TapGestureRecognizer()
                ..onTap =
                    () => afLaunchUrlString('https://appflowy.io/privacy')),
        ],
      ),
    );
  }
}
