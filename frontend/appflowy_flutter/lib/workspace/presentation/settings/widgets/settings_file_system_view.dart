import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_category_spacer.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/files/setting_file_import_appflowy_data_view.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/files/settings_export_file_widget.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/files/settings_file_cache_widget.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/files/settings_file_customize_location_view.dart';
import 'package:easy_localization/easy_localization.dart';

class SettingsFileSystemView extends StatelessWidget {
  const SettingsFileSystemView({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsBody(
      title: LocaleKeys.settings_menu_files.tr(),
      children: const [
        SettingsFileLocationCustomizer(),
        SettingsCategorySpacer(),
        if (kDebugMode) ...[
          SettingsExportFileWidget(),
        ],
        ImportAppFlowyData(),
        SettingsCategorySpacer(),
        SettingsFileCacheWidget(),
      ],
    );
  }
}
