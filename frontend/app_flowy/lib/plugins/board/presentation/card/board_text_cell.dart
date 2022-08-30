import 'package:app_flowy/plugins/board/application/card/board_text_cell_bloc.dart';
import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_service.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/cell/cell_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'board_cell.dart';

class BoardTextCell extends StatefulWidget with EditableCell {
  final String groupId;
  final bool isFocus;
  @override
  final EditableCellNotifier? editableNotifier;
  final GridCellControllerBuilder cellControllerBuilder;

  const BoardTextCell({
    required this.groupId,
    required this.cellControllerBuilder,
    this.editableNotifier,
    this.isFocus = false,
    Key? key,
  }) : super(key: key);

  @override
  State<BoardTextCell> createState() => _BoardTextCellState();
}

class _BoardTextCellState extends State<BoardTextCell> {
  late BoardTextCellBloc _cellBloc;
  late TextEditingController _controller;
  SingleListenerFocusNode focusNode = SingleListenerFocusNode();

  @override
  void initState() {
    final cellController =
        widget.cellControllerBuilder.build() as GridCellController;
    _cellBloc = BoardTextCellBloc(cellController: cellController)
      ..add(const BoardTextCellEvent.initial());
    _controller = TextEditingController(text: _cellBloc.state.content);

    if (widget.isFocus) {
      focusNode.requestFocus();
    }

    widget.editableNotifier?.becomeFirstResponder.addListener(() {
      if (!mounted) return;
      focusNode.requestFocus();
      _cellBloc.add(const BoardTextCellEvent.enableEdit(true));
    });

    widget.editableNotifier?.resignFirstResponder.addListener(() {
      if (!mounted) return;
      _cellBloc.add(const BoardTextCellEvent.enableEdit(false));
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocListener<BoardTextCellBloc, BoardTextCellState>(
        listener: (context, state) {
          if (_controller.text != state.content) {
            _controller.text = state.content;
          }
        },
        child: BlocBuilder<BoardTextCellBloc, BoardTextCellState>(
          buildWhen: (previous, current) =>
              previous.enableEdit != current.enableEdit,
          builder: (context, state) {
            return TextField(
              // autofocus: true,
              // enabled: state.enableEdit,
              controller: _controller,
              focusNode: focusNode,
              onChanged: (value) => focusChanged(),
              onEditingComplete: () => focusNode.unfocus(),
              maxLines: 1,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(vertical: 6),
                border: InputBorder.none,
                isDense: true,
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> focusChanged() async {
    _cellBloc.add(BoardTextCellEvent.updateText(_controller.text));
  }

  @override
  Future<void> dispose() async {
    _cellBloc.close();
    _controller.dispose();
    focusNode.dispose();
    super.dispose();
  }
}
