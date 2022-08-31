import 'package:app_flowy/plugins/board/application/card/board_text_cell_bloc.dart';
import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_service.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/cell/cell_builder.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
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

    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        _cellBloc.add(const BoardTextCellEvent.enableEdit(false));
      }
    });

    widget.editableNotifier?.becomeFirstResponder.addListener(() {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        focusNode.requestFocus();
      });
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
          builder: (context, state) {
            Widget child;
            if (state.enableEdit) {
              child = TextField(
                controller: _controller,
                focusNode: focusNode,
                onChanged: (value) => focusChanged(),
                onEditingComplete: () => focusNode.unfocus(),
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Mulish',
                ),
                decoration: const InputDecoration(
                  // Magic number 4 makes the textField take up the same space as FlowyText
                  contentPadding: EdgeInsets.symmetric(vertical: 4),
                  border: InputBorder.none,
                  isDense: true,
                ),
              );
            } else {
              child = FlowyText.medium(state.content, fontSize: 14);
            }

            return Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: child,
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
