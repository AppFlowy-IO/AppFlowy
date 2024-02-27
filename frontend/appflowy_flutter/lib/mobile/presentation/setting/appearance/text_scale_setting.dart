import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/presentation/widgets/more_view_actions/widgets/font_size_stepper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../setting.dart';

const int _divisions = 4;

class TextScaleSetting extends StatelessWidget {
  const TextScaleSetting({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textScaleFactor =
        context.watch<AppearanceSettingsCubit>().state.textScaleFactor;
    return MobileSettingItem(
      name: LocaleKeys.settings_appearance_fontScaleFactor.tr(),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FlowyText(
            // map the text scale factor to the 0-1
            // 0.8 - 0.0
            // 0.9 - 0.5
            // 1.0 - 1.0
            ((_divisions + 1) * textScaleFactor - _divisions)
                .toStringAsFixed(2),
            color: theme.colorScheme.onSurface,
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () {
        showMobileBottomSheet(
          context,
          showHeader: true,
          showDragHandle: true,
          showDivider: false,
          showCloseButton: false,
          title: LocaleKeys.settings_appearance_fontScaleFactor.tr(),
          builder: (context) {
            return FontSizeStepper(
              value: textScaleFactor,
              minimumValue: 0.8,
              maximumValue: 1.0,
              divisions: _divisions,
              onChanged: (newTextScaleFactor) {
                context
                    .read<AppearanceSettingsCubit>()
                    .setTextScaleFactor(newTextScaleFactor);
              },
            );
          },
        );
      },
    );
  }
}
