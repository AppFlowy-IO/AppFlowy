import 'package:app_flowy/plugins/doc/editor_styles.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/appearance.dart';
import 'package:app_flowy/plugins/doc/presentation/banner.dart';
import 'package:app_flowy/plugins/doc/presentation/toolbar/tool_bar.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'application/doc_bloc.dart';
import 'styles.dart';

class DocumentPage extends StatefulWidget {
  final ViewPB view;

  DocumentPage({Key? key, required this.view}) : super(key: ValueKey(view.id));

  @override
  State<DocumentPage> createState() => _DocumentPageState();
}

class _DocumentPageState extends State<DocumentPage> {
  late DocumentBloc documentBloc;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    documentBloc = getIt<DocumentBloc>(param1: super.widget.view)
      ..add(const DocumentEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<DocumentBloc>.value(value: documentBloc),
      ],
      child:
          BlocBuilder<DocumentBloc, DocumentState>(builder: (context, state) {
        return state.loadingState.map(
          // loading: (_) => const FlowyProgressIndicator(),
          loading: (_) =>
              SizedBox.expand(child: Container(color: Colors.transparent)),
          finish: (result) => result.successOrFail.fold(
            (_) {
              if (state.forceClose) {
                return _renderAppPage();
              } else {
                return _renderDocument(context, state);
              }
            },
            (err) => FlowyErrorPage(err.toString()),
          ),
        );
      }),
    );
  }

  @override
  Future<void> dispose() async {
    documentBloc.close();
    _focusNode.dispose();
    super.dispose();
  }

  Widget _renderDocument(BuildContext context, DocumentState state) {
    quill.QuillController controller = quill.QuillController(
      document: context.read<DocumentBloc>().document,
      selection: const TextSelection.collapsed(offset: 0),
    );
    return Column(
      children: [
        if (state.isDeleted) _renderBanner(context),
        _renderAppFlowyEditor(controller),
      ],
    );
  }

  Widget _renderBanner(BuildContext context) {
    return DocumentBanner(
      onRestore: () =>
          context.read<DocumentBloc>().add(const DocumentEvent.restorePage()),
      onDelete: () => context
          .read<DocumentBloc>()
          .add(const DocumentEvent.deletePermanently()),
    );
  }

  // FIXME: data persistence
  final EditorState _editorState = EditorState.empty();
  Widget _renderAppFlowyEditor(quill.QuillController controller) {
    final editor = AppFlowyEditor(
      editorState: _editorState,
      editorStyle: customEditorStyle(context),
    );
    return Expanded(
      child: SizedBox.expand(
        child: Container(
          color: Colors.red.withOpacity(0.3),
          child: editor,
        ),
      ),
    );
  }

  Widget _renderEditor(quill.QuillController controller) {
    final scrollController = ScrollController();

    final editor = quill.QuillEditor(
      controller: controller,
      focusNode: _focusNode,
      scrollable: true,
      paintCursorAboveText: true,
      autoFocus: controller.document.isEmpty(),
      expands: false,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      readOnly: false,
      scrollBottomInset: 0,
      scrollController: scrollController,
      customStyles: customStyles(context),
    );

    return Expanded(
      child: SizedBox.expand(child: editor),
    );
  }

  Widget _renderToolbar(quill.QuillController controller) {
    return ChangeNotifierProvider.value(
      value: Provider.of<AppearanceSettingModel>(context, listen: true),
      child: EditorToolbar.basic(
        controller: controller,
      ),
    );
  }

  Widget _renderAppPage() {
    return Container(
      color: Colors.black,
    );
  }
}
