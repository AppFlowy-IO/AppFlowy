import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class AddNewPageWidgetBottomSheet extends StatelessWidget {
  const AddNewPageWidgetBottomSheet({
    super.key,
    required this.view,
    required this.onAction,
  });

  final ViewPB view;
  final void Function(ViewLayoutPB layout) onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FlowyOptionTile.text(
          text: LocaleKeys.document_menuName.tr(),
          leftIcon: const FlowySvg(
            FlowySvgs.document_s,
            size: Size.square(20),
          ),
          showTopBorder: false,
          onTap: () => onAction(ViewLayoutPB.Document),
        ),
        FlowyOptionTile.text(
          text: LocaleKeys.grid_menuName.tr(),
          leftIcon: const FlowySvg(
            FlowySvgs.grid_s,
            size: Size.square(20),
          ),
          showTopBorder: false,
          onTap: () => onAction(ViewLayoutPB.Grid),
        ),
        FlowyOptionTile.text(
          text: LocaleKeys.board_menuName.tr(),
          leftIcon: const FlowySvg(
            FlowySvgs.board_s,
            size: Size.square(20),
          ),
          showTopBorder: false,
          onTap: () => onAction(ViewLayoutPB.Board),
        ),
        FlowyOptionTile.text(
          text: LocaleKeys.calendar_menuName.tr(),
          leftIcon: const FlowySvg(
            FlowySvgs.date_s,
            size: Size.square(20),
          ),
          showTopBorder: false,
          onTap: () => onAction(ViewLayoutPB.Calendar),
        ),
      ],
    );
  }
}
