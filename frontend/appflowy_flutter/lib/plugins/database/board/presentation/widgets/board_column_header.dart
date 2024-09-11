import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/board/application/board_bloc.dart';
import 'package:appflowy/plugins/database/board/group_ext.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/header/field_type_extension.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_board/appflowy_board.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'board_checkbox_column_header.dart';
import 'board_editable_column_header.dart';

class BoardColumnHeader extends StatefulWidget {
  const BoardColumnHeader({
    super.key,
    required this.databaseController,
    required this.groupData,
    required this.margin,
  });

  final DatabaseController databaseController;
  final AppFlowyGroupData groupData;
  final EdgeInsets margin;

  @override
  State<BoardColumnHeader> createState() => _BoardColumnHeaderState();
}

class _BoardColumnHeaderState extends State<BoardColumnHeader> {
  final ValueNotifier<bool> isEditing = ValueNotifier(false);

  GroupData get customData => widget.groupData.customData;

  @override
  void dispose() {
    isEditing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget child = switch (customData.fieldType) {
      FieldType.MultiSelect ||
      FieldType.SingleSelect when !customData.group.isDefault =>
        EditableColumnHeader(
          databaseController: widget.databaseController,
          groupData: widget.groupData,
          isEditing: isEditing,
          onSubmitted: (columnName) {
            context
                .read<BoardBloc>()
                .add(BoardEvent.renameGroup(widget.groupData.id, columnName));
          },
        ),
      FieldType.Checkbox => CheckboxColumnHeader(
          databaseController: widget.databaseController,
          groupData: widget.groupData,
        ),
      _ => _DefaultColumnHeaderContent(
          databaseController: widget.databaseController,
          groupData: widget.groupData,
        ),
    };

    return Container(
      padding: widget.margin,
      height: 50,
      child: child,
    );
  }
}

class GroupOptionsButton extends StatelessWidget {
  const GroupOptionsButton({
    super.key,
    required this.groupData,
    this.isEditing,
  });

  final AppFlowyGroupData groupData;
  final ValueNotifier<bool>? isEditing;

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      clickHandler: PopoverClickHandler.gestureDetector,
      margin: const EdgeInsets.all(8),
      constraints: BoxConstraints.loose(const Size(168, 300)),
      direction: PopoverDirection.bottomWithLeftAligned,
      child: FlowyIconButton(
        width: 20,
        icon: const FlowySvg(FlowySvgs.details_horizontal_s),
        iconColorOnHover: Theme.of(context).colorScheme.onSurface,
      ),
      popupBuilder: (popoverContext) {
        final customGroupData = groupData.customData as GroupData;
        final isDefault = customGroupData.group.isDefault;
        final menuItems = GroupOption.values.toList();
        if (!customGroupData.fieldType.canEditHeader || isDefault) {
          menuItems.remove(GroupOption.rename);
        }
        if (!customGroupData.fieldType.canDeleteGroup || isDefault) {
          menuItems.remove(GroupOption.delete);
        }
        return SeparatedColumn(
          mainAxisSize: MainAxisSize.min,
          separatorBuilder: () => const VSpace(4),
          children: [
            ...menuItems.map(
              (action) => SizedBox(
                height: GridSize.popoverItemHeight,
                child: FlowyButton(
                  leftIcon: FlowySvg(action.icon),
                  text: FlowyText.medium(
                    action.text,
                    lineHeight: 1.0,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    run(context, action, customGroupData.group);
                    PopoverContainer.of(popoverContext).close();
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void run(BuildContext context, GroupOption option, GroupPB group) {
    switch (option) {
      case GroupOption.rename:
        isEditing?.value = true;
        break;
      case GroupOption.hide:
        context
            .read<BoardBloc>()
            .add(BoardEvent.setGroupVisibility(group, false));
        break;
      case GroupOption.delete:
        showConfirmDeletionDialog(
          context: context,
          name: LocaleKeys.board_column_label.tr(),
          description: LocaleKeys.board_column_deleteColumnConfirmation.tr(),
          onConfirm: () {
            context
                .read<BoardBloc>()
                .add(BoardEvent.deleteGroup(group.groupId));
          },
        );
        break;
    }
  }
}

class CreateCardFromTopButton extends StatelessWidget {
  const CreateCardFromTopButton({
    super.key,
    required this.groupId,
  });

  final String groupId;

  @override
  Widget build(BuildContext context) {
    return FlowyTooltip(
      message: LocaleKeys.board_column_addToColumnTopTooltip.tr(),
      preferBelow: false,
      child: FlowyIconButton(
        width: 20,
        icon: const FlowySvg(FlowySvgs.add_s),
        iconColorOnHover: Theme.of(context).colorScheme.onSurface,
        onPressed: () => context.read<BoardBloc>().add(
              BoardEvent.createRow(
                groupId,
                OrderObjectPositionTypePB.Start,
                null,
                null,
              ),
            ),
      ),
    );
  }
}

class _DefaultColumnHeaderContent extends StatelessWidget {
  const _DefaultColumnHeaderContent({
    required this.databaseController,
    required this.groupData,
  });

  final DatabaseController databaseController;
  final AppFlowyGroupData groupData;

  @override
  Widget build(BuildContext context) {
    final customData = groupData.customData as GroupData;
    return Row(
      children: [
        Expanded(
          child: FlowyText.medium(
            customData.group.generateGroupName(databaseController),
            overflow: TextOverflow.ellipsis,
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

enum GroupOption {
  rename,
  hide,
  delete;

  FlowySvgData get icon => switch (this) {
        rename => FlowySvgs.edit_s,
        hide => FlowySvgs.hide_s,
        delete => FlowySvgs.delete_s,
      };

  String get text => switch (this) {
        rename => LocaleKeys.board_column_renameColumn.tr(),
        hide => LocaleKeys.board_column_hideColumn.tr(),
        delete => LocaleKeys.board_column_deleteColumn.tr(),
      };
}
