import 'package:app_flowy/plugins/document/presentation/plugins/board/board_menu_item.dart';
import 'package:app_flowy/plugins/document/presentation/plugins/board/board_node_widget.dart';
import 'package:app_flowy/plugins/document/presentation/plugins/grid/grid_menu_item.dart';
import 'package:app_flowy/plugins/document/presentation/plugins/grid/grid_node_widget.dart';
import 'package:app_flowy/plugins/document/presentation/plugins/openai/widgets/auto_completion_node_widget.dart';
import 'package:app_flowy/plugins/document/presentation/plugins/openai/widgets/auto_completion_plugins.dart';
import 'package:app_flowy/plugins/document/presentation/plugins/openai/widgets/smart_edit_node_widget.dart';
import 'package:app_flowy/plugins/document/presentation/plugins/openai/widgets/smart_edit_toolbar_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  Future<void> dispose() async {
    // https://github.com/flutter/flutter/issues/64935#issuecomment-686852369
    super.dispose();

    await _clearTemporaryNodes();
    await documentBloc.close();
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
          loading: (_) => SizedBox.expand(
            child: Container(color: Colors.transparent),
          ),
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

  Widget _renderDocument(BuildContext context, DocumentState state) {
    return Column(
      children: [
        if (state.isDeleted) _renderBanner(context),
        // AppFlowy Editor
        _renderAppFlowyEditor(
          context,
          context.read<DocumentBloc>().editorState,
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

  Widget _renderAppFlowyEditor(BuildContext context, EditorState editorState) {
    // enable open ai features if needed.
    final userProfilePB = context.read<DocumentBloc>().state.userProfilePB;
    final openAIKey = userProfilePB?.openaiKey;

    final theme = Theme.of(context);
    final editor = AppFlowyEditor(
      editorState: editorState,
      autoFocus: editorState.document.isEmpty,
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
        // Grid
        gridMenuItem,
        // Callout
        calloutMenuItem,
        // AI
        if (openAIKey != null && openAIKey.isNotEmpty) ...[
          autoGeneratorMenuItem,
        ]
      ],
      toolbarItems: [
        smartEditItem,
      ],
      themeData: theme.copyWith(extensions: [
        ...theme.extensions.values,
        customEditorTheme(context),
        ...customPluginTheme(context),
      ]),
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

  Future<void> _clearTemporaryNodes() async {
    final editorState = documentBloc.editorState;
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
}
