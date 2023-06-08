import 'package:appflowy/plugins/document/application/doc_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/option_action.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/block_action_list.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Wrapper for the appflowy editor.
class AppFlowyEditorPage extends StatefulWidget {
  const AppFlowyEditorPage({
    super.key,
    required this.editorState,
    this.header,
  });

  final EditorState editorState;
  final Widget? header;

  @override
  State<AppFlowyEditorPage> createState() => _AppFlowyEditorPageState();
}

class _AppFlowyEditorPageState extends State<AppFlowyEditorPage> {
  final scrollController = ScrollController();

  final List<CommandShortcutEvent> commandShortcutEvents = [
    ...codeBlockCommands,
    ...standardCommandShortcutEvents,
  ];

  final List<ToolbarItem> toolbarItems = [
    smartEditItem,
    paragraphItem,
    ...headingItems,
    ...markdownFormatItems,
    quoteItem,
    bulletedListItem,
    numberedListItem,
    linkItem,
    textColorItem,
    highlightColorItem,
  ];

  late final slashMenuItems = [
    inlineGridMenuItem(documentBloc),
    referenceGridMenuItem,
    inlineBoardMenuItem(documentBloc),
    boardMenuItem,
    calloutItem,
    mathEquationItem,
    codeBlockItem,
    emojiMenuItem,
    autoGeneratorMenuItem,
  ];

  late final Map<String, BlockComponentBuilder> blockComponentBuilders =
      _customAppFlowyBlockComponentBuilders();
  List<CharacterShortcutEvent> get characterShortcutEvents => [
        // code block
        ...codeBlockCharacterEvents,

        // toggle list
        // formatGreaterToToggleList,

        // customize the slash menu command
        customSlashCommand(
          slashMenuItems,
          style: styleCustomizer.selectionMenuStyleBuilder(),
        ),

        ...standardCharacterShortcutEvents
          ..removeWhere(
            (element) => element == slashCommand,
          ), // remove the default slash command.
      ];

  late final showSlashMenu = customSlashCommand(
    slashMenuItems,
    shouldInsertSlash: false,
    style: styleCustomizer.selectionMenuStyleBuilder(),
  ).handler;

  EditorStyleCustomizer get styleCustomizer => EditorStyleCustomizer(
        context: context,
      );
  DocumentBloc get documentBloc => context.read<DocumentBloc>();

