import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_service.dart';
import 'package:app_flowy/plugins/grid/application/cell/url_cell_editor_bloc.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

class URLCellEditor extends StatefulWidget {
  final GridURLCellController cellController;
  const URLCellEditor({required this.cellController, Key? key})
      : super(key: key);

  @override
  State<URLCellEditor> createState() => _URLCellEditorState();
}

class _URLCellEditorState extends State<URLCellEditor> {
  late URLCellEditorBloc _cellBloc;
  late TextEditingController _controller;

  @override
  void initState() {
    _cellBloc = URLCellEditorBloc(cellController: widget.cellController);
    _cellBloc.add(const URLCellEditorEvent.initial());
    _controller = TextEditingController(text: _cellBloc.state.content);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocListener<URLCellEditorBloc, URLCellEditorState>(
        listener: (context, state) {
          if (_controller.text != state.content) {
            _controller.text = state.content;
          }
        },
        child: TextField(
          autofocus: true,
          controller: _controller,
          onChanged: (value) => focusChanged(),
          maxLines: null,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.zero,
            border: InputBorder.none,
            hintText: "",
            isDense: true,
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

  Future<void> focusChanged() async {
    if (mounted) {
      if (_cellBloc.isClosed == false &&
          _controller.text != _cellBloc.state.content) {
        _cellBloc.add(URLCellEditorEvent.updateText(_controller.text));
      }
    }
  }
}

class URLEditorPopover extends StatelessWidget {
  final GridURLCellController cellController;
  const URLEditorPopover({required this.cellController, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: URLCellEditor(
          cellController: cellController,
        ),
      ),
    );
  }
}
