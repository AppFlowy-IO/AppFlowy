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
          height: 52.0,
          leftIcon: const FlowySvg(
            FlowySvgs.icon_document_s,
            size: Size.square(20),
          ),
          showTopBorder: false,
          showBottomBorder: false,
          onTap: () => onAction(ViewLayoutPB.Document),
        ),
        FlowyOptionTile.text(
          text: LocaleKeys.grid_menuName.tr(),
          height: 52.0,
          leftIcon: const FlowySvg(
            FlowySvgs.icon_grid_s,
            size: Size.square(20),
          ),
          showTopBorder: false,
          showBottomBorder: false,
          onTap: () => onAction(ViewLayoutPB.Grid),
        ),
        FlowyOptionTile.text(
          text: LocaleKeys.board_menuName.tr(),
          height: 52.0,
          leftIcon: const FlowySvg(
            FlowySvgs.icon_board_s,
            size: Size.square(20),
          ),
          showTopBorder: false,
          showBottomBorder: false,
          onTap: () => onAction(ViewLayoutPB.Board),
        ),
        FlowyOptionTile.text(
          text: LocaleKeys.calendar_menuName.tr(),
          height: 52.0,
          leftIcon: const FlowySvg(
            FlowySvgs.icon_calendar_s,
            size: Size.square(20),
          ),
          showTopBorder: false,
          showBottomBorder: false,
          onTap: () => onAction(ViewLayoutPB.Calendar),
        ),
        FlowyOptionTile.text(
          text: LocaleKeys.chat_newChat.tr(),
          height: 52.0,
          leftIcon: const FlowySvg(
            FlowySvgs.chat_ai_page_s,
            size: Size.square(20),
          ),
          showTopBorder: false,
          showBottomBorder: false,
          onTap: () => onAction(ViewLayoutPB.Chat),
        ),
      ],
    );
  }
}
