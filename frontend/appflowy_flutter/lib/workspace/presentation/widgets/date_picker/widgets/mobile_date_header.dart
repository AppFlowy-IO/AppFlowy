import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _height = 44.0;

class MobileDateHeader extends StatelessWidget {
  const MobileDateHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: FlowyIconButton(
              icon: const FlowySvg(
                FlowySvgs.close_s,
                size: Size.square(_height),
              ),
              onPressed: () => context.pop(),
            ),
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
