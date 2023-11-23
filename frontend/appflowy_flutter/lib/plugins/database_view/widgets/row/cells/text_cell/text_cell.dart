import 'dart:async';

import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/text_cell/text_cell_bloc.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../grid/presentation/layout/sizes.dart';
import '../../cell_builder.dart';

class GridTextCellStyle extends GridCellStyle {
  final String? placeholder;
  final TextStyle? textStyle;
  final EdgeInsets? cellPadding;
  final bool autofocus;
  final double emojiFontSize;
  final double emojiHPadding;
  final bool showEmoji;
  final bool useRoundedBorder;

  const GridTextCellStyle({
    this.placeholder,
    this.textStyle,
    this.cellPadding,
    this.autofocus = false,
    this.showEmoji = true,
    this.emojiFontSize = 16,
    this.emojiHPadding = 4,
    this.useRoundedBorder = false,
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
      cellStyle = const GridTextCellStyle();
    }
  }

  @override
  GridEditableTextCell<GridTextCell> createState() => _GridTextCellState();
}

class _GridTextCellState extends GridEditableTextCell<GridTextCell> {
  late TextCellBloc _cellBloc;
  late TextEditingController _controller;

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
        child: Padding(
          padding: widget.cellStyle.cellPadding ??
              EdgeInsets.only(
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
                child: widget.cellStyle.useRoundedBorder
                    ? FlowyTextField(
                        controller: _controller,
                        textStyle: widget.cellStyle.textStyle ??
                            Theme.of(context).textTheme.bodyMedium,
                        focusNode: focusNode,
                        autoFocus: widget.cellStyle.autofocus,
                        hintText: widget.cellStyle.placeholder,
                        onChanged: (text) => _cellBloc.add(
                          TextCellEvent.updateText(text),
                        ),
                        debounceDuration: const Duration(milliseconds: 300),
                      )
                    : TextField(
                        controller: _controller,
                        focusNode: focusNode,
                        maxLines: null,
                        style: widget.cellStyle.textStyle ??
                            Theme.of(context).textTheme.bodyMedium,
                        autofocus: widget.cellStyle.autofocus,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.only(
                            top: GridSize.cellContentInsets.top,
                            bottom: GridSize.cellContentInsets.bottom,
                          ),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          hintText: widget.cellStyle.placeholder,
                          isDense: true,
                        ),
                        onTapOutside: (_) => focusNode.unfocus(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _controller.dispose();
    _cellBloc.close();
    super.dispose();
  }

  @override
  String? onCopy() => _cellBloc.state.content;

  @override
  Future<void> focusChanged() {
    _cellBloc.add(
      TextCellEvent.updateText(_controller.text),
    );
    return super.focusChanged();
  }
}
