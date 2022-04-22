import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/prelude.dart';
import 'cell_builder.dart';

class GridTextCellStyle extends GridCellStyle {
  String? placeholder;

  GridTextCellStyle({
    this.placeholder,
  });
}

class GridTextCell extends GridCellWidget {
  final GridCellContext cellContext;
  late final GridTextCellStyle? cellStyle;
  GridTextCell({
    required this.cellContext,
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
  State<GridTextCell> createState() => _GridTextCellState();
}

class _GridTextCellState extends State<GridTextCell> {
  late TextCellBloc _cellBloc;
  late TextEditingController _controller;
  late FocusNode _focusNode;

  Timer? _delayOperation;

  @override
  void initState() {
    _cellBloc = getIt<TextCellBloc>(param1: widget.cellContext);
    _cellBloc.add(const TextCellEvent.initial());
    _controller = TextEditingController(text: _cellBloc.state.content);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      widget.onFocus.value = _focusNode.hasFocus;
      focusChanged();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocConsumer<TextCellBloc, TextCellState>(
        listener: (context, state) {
          if (_controller.text != state.content) {
            _controller.text = state.content;
          }
        },
        buildWhen: (previous, current) => previous.content != current.content,
        builder: (context, state) {
          return TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: (value) => focusChanged(),
            onEditingComplete: () => _focusNode.unfocus(),
            maxLines: 1,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              hintText: widget.cellStyle?.placeholder,
              isDense: true,
            ),
          );
        },
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _delayOperation?.cancel();
    _cellBloc.close();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> focusChanged() async {
    if (mounted) {
      _delayOperation?.cancel();
      _delayOperation = Timer(const Duration(milliseconds: 300), () {
        if (_cellBloc.isClosed == false && _controller.text != _cellBloc.state.content) {
          _cellBloc.add(TextCellEvent.updateText(_controller.text));
        }
      });
    }
  }
}
