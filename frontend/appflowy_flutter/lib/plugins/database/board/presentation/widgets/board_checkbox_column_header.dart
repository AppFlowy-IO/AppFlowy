import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/board/application/board_bloc.dart';
import 'package:appflowy/plugins/database/board/group_ext.dart';
import 'package:appflowy_board/appflowy_board.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

import 'board_column_header.dart';

class CheckboxColumnHeader extends StatelessWidget {
  const CheckboxColumnHeader({
    super.key,
    required this.databaseController,
    required this.groupData,
  });

  final DatabaseController databaseController;
  final AppFlowyGroupData groupData;

  @override
  Widget build(BuildContext context) {
    final customData = groupData.customData as GroupData;
    final groupName = customData.group.generateGroupName(databaseController);
    return Row(
      children: [
        FlowySvg(
          customData.asCheckboxGroup()!.isCheck
              ? FlowySvgs.check_filled_s
              : FlowySvgs.uncheck_s,
          blendMode: BlendMode.dst,
          size: const Size.square(18),
        ),
        const HSpace(6),
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: FlowyTooltip(
              message: groupName,
              child: FlowyText.medium(
                groupName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        const HSpace(6),
        GroupOptionsButton(
          groupData: groupData,
        ),
        const HSpace(4),
        CreateCardFromTopButton(
          groupId: groupData.id,
        ),
      ],
    );
  }
}
