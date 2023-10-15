import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';

class NotificationsHubEmpty extends StatelessWidget {
  const NotificationsHubEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: FlowyText.regular(
          LocaleKeys.notificationHub_empty.tr(),
        ),
      ),
    );
  }
}
