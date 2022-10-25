import 'package:app_flowy/plugins/board/application/card/board_text_cell_bloc.dart';
import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_service.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/cell/cell_builder.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/text_style.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:textstyle_extensions/textstyle_extensions.dart';
import 'board_cell.dart';
import 'define.dart';

class BoardTextCell extends StatefulWidget with EditableCell {
  final String groupId;
  @override
  final EditableCellNotifier? editableNotifier;
  final GridCellControllerBuilder cellControllerBuilder;

  const BoardTextCell({
    required this.groupId,
    required this.cellControllerBuilder,
    this.editableNotifier,
    Key? key,
  }) : super(key: key);

  @override
  State<BoardTextCell> createState() => _BoardTextCellState();
}

class _BoardTextCellState extends State<BoardTextCell> {
  late BoardTextCellBloc _cellBloc;
  late TextEditingController _controller;
  bool focusWhenInit = false;
  SingleListenerFocusNode focusNode = SingleListenerFocusNode();

  @override
  void initState() {
    final cellController =
        widget.cellControllerBuilder.build() as GridCellController;
    _cellBloc = BoardTextCellBloc(cellController: cellController)
      ..add(const BoardTextCellEvent.initial());
    _controller = TextEditingController(text: _cellBloc.state.content);
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
        _cellBloc.add(const BoardTextCellEvent.enableEdit(false));
      }
    });
    _bindEditableNotifier();
    super.initState();
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
      _cellBloc.add(BoardTextCellEvent.enableEdit(isEditing));
    });
  }

  @override
  void didUpdateWidget(covariant BoardTextCell oldWidget) {
    _bindEditableNotifier();
    super.didUpdateWidget(oldWidget);
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
          buildWhen: (previous, current) {
            if (previous.content != current.content &&
                _controller.text == current.content &&
                current.enableEdit) {
              return false;
            }

            return previous != current;
          },
          builder: (context, state) {
            if (state.content.isEmpty &&
                state.enableEdit == false &&
                focusWhenInit == false) {
              return const SizedBox();
            }

            //
            Widget child;
            if (state.enableEdit || focusWhenInit) {
              child = _buildTextField();
            } else {
              child = _buildText(state);
            }
            return Align(alignment: Alignment.centerLeft, child: child);
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

  Widget _buildText(BoardTextCellState state) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: BoardSizes.cardCellVPadding,
      ),
      child: FlowyText.medium(
        state.content,
        fontSize: 14,
        maxLines: null, // Enable multiple lines
      ),
    );
  }

  Widget _buildTextField() {
    return IntrinsicHeight(
      child: TextField(
        controller: _controller,
        focusNode: focusNode,
        onChanged: (value) => focusChanged(),
        onEditingComplete: () => focusNode.unfocus(),
        maxLines: null,
        style: TextStyles.body1.size(FontSizes.s14),
        decoration: InputDecoration(
          // Magic number 4 makes the textField take up the same space as FlowyText
          contentPadding: EdgeInsets.symmetric(
            vertical: BoardSizes.cardCellVPadding + 4,
          ),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }
}
