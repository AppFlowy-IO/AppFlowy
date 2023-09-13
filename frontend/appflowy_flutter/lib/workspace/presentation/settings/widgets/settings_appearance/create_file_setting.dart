import 'package:appflowy/workspace/application/settings/prelude.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_appearance/theme_setting_entry_template.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreateFileSettings extends StatelessWidget {
  CreateFileSettings({
    super.key,
  });

  final cubit = CreateFileSettingsCubit();

  @override
  Widget build(BuildContext context) {
    return ThemeSettingEntryTemplateWidget(
      label: 'Show rename dialog when creating a new file',
      trailing: [
        BlocProvider.value(
          value: cubit,
          child: BlocBuilder<CreateFileSettingsCubit, bool>(
            builder: (context, state) {
              return Switch(
                value: state,
                onChanged: (value) {
                  cubit.toggle(value: value);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
