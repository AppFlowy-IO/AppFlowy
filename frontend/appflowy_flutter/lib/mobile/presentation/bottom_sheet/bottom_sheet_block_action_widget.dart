import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet_action_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

enum BlockActionBottomSheetType {
  delete,
  duplicate,
  insertAbove,
  insertBelow,
}

// Only works on mobile.
class BlockActionBottomSheet extends StatelessWidget {
  const BlockActionBottomSheet({
    super.key,
    required this.onAction,
    this.extendActionWidgets = const [],
  });

  final void Function(BlockActionBottomSheetType layout) onAction;
  final List<Widget> extendActionWidgets;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // insert above, insert below
        Row(
          children: [
            Expanded(
              child: BottomSheetActionWidget(
                svg: FlowySvgs.arrow_up_s,
                text: LocaleKeys.button_insertAbove.tr(),
                onTap: () => onAction(BlockActionBottomSheetType.insertAbove),
              ),
            ),
            const HSpace(8),
            Expanded(
              child: BottomSheetActionWidget(
                svg: FlowySvgs.arrow_down_s,
                text: LocaleKeys.button_insertBelow.tr(),
                onTap: () => onAction(BlockActionBottomSheetType.insertBelow),
              ),
            ),
          ],
        ),
        const VSpace(8),

        // duplicate, delete
        Row(
          children: [
            Expanded(
              child: BottomSheetActionWidget(
                svg: FlowySvgs.m_duplicate_m,
                text: LocaleKeys.button_duplicate.tr(),
                onTap: () => onAction(BlockActionBottomSheetType.duplicate),
              ),
            ),
            const HSpace(8),
            Expanded(
              child: BottomSheetActionWidget(
                svg: FlowySvgs.m_delete_m,
                text: LocaleKeys.button_delete.tr(),
                onTap: () => onAction(BlockActionBottomSheetType.delete),
              ),
            ),
          ],
        ),
        const VSpace(8),

        ...extendActionWidgets,
      ],
    );
  }
}
