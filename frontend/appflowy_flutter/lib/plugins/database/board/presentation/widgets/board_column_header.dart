import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/board/application/board_bloc.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/header/field_type_extension.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_board/appflowy_board.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BoardColumnHeader extends StatefulWidget {
  const BoardColumnHeader({
    super.key,
    required this.groupData,
    required this.margin,
  });

  final AppFlowyGroupData groupData;
  final EdgeInsets margin;

  @override
  State<BoardColumnHeader> createState() => _BoardColumnHeaderState();
}

class _BoardColumnHeaderState extends State<BoardColumnHeader> {
  final FocusNode _focusNode = FocusNode();
  final FocusNode _keyboardListenerFocusNode = FocusNode();

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
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _saveEdit();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _keyboardListenerFocusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final boardCustomData = widget.groupData.customData as GroupData;

    return BlocBuilder<BoardBloc, BoardState>(
      builder: (context, state) {
        return state.maybeMap(
          orElse: () => const SizedBox.shrink(),
          ready: (state) {
            if (state.editingHeaderId != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _focusNode.requestFocus();
              });
            }

            Widget title = Expanded(
              child: FlowyText.medium(
                widget.groupData.headerData.groupName,
                overflow: TextOverflow.ellipsis,
              ),
            );

            if (!boardCustomData.group.isDefault &&
                boardCustomData.fieldType.canEditHeader) {
              title = Flexible(
                fit: FlexFit.tight,
                child: FlowyTooltip(
                  message: LocaleKeys.board_column_renameGroupTooltip.tr(),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => context.read<BoardBloc>().add(
                            BoardEvent.startEditingHeader(widget.groupData.id),
                          ),
                      child: FlowyText.medium(
                        widget.groupData.headerData.groupName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              );
            }

            if (state.editingHeaderId == widget.groupData.id) {
              title = _buildTextField(context);
            }

            return Padding(
              padding: widget.margin,
              child: SizedBox(
                height: 50,
                child: Row(
                  children: [
                    _buildHeaderIcon(boardCustomData),
                    title,
                    const HSpace(6),
                    _groupOptionsButton(context),
                    const HSpace(4),
                    FlowyTooltip(
                      message:
                          LocaleKeys.board_column_addToColumnTopTooltip.tr(),
                      preferBelow: false,
                      child: FlowyIconButton(
                        width: 20,
                        icon: const FlowySvg(FlowySvgs.add_s),
                        iconColorOnHover:
                            Theme.of(context).colorScheme.onSurface,
                        onPressed: () => context.read<BoardBloc>().add(
                              BoardEvent.createRow(
                                widget.groupData.id,
                                OrderObjectPositionTypePB.Start,
                                null,
                                null,
                              ),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(BuildContext context) {
    return Expanded(
      child: KeyboardListener(
        focusNode: _keyboardListenerFocusNode,
        onKeyEvent: (event) {
          if ([LogicalKeyboardKey.enter, LogicalKeyboardKey.escape]
              .contains(event.logicalKey)) {
            _saveEdit();
          }
        },
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          onEditingComplete: _saveEdit,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            hoverColor: Colors.transparent,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            isDense: true,
          ),
        ),
      ),
    );
  }

  void _saveEdit() => context
      .read<BoardBloc>()
      .add(BoardEvent.endEditingHeader(widget.groupData.id, _controller.text));

  Widget _buildHeaderIcon(GroupData customData) =>
      switch (customData.fieldType) {
        FieldType.Checkbox => Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FlowySvg(
              customData.asCheckboxGroup()!.isCheck
                  ? FlowySvgs.check_filled_s
                  : FlowySvgs.uncheck_s,
              blendMode: BlendMode.dst,
              size: const Size.square(18),
            ),
          ),
        _ => const SizedBox.shrink(),
      };

  Widget _groupOptionsButton(BuildContext context) {
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
        final customGroupData = widget.groupData.customData as GroupData;
        final isDefault = customGroupData.group.isDefault;
        final menuItems = GroupOptions.values.toList();
        if (!customGroupData.fieldType.canEditHeader || isDefault) {
          menuItems.remove(GroupOptions.rename);
        }
        if (!customGroupData.fieldType.canDeleteGroup || isDefault) {
          menuItems.remove(GroupOptions.delete);
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
                    action.call(context, customGroupData.group);
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
}

enum GroupOptions {
  rename,
  hide,
  delete;

  void call(BuildContext context, GroupPB group) {
    switch (this) {
      case rename:
        context
            .read<BoardBloc>()
            .add(BoardEvent.startEditingHeader(group.groupId));
        break;
      case hide:
        context
            .read<BoardBloc>()
            .add(BoardEvent.setGroupVisibility(group, false));
        break;
      case delete:
        NavigatorAlertDialog(
          title: LocaleKeys.board_column_deleteColumnConfirmation.tr(),
          confirm: () {
            context
                .read<BoardBloc>()
                .add(BoardEvent.deleteGroup(group.groupId));
          },
        ).show(context);
        break;
    }
  }

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
