import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/settings/prelude.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_appearance/theme_setting_entry_template.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

bool _prevSetting = false;

class CreateFileSettings extends StatelessWidget {
  CreateFileSettings({
    super.key,
  });

  final cubit = CreateFileSettingsCubit(_prevSetting);

  @override
  Widget build(BuildContext context) {
    return FlowySettingListTile(
      label:
          LocaleKeys.settings_appearance_showNamingDialogWhenCreatingPage.tr(),
      trailing: [
        BlocProvider.value(
          value: cubit,
          child: BlocBuilder<CreateFileSettingsCubit, bool>(
            builder: (context, state) {
              _prevSetting = state;
              return Switch(
                value: state,
                splashRadius: 0,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (value) {
                  cubit.toggle(value: value);
                  _prevSetting = value;
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
