import 'dart:async';
import 'package:app_flowy/plugins/grid/presentation/widgets/cell/prelude.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/plugins/grid/application/prelude.dart';
import '../../layout/sizes.dart';
import 'cell_builder.dart';

class GridTextCellStyle extends GridCellStyle {
  String? placeholder;

  GridTextCellStyle({
    this.placeholder,
  });
}

class GridTextCell extends GridCellWidget {
  final GridCellControllerBuilder cellControllerBuilder;
  late final GridTextCellStyle? cellStyle;
  GridTextCell({
    required this.cellControllerBuilder,
    GridCellStyle? style,
    Key? key,
  }) : super(key: key) {
    if (style != null) {
      cellStyle = (style as GridTextCellStyle);
    } else {
      cellStyle = null;
    }
  }

  @override
  GridFocusNodeCellState<GridTextCell> createState() => _GridTextCellState();
}

class _GridTextCellState extends GridFocusNodeCellState<GridTextCell> {
  late TextCellBloc _cellBloc;
  late TextEditingController _controller;
  Timer? _delayOperation;

  @override
  void initState() {
    final cellController = widget.cellControllerBuilder.build();
    _cellBloc = getIt<TextCellBloc>(param1: cellController);
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
          child: TextField(
            controller: _controller,
            focusNode: focusNode,
            onChanged: (value) => focusChanged(),
            onEditingComplete: () => focusNode.unfocus(),
            maxLines: null,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.only(
                top: GridSize.cellContentInsets.top,
                bottom: GridSize.cellContentInsets.bottom,
              ),
              border: InputBorder.none,
              hintText: widget.cellStyle?.placeholder,
              isDense: true,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _delayOperation = null;
    _cellBloc.close();
    super.dispose();
  }

  @override
  Future<void> focusChanged() async {
    if (mounted) {
      _delayOperation?.cancel();
      _delayOperation = Timer(const Duration(milliseconds: 30), () {
        if (_cellBloc.isClosed == false &&
            _controller.text != _cellBloc.state.content) {
          _cellBloc.add(TextCellEvent.updateText(_controller.text));
        }
      });
    }
  }

  @override
  String? onCopy() => _cellBloc.state.content;

  @override
  void onInsert(String value) {
    _cellBloc.add(TextCellEvent.updateText(value));
  }
}
