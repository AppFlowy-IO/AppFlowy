import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/setting/self_host/self_host_bottom_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'setting.dart';

class SelfHostSettingGroup extends StatefulWidget {
  const SelfHostSettingGroup({
    super.key,
  });

  @override
  State<SelfHostSettingGroup> createState() => _SelfHostSettingGroupState();
}

class _SelfHostSettingGroupState extends State<SelfHostSettingGroup> {
  final future = getAppFlowyCloudUrl();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final url = snapshot.data ?? '';
        return MobileSettingGroup(
          groupTitle: LocaleKeys.settings_menu_cloudAppFlowySelfHost.tr(),
          settingItemList: [
            MobileSettingItem(
              name: url,
              onTap: () {
                showMobileBottomSheet(
                  context,
                  showHeader: true,
                  title: LocaleKeys.editor_urlHint.tr(),
                  showCloseButton: true,
                  showDivider: false,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  builder: (_) {
                    return SelfHostUrlBottomSheet(
                      url: url,
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }
}
