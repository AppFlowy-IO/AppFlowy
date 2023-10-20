import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static const routeName = '/PrivacyPolicyPage';

  @override
  Widget build(BuildContext context) {
    // TODO(yijing): implement page
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.settings_mobile_privacyPolicy.tr()),
      ),
      body: const Center(
        child: Text('🪜 Under construction'),
      ),
    );
  }
}
