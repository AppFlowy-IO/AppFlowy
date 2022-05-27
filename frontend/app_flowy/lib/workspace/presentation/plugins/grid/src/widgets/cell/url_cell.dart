import 'dart:async';
import 'package:app_flowy/workspace/application/grid/cell/url_cell_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_flowy/workspace/application/grid/prelude.dart';
import 'cell_builder.dart';

class GridURLCellStyle extends GridCellStyle {
  String? placeholder;

  GridURLCellStyle({
    this.placeholder,
  });
}

class GridURLCell extends StatefulWidget with GridCellWidget {
  final GridCellContextBuilder cellContextBuilder;
  late final GridURLCellStyle? cellStyle;
  GridURLCell({
    required this.cellContextBuilder,
    GridCellStyle? style,
    Key? key,
  }) : super(key: key) {
    if (style != null) {
      cellStyle = (style as GridURLCellStyle);
    } else {
      cellStyle = null;
    }
  }

  @override
  State<GridURLCell> createState() => _GridURLCellState();
}

class _GridURLCellState extends State<GridURLCell> {
  late URLCellBloc _cellBloc;
  late TextEditingController _controller;
  late CellSingleFocusNode _focusNode;
  Timer? _delayOperation;

  @override
  void initState() {
    final cellContext = widget.cellContextBuilder.build() as GridURLCellContext;
    _cellBloc = URLCellBloc(cellContext: cellContext);
    _cellBloc.add(const URLCellEvent.initial());
    _controller = TextEditingController(text: _cellBloc.state.content);
    _focusNode = CellSingleFocusNode();

    _listenFocusNode();
    _listenRequestFocus(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocListener<URLCellBloc, URLCellState>(
        listener: (context, state) {
          if (_controller.text != state.content) {
            _controller.text = state.content;
          }
        },
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: (value) => focusChanged(),
          onEditingComplete: () => _focusNode.unfocus(),
          maxLines: null,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            contentPadding: EdgeInsets.zero,
            border: InputBorder.none,
            hintText: widget.cellStyle?.placeholder,
            isDense: true,
          ),
        ),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    widget.requestFocus.removeAllListener();
    _delayOperation?.cancel();
    _cellBloc.close();
    _focusNode.removeSingleListener();
    _focusNode.dispose();

    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GridURLCell oldWidget) {
    if (oldWidget != widget) {
      _listenFocusNode();
    }
    super.didUpdateWidget(oldWidget);
  }

  void _listenFocusNode() {
    widget.onFocus.value = _focusNode.hasFocus;
    _focusNode.setSingleListener(() {
      widget.onFocus.value = _focusNode.hasFocus;
      focusChanged();
    });
  }

  void _listenRequestFocus(BuildContext context) {
    widget.requestFocus.addListener(() {
      if (_focusNode.hasFocus == false && _focusNode.canRequestFocus) {
        FocusScope.of(context).requestFocus(_focusNode);
      }
    });
  }

  Future<void> focusChanged() async {
    if (mounted) {
      _delayOperation?.cancel();
      _delayOperation = Timer(const Duration(milliseconds: 300), () {
        if (_cellBloc.isClosed == false && _controller.text != _cellBloc.state.content) {
          _cellBloc.add(URLCellEvent.updateText(_controller.text));
        }
      });
    }
  }
}
