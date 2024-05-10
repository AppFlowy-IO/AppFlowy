import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/text_cell_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../editable_cell_builder.dart';
import 'card_cell.dart';

class TextCardCellStyle extends CardCellStyle {
  TextCardCellStyle({
    required super.padding,
    required this.textStyle,
    required this.titleTextStyle,
    this.maxLines = 1,
  });

  final TextStyle textStyle;
  final TextStyle titleTextStyle;
  final int? maxLines;
}

class TextCardCell extends CardCell<TextCardCellStyle> with EditableCell {
  const TextCardCell({
    super.key,
    required super.style,
    required this.databaseController,
    required this.cellContext,
    this.showNotes = false,
    this.editableNotifier,
  });

  final DatabaseController databaseController;
  final CellContext cellContext;
  final bool showNotes;

  @override
  final EditableCardNotifier? editableNotifier;

  @override
  State<TextCardCell> createState() => _TextCellState();
}

class _TextCellState extends State<TextCardCell> {
  late final cellBloc = TextCellBloc(
    cellController: makeCellController(
      widget.databaseController,
      widget.cellContext,
    ).as(),
  );
  late final TextEditingController _textEditingController =
      TextEditingController(text: cellBloc.state.content);
  final focusNode = SingleListenerFocusNode();

  bool focusWhenInit = false;

  @override
  void initState() {
    super.initState();
    focusWhenInit = widget.editableNotifier?.isCellEditing.value ?? false;
    if (focusWhenInit) {
      focusNode.requestFocus();
    }

    // If the focusNode lost its focus, the widget's editableNotifier will
    // set to false, which will cause the [EditableRowNotifier] to receive
    // end edit event.
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        focusWhenInit = false;
        widget.editableNotifier?.isCellEditing.value = false;
        cellBloc.add(const TextCellEvent.enableEdit(false));
      }
    });
    _bindEditableNotifier();
  }

  void _bindEditableNotifier() {
    widget.editableNotifier?.isCellEditing.addListener(() {
      if (!mounted) {
        return;
      }

      final isEditing = widget.editableNotifier?.isCellEditing.value ?? false;
      if (isEditing) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          focusNode.requestFocus();
        });
      }
      cellBloc.add(TextCellEvent.enableEdit(isEditing));
    });
  }

  @override
  void didUpdateWidget(covariant oldWidget) {
    _bindEditableNotifier();
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cellBloc,
      child: BlocConsumer<TextCellBloc, TextCellState>(
        listenWhen: (previous, current) => previous.content != current.content,
        listener: (context, state) {
          if (!state.enableEdit) {
            _textEditingController.text = state.content;
          }
        },
        builder: (context, state) {
          final isTitle = cellBloc.cellController.fieldInfo.isPrimary;
          if (state.content.isEmpty &&
              state.enableEdit == false &&
              focusWhenInit == false &&
              !isTitle) {
            return const SizedBox.shrink();
          }

          final icon = isTitle ? _buildIcon(state) : null;
          final child = isTitle
              ? _buildTextField(state.enableEdit || focusWhenInit)
              : _buildText(state.content);

          return Row(
            children: [
              if (icon != null) ...[
                icon,
                const HSpace(4.0),
              ],
              Expanded(child: child),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    focusNode.dispose();
    cellBloc.close();
    super.dispose();
  }

  Widget? _buildIcon(TextCellState state) {
    if (state.emoji.isNotEmpty) {
      return Text(
        state.emoji,
        style: widget.style.titleTextStyle,
      );
    }
    if (widget.showNotes) {
      return FlowyTooltip(
        message: LocaleKeys.board_notesTooltip.tr(),
        child: FlowySvg(
          FlowySvgs.notes_s,
          color: Theme.of(context).hintColor,
        ),
      );
    }
    return null;
  }

  Widget _buildText(String content) {
    final text =
        content.isEmpty ? LocaleKeys.grid_row_textPlaceholder.tr() : content;
    final color = content.isEmpty ? Theme.of(context).hintColor : null;

    return Padding(
      padding: widget.style.padding,
      child: Text(
        text,
        style: widget.style.textStyle.copyWith(color: color),
        maxLines: widget.style.maxLines,
      ),
    );
  }

  Widget _buildTextField(bool isEditing) {
    final padding =
        widget.style.padding.add(const EdgeInsets.symmetric(vertical: 4.0));
    return IgnorePointer(
      ignoring: !isEditing,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              focusNode.unfocus(),
        },
        child: TextField(
          controller: _textEditingController,
          focusNode: focusNode,
          onChanged: (_) {
            if (_textEditingController.value.composing.isCollapsed) {
              cellBloc
                  .add(TextCellEvent.updateText(_textEditingController.text));
            }
          },
          onEditingComplete: () => focusNode.unfocus(),
          maxLines: isEditing ? null : 2,
          minLines: 1,
          textInputAction: TextInputAction.done,
          readOnly: !isEditing,
          enableInteractiveSelection: isEditing,
          style: widget.style.titleTextStyle,
          decoration: InputDecoration(
            contentPadding: padding,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            isDense: true,
            isCollapsed: true,
            hintText: LocaleKeys.grid_row_titlePlaceholder.tr(),
            hintStyle: widget.style.titleTextStyle.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
          onTapOutside: (_) {},
        ),
      ),
    );
  }
}
