import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/text_cell/text_cell_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../editable_cell_builder.dart';
import 'card_cell.dart';

class TextCardCellStyle extends CardCellStyle {
  final TextStyle textStyle;
  final TextStyle titleTextStyle;
  final int? maxLines;

  TextCardCellStyle({
    required super.padding,
    required this.textStyle,
    required this.titleTextStyle,
    this.maxLines = 1,
  });
}

class TextCardCell extends CardCell<TextCardCellStyle> with EditableCell {
  final TextCellController cellController;
  final bool showNotes;

  const TextCardCell({
    super.key,
    required super.style,
    required this.cellController,
    this.editableNotifier,
    this.showNotes = false,
  });

  @override
  final EditableCardNotifier? editableNotifier;

  @override
  State<TextCardCell> createState() => _TextCellState();
}

class _TextCellState extends State<TextCardCell> {
  late TextEditingController _textEditingController;
  bool focusWhenInit = false;
  final focusNode = SingleListenerFocusNode();

  TextCellBloc get cellBloc => context.read<TextCellBloc>();

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
      if (!mounted) return;

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
    return BlocProvider(
      create: (context) {
        return TextCellBloc(cellController: widget.cellController)
          ..add(const TextCellEvent.initial());
      },
      child: BlocListener<TextCellBloc, TextCellState>(
        listener: (context, state) {
          if (_textEditingController.text != state.content) {
            _textEditingController.text = state.content;
          }
        },
        child: BlocBuilder<TextCellBloc, TextCellState>(
          buildWhen: (previous, current) {
            if (previous.content != current.content &&
                _textEditingController.text == current.content &&
                current.enableEdit) {
              return false;
            }

            return previous != current;
          },
          builder: (context, state) {
            final isTitle = cellBloc.cellController.fieldInfo.isPrimary;
            if (state.content.isEmpty &&
                state.enableEdit == false &&
                focusWhenInit == false &&
                !isTitle) {
              return const SizedBox.shrink();
            }

            final child = state.enableEdit || focusWhenInit
                ? _buildTextField()
                : _buildText(state, isTitle);

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.showNotes) ...[
                  FlowyTooltip(
                    message: LocaleKeys.board_notesTooltip.tr(),
                    child: FlowySvg(
                      FlowySvgs.notes_s,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                  const HSpace(4),
                ],
                Expanded(child: child),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> focusChanged() async {
    cellBloc.add(TextCellEvent.updateText(_textEditingController.text));
  }

  @override
  Future<void> dispose() async {
    _textEditingController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  Widget _buildText(TextCellState state, bool isTitle) {
    final text = state.content.isEmpty
        ? isTitle
            ? LocaleKeys.grid_row_titlePlaceholder.tr()
            : LocaleKeys.grid_row_textPlaceholder.tr()
        : state.content;
    final color = state.content.isEmpty ? Theme.of(context).hintColor : null;
    final textStyle =
        isTitle ? widget.style.titleTextStyle : widget.style.textStyle;
    return Padding(
      padding: widget.style.padding,
      child: Text(
        text,
        style: textStyle.copyWith(color: color),
        maxLines: widget.style.maxLines,
      ),
    );
  }

  Widget _buildTextField() {
    return TextField(
      controller: _textEditingController,
      focusNode: focusNode,
      onChanged: (value) => focusChanged(),
      onEditingComplete: () => focusNode.unfocus(),
      maxLines: null,
      style: widget.style.titleTextStyle,
      decoration: InputDecoration(
        contentPadding: widget.style.padding,
        border: InputBorder.none,
        isDense: true,
        isCollapsed: true,
        hintText: LocaleKeys.grid_row_titlePlaceholder.tr(),
      ),
    );
  }
}
