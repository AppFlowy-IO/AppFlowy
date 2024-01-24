import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';

class MobileCalendarEventsEmpty extends StatelessWidget {
  const MobileCalendarEventsEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FlowyText(
              LocaleKeys.calendar_mobileEventScreen_emptyTitle.tr(),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            const VSpace(8),
            FlowyText.regular(
              LocaleKeys.calendar_mobileEventScreen_emptyBody.tr(),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
