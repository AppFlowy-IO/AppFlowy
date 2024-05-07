import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/widgets/flowy_mobile_quick_action_button.dart';
import 'package:appflowy/plugins/database/board/application/board_bloc.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/header/field_type_extension.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_board/appflowy_board.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// similar to [BoardColumnHeader] in Desktop
class GroupCardHeader extends StatefulWidget {
  const GroupCardHeader({
    super.key,
    required this.groupData,
  });

  final AppFlowyGroupData groupData;

  @override
  State<GroupCardHeader> createState() => _GroupCardHeaderState();
}

class _GroupCardHeaderState extends State<GroupCardHeader> {
  late final TextEditingController _controller =
      TextEditingController.fromValue(
    TextEditingValue(
      selection: TextSelection.collapsed(
        offset: widget.groupData.headerData.groupName.length,
      ),
      text: widget.groupData.headerData.groupName,
    ),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final boardCustomData = widget.groupData.customData as GroupData;
    final titleTextStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(
          fontWeight: FontWeight.w600,
        );
    return BlocBuilder<BoardBloc, BoardState>(
      builder: (context, state) {
        Widget title = Text(
          widget.groupData.headerData.groupName,
          style: titleTextStyle,
          overflow: TextOverflow.ellipsis,
        );

        // header can be edited if it's not default group(no status) and the field type can be edited
        if (!boardCustomData.group.isDefault &&
            boardCustomData.fieldType.canEditHeader) {
          title = GestureDetector(
            onTap: () => context
                .read<BoardBloc>()
                .add(BoardEvent.startEditingHeader(widget.groupData.id)),
            child: Text(
              widget.groupData.headerData.groupName,
              style: titleTextStyle,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }

        final isEditing = state.maybeMap(
          ready: (value) => value.editingHeaderId == widget.groupData.id,
          orElse: () => false,
        );

        if (isEditing) {
          title = TextField(
            controller: _controller,
            autofocus: true,
            onEditingComplete: () => context.read<BoardBloc>().add(
                  BoardEvent.endEditingHeader(
                    widget.groupData.id,
                    _controller.text,
                  ),
                ),
            style: titleTextStyle,
            onTapOutside: (_) => context.read<BoardBloc>().add(
                  // group header switch from TextField to Text
                  // group name won't be changed
                  BoardEvent.endEditingHeader(widget.groupData.id, null),
                ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(left: 16),
          child: SizedBox(
            height: 42,
            child: Row(
              children: [
                _buildHeaderIcon(boardCustomData),
                Expanded(child: title),
                IconButton(
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  splashRadius: 5,
                  onPressed: () => showMobileBottomSheet(
                    context,
                    showDragHandle: true,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    builder: (_) => SeparatedColumn(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      separatorBuilder: () => const Divider(
                        height: 8.5,
                        thickness: 0.5,
                      ),
                      children: [
                        MobileQuickActionButton(
                          text: LocaleKeys.board_column_renameColumn.tr(),
                          icon: FlowySvgs.edit_s,
                          onTap: () {
                            context.read<BoardBloc>().add(
                                  BoardEvent.startEditingHeader(
                                    widget.groupData.id,
                                  ),
                                );
                            context.pop();
                          },
                        ),
                        MobileQuickActionButton(
                          text: LocaleKeys.board_column_hideColumn.tr(),
                          icon: FlowySvgs.hide_s,
                          onTap: () {
                            context.read<BoardBloc>().add(
                                  BoardEvent.toggleGroupVisibility(
                                    widget.groupData.customData.group
                                        as GroupPB,
                                    false,
                                  ),
                                );
                            context.pop();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.add,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  splashRadius: 5,
                  onPressed: () {
                    context.read<BoardBloc>().add(
                          BoardEvent.createRow(
                            widget.groupData.id,
                            OrderObjectPositionTypePB.After,
                            null,
                            null,
                          ),
                        );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderIcon(GroupData customData) =>
      switch (customData.fieldType) {
        FieldType.Checkbox => FlowySvg(
            customData.asCheckboxGroup()!.isCheck
                ? FlowySvgs.check_filled_s
                : FlowySvgs.uncheck_s,
            blendMode: BlendMode.dst,
          ),
        _ => const SizedBox.shrink(),
      };
}
