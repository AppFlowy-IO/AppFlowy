import 'dart:async';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/text_cell/text_cell_bloc.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../grid/presentation/layout/sizes.dart';
import '../../cell_builder.dart';

class GridTextCellStyle extends GridCellStyle {
  String? placeholder;
  TextStyle? textStyle;
  bool? autofocus;
  double emojiFontSize;
  double emojiHPadding;
  bool showEmoji;

  GridTextCellStyle({
    this.placeholder,
    this.textStyle,
    this.autofocus,
    this.showEmoji = true,
    this.emojiFontSize = 16,
    this.emojiHPadding = 0,
  });
}

class GridTextCell extends GridCellWidget {
  final CellControllerBuilder cellControllerBuilder;
  late final GridTextCellStyle cellStyle;
  GridTextCell({
    required this.cellControllerBuilder,
    GridCellStyle? style,
    Key? key,
  }) : super(key: key) {
    if (style != null) {
      cellStyle = (style as GridTextCellStyle);
    } else {
      cellStyle = GridTextCellStyle();
    }
  }

  @override
  GridFocusNodeCellState<GridTextCell> createState() => _GridTextCellState();
}

class _GridTextCellState extends GridFocusNodeCellState<GridTextCell> {
  late TextCellBloc _cellBloc;
  late TextEditingController _controller;

  @override
  void initState() {
    final cellController =
        widget.cellControllerBuilder.build() as TextCellController;
    _cellBloc = TextCellBloc(cellController: cellController);
    _cellBloc.add(const TextCellEvent.initial());
    _controller = TextEditingController(text: _cellBloc.state.content);
    super.initState();
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
        child: Padding(
          padding: EdgeInsets.only(
            left: GridSize.cellContentInsets.left,
            right: GridSize.cellContentInsets.right,
          ),
          child: Row(
            children: [
              if (widget.cellStyle.showEmoji)
                // Only build the emoji when it changes
                BlocBuilder<TextCellBloc, TextCellState>(
                  buildWhen: (p, c) => p.emoji != c.emoji,
                  builder: (context, state) => Center(
                    child: FlowyText(
                      state.emoji,
                      fontSize: widget.cellStyle.emojiFontSize,
                    ),
                  ),
                ),
              HSpace(widget.cellStyle.emojiHPadding),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: focusNode,
                  maxLines: null,
                  style: widget.cellStyle.textStyle ??
                      Theme.of(context).textTheme.bodyMedium,
                  autofocus: widget.cellStyle.autofocus ?? false,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.only(
                      top: GridSize.cellContentInsets.top,
                      bottom: GridSize.cellContentInsets.bottom,
                    ),
                    border: InputBorder.none,
                    hintText: widget.cellStyle.placeholder,
                    isDense: true,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
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
  void onInsert(String value) {
    _cellBloc.add(TextCellEvent.updateText(value));
  }

  @override
  Future<void> focusChanged() {
    _cellBloc.add(
      TextCellEvent.updateText(_controller.text),
    );
    return super.focusChanged();
  }
}
