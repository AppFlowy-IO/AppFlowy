import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/setting/cloud/appflowy_cloud_page.dart';
import 'package:appflowy/mobile/presentation/setting/widgets/mobile_setting_group_widget.dart';
import 'package:appflowy/mobile/presentation/setting/widgets/mobile_setting_item_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

class CloudSettingGroup extends StatelessWidget {
  const CloudSettingGroup({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) => MobileSettingGroup(
        groupTitle: LocaleKeys.settings_menu_cloudSetting.tr(),
        settingItemList: [
          MobileSettingItem(
            name: LocaleKeys.settings_menu_cloudAppFlowy.tr(),
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: () => context.push(AppFlowyCloudPage.routeName),
          ),
        ],
      ),
    );
  }
}
