import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/mobile_bottom_sheet_action_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

enum MobileTrashBottomSheetBodyAction {
  restoreAll,
  deleteAll,
}

class MobileTrashBottomSheetBody extends StatelessWidget {
  const MobileTrashBottomSheetBody({
    super.key,
    required this.onAction,
  });

  final void Function(MobileTrashBottomSheetBodyAction action) onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // restore all, delete all
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: BottomSheetActionWidget(
                svg: FlowySvgs.m_restore_m,
                text: LocaleKeys.trash_restoreAll.tr(),
                onTap: () => onAction(
                  MobileTrashBottomSheetBodyAction.restoreAll,
                ),
              ),
            ),
            Expanded(
              child: BottomSheetActionWidget(
                svg: FlowySvgs.m_delete_m,
                text: LocaleKeys.button_delete.tr(),
                onTap: () => onAction(
                  MobileTrashBottomSheetBodyAction.deleteAll,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
