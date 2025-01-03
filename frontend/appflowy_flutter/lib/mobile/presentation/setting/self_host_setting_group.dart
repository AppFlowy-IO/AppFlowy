import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/setting/self_host/self_host_bottom_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
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
  final future = Future.wait([
    getAppFlowyCloudUrl(),
    getAppFlowyShareDomain(),
  ]);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (!snapshot.hasData || data == null || data.length != 2) {
          return const SizedBox.shrink();
        }
        final url = data[0];
        final shareDomain = data[1];
        return MobileSettingGroup(
          groupTitle: LocaleKeys.settings_menu_cloudAppFlowy.tr(),
          settingItemList: [
            _buildSelfHostField(url),
            _buildShareDomainField(shareDomain),
          ],
        );
      },
    );
  }

  Widget _buildSelfHostField(String url) {
    return MobileSettingItem(
      title: Padding(
        padding: const EdgeInsets.only(bottom: 4.0),
        child: FlowyText(
          LocaleKeys.settings_menu_cloudURL.tr(),
          fontSize: 12.0,
          color: Theme.of(context).hintColor,
        ),
      ),
      subtitle: FlowyText(
        url,
      ),
      trailing: const Icon(
        Icons.chevron_right,
      ),
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
              type: SelfHostUrlBottomSheetType.cloudURL,
            );
          },
        );
      },
    );
  }

  Widget _buildShareDomainField(String shareDomain) {
    return MobileSettingItem(
      title: Padding(
        padding: const EdgeInsets.only(bottom: 4.0),
        child: FlowyText(
          LocaleKeys.settings_menu_webURL.tr(),
          fontSize: 12.0,
          color: Theme.of(context).hintColor,
        ),
      ),
      subtitle: FlowyText(
        shareDomain,
      ),
      trailing: const Icon(
        Icons.chevron_right,
      ),
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
              url: shareDomain,
              type: SelfHostUrlBottomSheetType.shareDomain,
            );
          },
        );
      },
    );
  }
}
