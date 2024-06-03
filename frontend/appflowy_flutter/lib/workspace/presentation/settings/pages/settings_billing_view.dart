import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_category.dart';
import 'package:appflowy/workspace/presentation/settings/shared/single_setting_action.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../generated/locale_keys.g.dart';

class SettingsBillingView extends StatelessWidget {
  const SettingsBillingView({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsBody(
      title: LocaleKeys.settings_billingPage_title.tr(),
      description: LocaleKeys.settings_billingPage_description.tr(),
      children: [
        SettingsCategory(
          title: LocaleKeys.settings_billingPage_plan_title.tr(),
          children: [
            SingleSettingAction(
              label: LocaleKeys.settings_billingPage_plan_freeLabel.tr(),
              buttonLabel:
                  LocaleKeys.settings_billingPage_plan_planButtonLabel.tr(),
            ),
            SingleSettingAction(
              label: LocaleKeys.settings_billingPage_plan_billingPeriod.tr(),
              buttonLabel:
                  LocaleKeys.settings_billingPage_plan_periodButtonLabel.tr(),
            ),
          ],
        ),
        SettingsCategory(
          title: LocaleKeys.settings_billingPage_paymentDetails_title.tr(),
          children: [
            SingleSettingAction(
              label: LocaleKeys.settings_billingPage_paymentDetails_methodLabel
                  .tr(),
              buttonLabel: LocaleKeys
                  .settings_billingPage_paymentDetails_methodButtonLabel
                  .tr(),
            ),
          ],
        ),
      ],
    );
  }
}
