import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/application/field/type_option/type_option_data_parser.dart';
import 'package:appflowy/plugins/database/board/application/board_bloc.dart';
import 'package:appflowy/plugins/database/board/group_ext.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/extension.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_board/appflowy_board.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'board_column_header.dart';

/// This column header is used for the MultiSelect and SingleSelect field types.
class EditableColumnHeader extends StatefulWidget {
  const EditableColumnHeader({
    super.key,
    required this.databaseController,
    required this.groupData,
    required this.isEditing,
    required this.onSubmitted,
  });

  final DatabaseController databaseController;
  final AppFlowyGroupData groupData;
  final ValueNotifier<bool> isEditing;
  final void Function(String columnName) onSubmitted;

  @override
  State<EditableColumnHeader> createState() => _EditableColumnHeaderState();
}

class _EditableColumnHeaderState extends State<EditableColumnHeader> {
  late final FocusNode focusNode;
  late final TextEditingController textController = TextEditingController(
    text: _generateGroupName(),
  );

  GroupData get customData => widget.groupData.customData;

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode(
      onKeyEvent: (node, event) {
        if (event.logicalKey == LogicalKeyboardKey.escape &&
            event is KeyUpEvent) {
          focusNode.unfocus();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
    )..addListener(() {
        if (!focusNode.hasFocus) {
          widget.isEditing.value = false;
          widget.onSubmitted(textController.text);
        } else {
          textController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: textController.text.length,
          );
        }
      });
  }

  @override
  void didUpdateWidget(covariant oldWidget) {
    if (oldWidget.groupData.customData != widget.groupData.customData) {
      textController.text = _generateGroupName();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    focusNode.dispose();
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: widget.isEditing,
            builder: (context, isEditing, _) {
              if (isEditing) {
                focusNode.requestFocus();
              }
              return isEditing ? _buildTextField() : _buildTitle();
            },
          ),
        ),
        const HSpace(6),
        GroupOptionsButton(
          groupData: widget.groupData,
          isEditing: widget.isEditing,
        ),
        const HSpace(4),
        CreateCardFromTopButton(
          groupId: widget.groupData.id,
        ),
      ],
    );
  }

  Widget _buildTitle() {
    final (backgroundColor, dotColor) = _generateGroupColor();
    return FlowyTooltip(
      message: LocaleKeys.board_column_renameGroupTooltip.tr(),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            widget.isEditing.value = true;
          },
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Container(
              height: 20,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      height: 6,
                      width: 6,
                      decoration: BoxDecoration(
                        color: dotColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const HSpace(4.0),
                  FlowyText.medium(
                    _generateGroupName(),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField() {
    return TextField(
      controller: textController,
      focusNode: focusNode,
      onEditingComplete: () {
        widget.isEditing.value = false;
      },
      onSubmitted: widget.onSubmitted,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        hoverColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
    );
  }

  String _generateGroupName() {
    return customData.group.generateGroupName(widget.databaseController);
  }

  (Color? backgroundColor, Color? dotColor) _generateGroupColor() {
    Color? backgroundColor;
    Color? dotColor;

    final groupId = widget.groupData.id;
    final fieldId = customData.fieldInfo.id;
    final field = widget.databaseController.fieldController.getField(fieldId);
    if (field != null) {
      final selectOptions = switch (field.fieldType) {
        FieldType.MultiSelect => MultiSelectTypeOptionDataParser()
            .fromBuffer(field.field.typeOptionData)
            .options,
        FieldType.SingleSelect => SingleSelectTypeOptionDataParser()
            .fromBuffer(field.field.typeOptionData)
            .options,
        _ => <SelectOptionPB>[],
      };

      final colorPB =
          selectOptions.firstWhereOrNull((e) => e.id == groupId)?.color;

      if (colorPB != null) {
        backgroundColor = colorPB.toColor(context);
        dotColor = getColorOfDot(colorPB);
      }
    }

    return (backgroundColor, dotColor);
  }

  // move to theme file and allow theme customization once palette is finalized
  Color getColorOfDot(SelectOptionColorPB color) {
    return switch (Theme.of(context).brightness) {
      Brightness.light => switch (color) {
          SelectOptionColorPB.Purple => const Color(0xFFAB8DFF),
          SelectOptionColorPB.Pink => const Color(0xFFFF8EF5),
          SelectOptionColorPB.LightPink => const Color(0xFFFF85A9),
          SelectOptionColorPB.Orange => const Color(0xFFFFBC7E),
          SelectOptionColorPB.Yellow => const Color(0xFFFCD86F),
          SelectOptionColorPB.Lime => const Color(0xFFC6EC41),
          SelectOptionColorPB.Green => const Color(0xFF74F37D),
          SelectOptionColorPB.Aqua => const Color(0xFF40F0D1),
          SelectOptionColorPB.Blue => const Color(0xFF00C8FF),
          _ => throw ArgumentError,
        },
      Brightness.dark => switch (color) {
          SelectOptionColorPB.Purple => const Color(0xFF502FD6),
          SelectOptionColorPB.Pink => const Color(0xFFBF1CC0),
          SelectOptionColorPB.LightPink => const Color(0xFFC42A53),
          SelectOptionColorPB.Orange => const Color(0xFFD77922),
          SelectOptionColorPB.Yellow => const Color(0xFFC59A1A),
          SelectOptionColorPB.Lime => const Color(0xFFA4C824),
          SelectOptionColorPB.Green => const Color(0xFF23CA2E),
          SelectOptionColorPB.Aqua => const Color(0xFF19CCAC),
          SelectOptionColorPB.Blue => const Color(0xFF04A9D7),
          _ => throw ArgumentError,
        }
    };
  }
}
