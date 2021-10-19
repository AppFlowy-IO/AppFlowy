import 'dart:io';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/doc/doc_bloc.dart';
import 'package:app_flowy/workspace/domain/i_doc.dart';
import 'package:editor/flutter_quill.dart';
import 'package:flowy_infra_ui/style_widget/progress_indicator.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DocPage extends StatefulWidget {
  final View view;

  const DocPage({Key? key, required this.view}) : super(key: key);

  @override
  State<DocPage> createState() => _DocPageState();
}

class _DocPageState extends State<DocPage> {
  late DocBloc docBloc;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    docBloc = getIt<DocBloc>(param1: super.widget.view.id)..add(const DocEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<DocBloc>.value(value: docBloc),
      ],
      child: BlocBuilder<DocBloc, DocState>(builder: (context, state) {
        return state.loadState.map(
          loading: (_) => const FlowyProgressIndicator(),
          finish: (result) => result.successOrFail.fold(
            (doc) => _renderDoc(context, doc),
            (err) => FlowyErrorPage(err.toString()),
          ),
        );
      }),
    );
  }

  @override
  Future<void> dispose() async {
    docBloc.close();
    super.dispose();
  }

  Widget _renderDoc(BuildContext context, FlowyDoc doc) {
    QuillController controller = QuillController(
      document: doc.document,
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

  Widget _renderEditor(QuillController controller) {
    final editor = QuillEditor(
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
    return Expanded(
      child: Padding(padding: const EdgeInsets.all(10), child: editor),
    );
  }

  Widget _renderToolbar(QuillController controller) {
    return QuillToolbar.basic(
      controller: controller,
    );
  }

  Future<String> _onImageSelection(File file) {
    throw UnimplementedError();
  }
}

// import 'package:flowy_editor/flowy_editor.dart';

// ignore: must_be_immutable
// class DocPage extends StatefulWidget {
//   late EditorController controller;
//   late DocEditBloc editBloc;
//   final FlowyDoc doc;

//   DocPage({Key? key, required this.doc}) : super(key: key) {
//     editBloc = getIt<DocEditBloc>(param1: doc.id);
//     controller = EditorController(
//       document: doc.document,
//       selection: const TextSelection.collapsed(offset: 0),
//     );
//   }

//   @override
//   State<DocPage> createState() => _DocPageState();
// }

// class _DocPageState extends State<DocPage> {
//   final FocusNode _focusNode = FocusNode();

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider.value(
//       value: widget.editBloc,
//       child: BlocBuilder<DocEditBloc, DocEditState>(
//         builder: (ctx, state) {
//           return Column(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               _renderEditor(widget.controller),
//               _renderToolbar(widget.controller),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   @override
//   Future<void> dispose() async {
//     widget.editBloc.add(const DocEditEvent.close());
//     widget.editBloc.close();
//     super.dispose();
//     await widget.doc.close();
//   }

//   Widget _renderEditor(EditorController controller) {
//     final editor = FlowyEditor(
//       controller: controller,
//       focusNode: _focusNode,
//       scrollable: true,
//       autoFocus: false,
//       expands: false,
//       padding: const EdgeInsets.symmetric(horizontal: 8.0),
//       readOnly: false,
//       scrollBottomInset: 0,
//       scrollController: ScrollController(),
//     );
//     return Expanded(
//       child: Padding(padding: const EdgeInsets.all(10), child: editor),
//     );
//   }

//   Widget _renderToolbar(EditorController controller) {
//     return FlowyToolbar.basic(
//       controller: controller,
//       onImageSelectCallback: _onImageSelection,
//     );
//   }

//   Future<String> _onImageSelection(File file) {
//     throw UnimplementedError();
//   }
// }
