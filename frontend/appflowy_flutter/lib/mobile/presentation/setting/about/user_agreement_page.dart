import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class UserAgreementPage extends StatelessWidget {
  const UserAgreementPage({super.key});

  static const routeName = '/UserAgreementPage';

  @override
  Widget build(BuildContext context) {
    // TODO(yijing): implement page
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.settings_mobile_userAgreement.tr()),
      ),
      body: const Center(
        child: Text('🪜 Under construction'),
      ),
    );
  }
}
