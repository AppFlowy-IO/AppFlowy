import 'package:appflowy/plugins/document/presentation/plugins/plugins.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../startup/startup.dart';
import 'application/doc_bloc.dart';
import 'editor_styles.dart';
import 'presentation/banner.dart';

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

  @override
  void initState() {
    // The appflowy editor use Intl as localization, set the default language as fallback.
    Intl.defaultLocale = 'en_US';
    documentBloc = getIt<DocumentBloc>(param1: super.widget.view)
      ..add(const DocumentEvent.initial());
    super.initState();
  }

  @override
  void dispose() {
    documentBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<DocumentBloc>.value(value: documentBloc),
      ],
      child: BlocBuilder<DocumentBloc, DocumentState>(
        builder: (context, state) {
          return state.loadingState.map(
            loading: (_) => SizedBox.expand(
              child: Container(color: Colors.transparent),
            ),
            finish: (result) => result.successOrFail.fold(
              (_) {
                if (state.forceClose) {
                  widget.onDeleted();
                  return const SizedBox();
                } else if (documentBloc.editorState == null) {
                  return const SizedBox();
                } else {
                  return _renderDocument(context, state);
                }
              },
              (err) => FlowyErrorPage(err.toString()),
            ),
          );
        },
      ),
    );
  }

  Widget _renderDocument(BuildContext context, DocumentState state) {
    return Column(
      children: [
        if (state.isDeleted) _renderBanner(context),
        // AppFlowy Editor
        const _AppFlowyEditorPage(),
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
}

class _AppFlowyEditorPage extends StatefulWidget {
  const _AppFlowyEditorPage({
    Key? key,
  }) : super(key: key);

  @override
  State<_AppFlowyEditorPage> createState() => _AppFlowyEditorPageState();
}

class _AppFlowyEditorPageState extends State<_AppFlowyEditorPage> {
  late DocumentBloc documentBloc;
  late EditorState editorState;
  String? get openAIKey => documentBloc.state.userProfilePB?.openaiKey;

  @override
  void initState() {
    super.initState();
    documentBloc = context.read<DocumentBloc>();
    editorState = documentBloc.editorState ?? EditorState.empty();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final autoFocusParameters = _autoFocusParameters();
    final editor = AppFlowyEditor(
      editorState: editorState,
      autoFocus: autoFocusParameters.value1,
      focusedSelection: autoFocusParameters.value2,
      customBuilders: {
        // Divider
        kDividerType: DividerWidgetBuilder(),
        // Math Equation
        kMathEquationType: MathEquationNodeWidgetBuidler(),
        // Code Block
        kCodeBlockType: CodeBlockNodeWidgetBuilder(),
        // Board
        kBoardType: BoardNodeWidgetBuilder(),
        // Grid
        kGridType: GridNodeWidgetBuilder(),
        // Card
        kCalloutType: CalloutNodeWidgetBuilder(),
        // Auto Generator,
        kAutoCompletionInputType: AutoCompletionInputBuilder(),
        // Cover
        kCoverType: CoverNodeWidgetBuilder(),
        // Smart Edit,
        kSmartEditType: SmartEditInputBuilder(),
      },
      shortcutEvents: [
        // Divider
        insertDividerEvent,
        // Code Block
        enterInCodeBlock,
        ignoreKeysInCodeBlock,
        pasteInCodeBlock,
      ],
      selectionMenuItems: [
        // Divider
        dividerMenuItem,
        // Math Equation
        mathEquationMenuItem,
        // Code Block
        codeBlockMenuItem,
        // Emoji
        emojiMenuItem,
        // Board
        boardMenuItem,
        // Create Board
        boardViewMenuItem(documentBloc),
        // Grid
        gridMenuItem,
        // Create Grid
        gridViewMenuItem(documentBloc),
        // Callout
        calloutMenuItem,
        // AI
        // enable open ai features if needed.
        if (openAIKey != null && openAIKey!.isNotEmpty) ...[
          autoGeneratorMenuItem,
        ],
      ],
      toolbarItems: [
        smartEditItem,
      ],
      themeData: theme.copyWith(
        extensions: [
          ...theme.extensions.values,
          customEditorTheme(context),
          ...customPluginTheme(context),
        ],
      ),
    );
    return Expanded(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: double.infinity,
          ),
          child: editor,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _clearTemporaryNodes();
    super.dispose();
  }

  Future<void> _clearTemporaryNodes() async {
    final document = editorState.document;
    if (document.root.children.isEmpty) {
      return;
    }
    final temporaryNodeTypes = [
      kAutoCompletionInputType,
      kSmartEditType,
    ];
    final iterator = NodeIterator(
      document: document,
      startNode: document.root.children.first,
    );
    final transaction = editorState.transaction;
    while (iterator.moveNext()) {
      final node = iterator.current;
      if (temporaryNodeTypes.contains(node.type)) {
        transaction.deleteNode(node);
      }
    }
    if (transaction.operations.isNotEmpty) {
      await editorState.apply(transaction, withUpdateCursor: false);
    }
  }

  dartz.Tuple2<bool, Selection?> _autoFocusParameters() {
    if (editorState.document.isEmpty) {
      return dartz.Tuple2(true, Selection.single(path: [0], startOffset: 0));
    }
    final texts = editorState.document.root.children.whereType<TextNode>();
    if (texts.every((element) => element.toPlainText().isEmpty)) {
      return dartz.Tuple2(
        true,
        Selection.single(path: texts.first.path, startOffset: 0),
      );
    }
    return const dartz.Tuple2(false, null);
  }
}
