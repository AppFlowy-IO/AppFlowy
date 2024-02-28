import 'dart:async';

import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/setting/font/font_picker_screen.dart';
import 'package:appflowy/plugins/document/application/document_appearance_cubit.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../setting.dart';

class FontSetting extends StatelessWidget {
  const FontSetting({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedFont = context.watch<AppearanceSettingsCubit>().state.font;
    return MobileSettingItem(
      name: LocaleKeys.settings_appearance_fontFamily_label.tr(),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FlowyText(
            selectedFont,
            fontFamily: GoogleFonts.getFont(selectedFont).fontFamily,
            color: theme.colorScheme.onSurface,
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () async {
        final newFont = await context.push<String>(FontPickerScreen.routeName);
        if (newFont != null && newFont != selectedFont) {
          if (context.mounted) {
            context.read<AppearanceSettingsCubit>().setFontFamily(newFont);
            unawaited(
              context.read<DocumentAppearanceCubit>().syncFontFamily(newFont),
            );
          }
        }
      },
    );
  }
}
