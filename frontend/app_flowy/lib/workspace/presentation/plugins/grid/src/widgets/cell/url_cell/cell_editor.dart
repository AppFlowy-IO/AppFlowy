import 'package:app_flowy/workspace/application/grid/cell/cell_service/cell_service.dart';
import 'package:app_flowy/workspace/application/grid/cell/url_cell_editor_bloc.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

class URLCellEditor extends StatefulWidget {
  final GridURLCellContext cellContext;
  const URLCellEditor({required this.cellContext, Key? key}) : super(key: key);

  @override
  State<URLCellEditor> createState() => _URLCellEditorState();

  static void show(
    BuildContext context,
    GridURLCellContext cellContext,
  ) {
    FlowyOverlay.of(context).remove(identifier());
    final editor = URLCellEditor(
      cellContext: cellContext,
    );

    //
    FlowyOverlay.of(context).insertWithAnchor(
      widget: OverlayContainer(
        child: SizedBox(width: 200, child: editor),
        constraints: BoxConstraints.loose(const Size(300, 160)),
      ),
      identifier: URLCellEditor.identifier(),
      anchorContext: context,
      anchorDirection: AnchorDirection.bottomWithCenterAligned,
    );
  }

  static String identifier() {
    return (URLCellEditor).toString();
  }
}

class _URLCellEditorState extends State<URLCellEditor> {
  late URLCellEditorBloc _cellBloc;
  late TextEditingController _controller;

  @override
  void initState() {
    _cellBloc = URLCellEditorBloc(cellContext: widget.cellContext);
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
      if (_cellBloc.isClosed == false && _controller.text != _cellBloc.state.content) {
        _cellBloc.add(URLCellEditorEvent.updateText(_controller.text));
      }
    }
  }
}
