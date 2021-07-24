import 'dart:io';

import 'package:app_flowy/workspace/domain/i_doc.dart';
import 'package:flowy_editor/flowy_editor.dart';
import 'package:flutter/material.dart';

class EditorWdiget extends StatelessWidget {
  final FocusNode _focusNode = FocusNode();
  final Doc doc;

  EditorWdiget({Key? key, required this.doc}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = EditorController(
      document: doc.data,
      selection: const TextSelection.collapsed(offset: 0),
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _renderEditor(controller),
        _renderToolbar(controller),
      ],
    );
  }

  Widget _renderEditor(EditorController controller) {
    final editor = FlowyEditor(
      controller: controller,
      focusNode: _focusNode,
      scrollable: true,
      autoFocus: false,
      expands: false,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      readOnly: false,
      scrollBottomInset: 0,
      scrollController: ScrollController(),
    );
    return Expanded(child: editor);
  }

  Widget _renderToolbar(EditorController controller) {
    return FlowyToolbar.basic(
      controller: controller,
      onImageSelectCallback: _onImageSelection,
    );
  }

  Future<String> _onImageSelection(File file) {
    throw UnimplementedError();
  }
}
