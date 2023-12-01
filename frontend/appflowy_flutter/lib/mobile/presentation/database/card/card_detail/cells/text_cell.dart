import 'dart:async';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cell_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/text_cell/text_cell.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/text_cell/text_cell_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RowDetailTextCell extends GridCellWidget {
  RowDetailTextCell({
    super.key,
    required this.cellControllerBuilder,
    GridCellStyle? style,
  }) {
    if (style != null) {
      cellStyle = (style as GridTextCellStyle);
    } else {
      cellStyle = const GridTextCellStyle();
    }
  }

  final CellControllerBuilder cellControllerBuilder;
  late final GridTextCellStyle cellStyle;

  @override
  GridEditableTextCell<RowDetailTextCell> createState() =>
      _RowDetailTextCellState();
}

class _RowDetailTextCellState extends GridEditableTextCell<RowDetailTextCell> {
  late final TextCellBloc _cellBloc;
  late final TextEditingController _controller;

  @override
  SingleListenerFocusNode focusNode = SingleListenerFocusNode();

  @override
  void initState() {
    super.initState();
    final cellController =
        widget.cellControllerBuilder.build() as TextCellController;
    _cellBloc = TextCellBloc(cellController: cellController)
      ..add(const TextCellEvent.initial());
    _controller = TextEditingController(text: _cellBloc.state.content);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocListener<TextCellBloc, TextCellState>(
        listener: (context, state) {
          if (_controller.text != state.content) {
            _controller.text = state.content;
          }
        },
        child: TextField(
          controller: _controller,
          focusNode: focusNode,
          style: widget.cellStyle.textStyle,
          maxLines: null,
          decoration: InputDecoration(
            enabledBorder:
                _getInputBorder(color: Theme.of(context).colorScheme.outline),
            focusedBorder:
                _getInputBorder(color: Theme.of(context).colorScheme.primary),
            hintText: widget.cellStyle.placeholder,
            contentPadding: widget.cellStyle.cellPadding ??
                const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            isCollapsed: true,
            isDense: true,
            constraints: const BoxConstraints(minHeight: 48),
            hintStyle: widget.cellStyle.textStyle
                ?.copyWith(color: Theme.of(context).hintColor),
          ),
          onTapOutside: (event) =>
              FocusManager.instance.primaryFocus?.unfocus(),
        ),
      ),
    );
  }

  InputBorder _getInputBorder({Color? color}) {
    if (!widget.cellStyle.useRoundedBorder) {
      return InputBorder.none;
    }
    return OutlineInputBorder(
      borderSide: BorderSide(color: color!),
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      gapPadding: 0,
    );
  }

  @override
  Future<void> dispose() async {
    _cellBloc.close();
    super.dispose();
  }

  @override
  String? onCopy() => _cellBloc.state.content;

  @override
  Future<void> focusChanged() {
    _cellBloc.add(TextCellEvent.updateText(_controller.text));
    return super.focusChanged();
  }
}