  @override
  Widget build(BuildContext context) {
    final (bool autoFocus, Selection? selection) =
        _computeAutoFocusParameters();

    final editor = AppFlowyEditor.custom(
      editorState: widget.editorState,
      editable: true,
      scrollController: scrollController,
      // setup the auto focus parameters
      autoFocus: autoFocus,
      focusedSelection: selection,
      // setup the theme
      editorStyle: styleCustomizer.style(),
      // customize the block builder
      blockComponentBuilders: blockComponentBuilders,
      // customize the shortcuts
      characterShortcutEvents: characterShortcutEvents,
      commandShortcutEvents: commandShortcutEvents,
      header: widget.header,
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: double.infinity,
          maxHeight: double.infinity,
        ),
        child: FloatingToolbar(
          style: styleCustomizer.floatingToolbarStyleBuilder(),
          items: toolbarItems,
          editorState: widget.editorState,
          scrollController: scrollController,
          child: editor,
        ),
      ),
    );
  }

  Map<String, BlockComponentBuilder> _customAppFlowyBlockComponentBuilders() {
    final standardActions = [
      OptionAction.delete,
      OptionAction.duplicate,
      // OptionAction.divider,
      // OptionAction.moveUp,
      // OptionAction.moveDown,
    ];

    final configuration = BlockComponentConfiguration(
      padding: (_) => const EdgeInsets.symmetric(vertical: 4.0),
    );
    final customBlockComponentBuilderMap = {
      PageBlockKeys.type: PageBlockComponentBuilder(),
      ParagraphBlockKeys.type: TextBlockComponentBuilder(
        configuration: configuration,
      ),
      TodoListBlockKeys.type: TodoListBlockComponentBuilder(
        configuration: configuration.copyWith(
          placeholderText: (_) => 'To-do',
        ),
      ),
      BulletedListBlockKeys.type: BulletedListBlockComponentBuilder(
        configuration: configuration.copyWith(
          placeholderText: (_) => 'List',
        ),
      ),
      NumberedListBlockKeys.type: NumberedListBlockComponentBuilder(
        configuration: configuration.copyWith(
          placeholderText: (_) => 'List',
        ),
      ),
      QuoteBlockKeys.type: QuoteBlockComponentBuilder(
        configuration: configuration.copyWith(
          placeholderText: (_) => 'Quote',
        ),
      ),
      HeadingBlockKeys.type: HeadingBlockComponentBuilder(
        configuration: configuration.copyWith(
          padding: (_) => const EdgeInsets.only(top: 12.0, bottom: 4.0),
          placeholderText: (node) =>
              'Heading ${node.attributes[HeadingBlockKeys.level]}',
        ),
        textStyleBuilder: (level) => styleCustomizer.headingStyleBuilder(level),
      ),
      ImageBlockKeys.type: ImageBlockComponentBuilder(
        configuration: configuration,
      ),
      BoardBlockKeys.type: BoardBlockComponentBuilder(
        configuration: configuration,
      ),
      GridBlockKeys.type: GridBlockComponentBuilder(
        configuration: configuration,
      ),
      CalloutBlockKeys.type: CalloutBlockComponentBuilder(
        configuration: configuration,
      ),
      DividerBlockKeys.type: DividerBlockComponentBuilder(),
      MathEquationBlockKeys.type: MathEquationBlockComponentBuilder(
        configuration: configuration.copyWith(
          padding: (_) => const EdgeInsets.symmetric(vertical: 20),
        ),
      ),
      CodeBlockKeys.type: CodeBlockComponentBuilder(
        configuration: configuration.copyWith(
          textStyle: (_) => styleCustomizer.codeBlockStyleBuilder(),
          placeholderTextStyle: (_) => styleCustomizer.codeBlockStyleBuilder(),
        ),
        padding: const EdgeInsets.only(
          left: 30,
          right: 30,
          bottom: 36,
        ),
      ),
      AutoCompletionBlockKeys.type: AutoCompletionBlockComponentBuilder(),
      SmartEditBlockKeys.type: SmartEditBlockComponentBuilder(),
      ToggleListBlockKeys.type: ToggleListBlockComponentBuilder(),
    };

    final builders = {
      ...standardBlockComponentBuilderMap,
      ...customBlockComponentBuilderMap,
    };

    // customize the action builder. actually, we can customize them in their own builder. Put them here just for convenience.
    for (final entry in builders.entries) {
      if (entry.key == PageBlockKeys.type) {
        continue;
      }
      final builder = entry.value;

      // customize the action builder.
      final supportColorBuilderTypes = [
        ParagraphBlockKeys.type,
        HeadingBlockKeys.type,
        BulletedListBlockKeys.type,
        NumberedListBlockKeys.type,
        QuoteBlockKeys.type,
        TodoListBlockKeys.type,
        CalloutBlockKeys.type
      ];

      final supportAlignBuilderType = [
        ImageBlockKeys.type,
      ];

      final colorAction = [
        OptionAction.divider,
        OptionAction.color,
      ];

      final alignAction = [
        OptionAction.divider,
        OptionAction.align,
      ];

      final List<OptionAction> actions = [
        ...standardActions,
        if (supportColorBuilderTypes.contains(entry.key)) ...colorAction,
        if (supportAlignBuilderType.contains(entry.key)) ...alignAction,
      ];

      builder.showActions = (_) => true;
      builder.actionBuilder = (context, state) => BlockActionList(
            blockComponentContext: context,
            blockComponentState: state,
            editorState: widget.editorState,
            actions: actions,
            showSlashMenu: () => showSlashMenu(
              widget.editorState,
            ),
          );
    }

    return builders;
  }

  (bool, Selection?) _computeAutoFocusParameters() {
    if (widget.editorState.document.isEmpty) {
      return (true, Selection.collapse([0], 0));
    }
    final nodes = widget.editorState.document.root.children
        .where((element) => element.delta != null);
    final isAllEmpty =
        nodes.isNotEmpty && nodes.every((element) => element.delta!.isEmpty);
    if (isAllEmpty) {
      return (true, Selection.collapse(nodes.first.path, 0));
    }
    return const (false, null);
  }
}
