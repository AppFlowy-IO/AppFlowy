import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet_action_widget.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet_drag_handler.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet_view_item_header.dart';
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
      mainAxisSize: MainAxisSize.min,
      children: [
        // drag handler
        const MobileBottomSheetDragHandler(),

        // header
        MobileViewItemBottomSheetHeader(
          showBackButton: false,
          view: view,
          onBack: () {},
        ),
        const VSpace(8.0),
        const Divider(),

        // body
        _AddNewPageBody(
          onAction: onAction,
        ),
        const VSpace(24.0),
      ],
    );
  }
}

class _AddNewPageBody extends StatelessWidget {
  const _AddNewPageBody({
    required this.onAction,
  });

  final void Function(ViewLayoutPB layout) onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // rename, duplicate
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: BottomSheetActionWidget(
                svg: FlowySvgs.documents_s,
                text: LocaleKeys.document_menuName.tr(),
                onTap: () => onAction(ViewLayoutPB.Document),
              ),
            ),
            Expanded(
              child: BottomSheetActionWidget(
                svg: FlowySvgs.grid_s,
                text: LocaleKeys.grid_menuName.tr(),
                onTap: () => onAction(ViewLayoutPB.Grid),
              ),
            ),
          ],
        ),

        // share, delete
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: BottomSheetActionWidget(
                svg: FlowySvgs.board_s,
                text: LocaleKeys.board_menuName.tr(),
                onTap: () => onAction(ViewLayoutPB.Board),
              ),
            ),
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
