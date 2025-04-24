import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/mobile/presentation/setting/cloud/appflowy_cloud_page.dart';
import 'package:appflowy/mobile/presentation/setting/widgets/mobile_setting_group_widget.dart';
import 'package:appflowy/mobile/presentation/setting/widgets/mobile_setting_item_widget.dart';
import 'package:appflowy/mobile/presentation/setting/widgets/mobile_setting_trailing.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/setting_cloud.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CloudSettingGroup extends StatelessWidget {
  const CloudSettingGroup({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getAuthenticatorType(),
      builder: (context, snapshot) {
        final cloudType = snapshot.data ?? AuthenticatorType.appflowyCloud;
        final name = titleFromCloudType(cloudType);
        return MobileSettingGroup(
          groupTitle: 'Cloud settings',
          settingItemList: [
            MobileSettingItem(
              name: 'Cloud server',
              trailing: MobileSettingTrailing(
                text: name,
              ),
              onTap: () => context.push(AppFlowyCloudPage.routeName),
            ),
          ],
        );
      },
    );
  }
}
