import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/app_bar_actions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';

const _height = 44.0;

class MobileDateHeader extends StatelessWidget {
  const MobileDateHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Stack(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: AppBarCloseButton(),
          ),
          Align(
            child: FlowyText.medium(
              LocaleKeys.grid_field_dateFieldName.tr(),
              fontSize: 16,
            ),
          ),
        ].map((e) => SizedBox(height: _height, child: e)).toList(),
      ),
    );
  }
}
