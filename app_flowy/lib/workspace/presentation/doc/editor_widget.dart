import 'dart:io';

import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/doc/doc_bloc.dart';
import 'package:app_flowy/workspace/domain/i_doc.dart';
import 'package:flowy_editor/flowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EditorWdiget extends StatelessWidget {
  final FocusNode _focusNode = FocusNode();
  late EditorController controller;
  final Doc doc;

  EditorWdiget({Key? key, required this.doc}) : super(key: key) {
    controller = EditorController(
      document: doc.data,
      selection: const TextSelection.collapsed(offset: 0),
      persistence: getIt<EditorPersistence>(param1: doc.info.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<DocBloc>(param1: doc.info.id),
      child: BlocBuilder<DocBloc, DocState>(
        builder: (ctx, state) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _renderEditor(controller),
              _renderToolbar(controller),
            ],
          );
        },
      ),
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
