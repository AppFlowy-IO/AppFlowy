import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/doc/doc_bloc.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_scroll_bar.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace-infra/view_create.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:styled_widget/styled_widget.dart';
import 'styles.dart';
import 'widget/banner.dart';
import 'widget/toolbar/tool_bar.dart';

class DocPage extends StatefulWidget {
  final View view;

  DocPage({Key? key, required this.view}) : super(key: ValueKey(view.id));

  @override
  State<DocPage> createState() => _DocPageState();
}

class _DocPageState extends State<DocPage> {
  late DocBloc docBloc;
  final scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    docBloc = getIt<DocBloc>(param1: super.widget.view)..add(const DocEvent.initial());
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
          // loading: (_) => const FlowyProgressIndicator(),
          loading: (_) => SizedBox.expand(child: Container(color: Colors.white)),
          finish: (result) => result.successOrFail.fold(
            (_) {
              if (state.forceClose) {
                return _renderAppPage();
              } else {
                return _renderDoc(context, state);
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
    docBloc.close();
    super.dispose();
  }

  Widget _renderDoc(BuildContext context, DocState state) {
    quill.QuillController controller = quill.QuillController(
      document: context.read<DocBloc>().document,
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
          ).padding(horizontal: 40, top: 28),
        ),
      ],
    );
  }

  Widget _renderBanner(BuildContext context) {
    return DocBanner(
      onRestore: () => context.read<DocBloc>().add(const DocEvent.restorePage()),
      onDelete: () => context.read<DocBloc>().add(const DocEvent.deletePermanently()),
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
    return EditorToolbar.basic(
      controller: controller,
    );
  }

  Widget _renderAppPage() {
    return Container(
      color: Colors.black,
    );
  }
}
