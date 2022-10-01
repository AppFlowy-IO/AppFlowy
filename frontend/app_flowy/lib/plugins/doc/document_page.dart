import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/appearance.dart';
import 'package:app_flowy/plugins/doc/presentation/banner.dart';
import 'package:app_flowy/plugins/doc/presentation/toolbar/tool_bar.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_scroll_bar.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'application/doc_bloc.dart';
import 'styles.dart';

class DocumentPage extends StatefulWidget {
  final VoidCallback onDeleted;
  final ViewPB view;

  DocumentPage({
    required this.view,
    required this.onDeleted,
    Key? key,
  }) : super(key: ValueKey(view.id));

  @override
  State<DocumentPage> createState() => _DocumentPageState();
}

class _DocumentPageState extends State<DocumentPage> {
  late DocumentBloc documentBloc;
  final scrollController = ScrollController();
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
                widget.onDeleted();
                return const SizedBox();
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
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _renderEditor(controller),
              const VSpace(10),
              _renderToolbar(controller),
              const VSpace(10),
            ],
          ),
        ),
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

  Widget _renderEditor(quill.QuillController controller) {
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
      child: ScrollbarListStack(
        axis: Axis.vertical,
        controller: scrollController,
        barSize: 6.0,
        child: SizedBox.expand(child: editor),
      ),
    );
  }

  Widget _renderToolbar(quill.QuillController controller) {
    return ChangeNotifierProvider.value(
      value: Provider.of<AppearanceSetting>(context, listen: true),
      child: EditorToolbar.basic(
        controller: controller,
      ),
    );
  }
}
