import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/setting_supabase_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SyncSettingView extends StatelessWidget {
  const SyncSettingView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SyncSettingBloc()..add(const SyncSettingEvent.initial()),
      child: BlocBuilder<SyncSettingBloc, SyncSettingState>(
        builder: (context, state) {
          return Row(
            children: [
              FlowyText.medium(LocaleKeys.settings_menu_enableSync.tr()),
              const Spacer(),
              Switch(
                onChanged: (bool value) {
                  context.read<SyncSettingBloc>().add(
                        SyncSettingEvent.enableSync(value),
                      );
                },
                value: state.config?.enableSync ?? false,
              )
            ],
          );
        },
      ),
    );
  }
}
