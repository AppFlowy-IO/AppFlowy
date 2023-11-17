import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet_action_widget.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
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
        // new document, new grid
        Row(
          children: [
            Expanded(
              child: BottomSheetActionWidget(
                svg: FlowySvgs.document_s,
                text: LocaleKeys.document_menuName.tr(),
                onTap: () => onAction(ViewLayoutPB.Document),
              ),
            ),
            const HSpace(8),
            Expanded(
              child: BottomSheetActionWidget(
                svg: FlowySvgs.grid_s,
                text: LocaleKeys.grid_menuName.tr(),
                onTap: () => onAction(ViewLayoutPB.Grid),
              ),
            ),
          ],
        ),
        const VSpace(8),

        // new board, new calendar
        Row(
          children: [
            Expanded(
              child: BottomSheetActionWidget(
                svg: FlowySvgs.board_s,
                text: LocaleKeys.board_menuName.tr(),
                onTap: () => onAction(ViewLayoutPB.Board),
              ),
            ),
            const HSpace(8),
            Expanded(
              child: BottomSheetActionWidget(
                svg: FlowySvgs.date_s,
                text: LocaleKeys.calendar_menuName.tr(),
                onTap: () => onAction(ViewLayoutPB.Calendar),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
