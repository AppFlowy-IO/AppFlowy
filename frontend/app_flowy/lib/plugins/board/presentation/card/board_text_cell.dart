import 'package:app_flowy/plugins/board/application/card/board_text_cell_bloc.dart';
import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_service.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/cell/cell_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BoardTextCell extends StatefulWidget {
  final String groupId;
  final bool isFocus;

  final GridCellControllerBuilder cellControllerBuilder;

  const BoardTextCell({
    required this.groupId,
    required this.cellControllerBuilder,
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
        child: TextField(
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
