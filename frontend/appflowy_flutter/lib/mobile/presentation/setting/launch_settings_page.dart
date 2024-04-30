import 'package:appflowy/env/env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/app_bar/app_bar.dart';
import 'package:appflowy/mobile/presentation/presentation.dart';
import 'package:appflowy/mobile/presentation/setting/self_host_setting_group.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileLaunchSettingsPage extends StatelessWidget {
  const MobileLaunchSettingsPage({
    super.key,
  });

  static const routeName = '/launch_settings';

  @override
  Widget build(BuildContext context) {
    context.watch<AppearanceSettingsCubit>();
    return Scaffold(
      appBar: FlowyAppBar(
        titleText: LocaleKeys.settings_title.tr(),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const LanguageSettingGroup(),
              if (Env.enableCustomCloud) const SelfHostSettingGroup(),
              const SupportSettingGroup(),
            ],
          ),
        ),
      ),
    );
  }
}
