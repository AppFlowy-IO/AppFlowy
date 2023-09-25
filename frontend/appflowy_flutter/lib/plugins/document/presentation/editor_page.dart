import 'package:appflowy/plugins/document/application/doc_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy/plugins/inline_actions/handlers/date_reference.dart';
import 'package:appflowy/plugins/inline_actions/handlers/reminder_reference.dart';
import 'package:appflowy/workspace/application/appearance.dart';
import 'package:appflowy/workspace/application/settings/shortcuts/settings_shortcuts_service.dart';
import 'package:appflowy/plugins/inline_actions/handlers/inline_page_reference.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_command.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_service.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:collection/collection.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final List<CommandShortcutEvent> commandShortcutEvents = [
  toggleToggleListCommand,
  ...codeBlockCommands,
  ...standardCommandShortcutEvents,
];

/// Wrapper for the appflowy editor.
class AppFlowyEditorPage extends StatefulWidget {
  const AppFlowyEditorPage({
    super.key,
    required this.editorState,
    this.header,
    this.shrinkWrap = false,
    this.scrollController,
    this.autoFocus,
    required this.styleCustomizer,
  });

  final Widget? header;
  final EditorState editorState;
  final ScrollController? scrollController;
  final bool shrinkWrap;
  final bool? autoFocus;
  final EditorStyleCustomizer styleCustomizer;

  @override
  State<AppFlowyEditorPage> createState() => _AppFlowyEditorPageState();
}

class _AppFlowyEditorPageState extends State<AppFlowyEditorPage> {
  late final ScrollController effectiveScrollController;

  late final InlineActionsService inlineActionsService = InlineActionsService(
    context: context,
    handlers: [
      InlinePageReferenceService().inlinePageReferenceDelegate,
      DateReferenceService(context).dateReferenceDelegate,
      ReminderReferenceService(context).reminderReferenceDelegate,
    ],
  );

  final List<ToolbarItem> toolbarItems = [
    smartEditItem..isActive = onlyShowInSingleTextTypeSelectionAndExcludeTable,
    paragraphItem..isActive = onlyShowInSingleTextTypeSelectionAndExcludeTable,
    ...(headingItems
      ..forEach(
        (e) => e.isActive = onlyShowInSingleSelectionAndTextType,
      )),
    ...markdownFormatItems,
    quoteItem..isActive = onlyShowInSingleTextTypeSelectionAndExcludeTable,
    bulletedListItem
      ..isActive = onlyShowInSingleTextTypeSelectionAndExcludeTable,
    numberedListItem
      ..isActive = onlyShowInSingleTextTypeSelectionAndExcludeTable,
    inlineMathEquationItem,
    linkItem,
    alignToolbarItem,
    buildTextColorItem(),
    buildHighlightColorItem(),
    customizeFontToolbarItem,
  ];

  late final List<SelectionMenuItem> slashMenuItems;

  late final Map<String, BlockComponentBuilder> blockComponentBuilders =
      _customAppFlowyBlockComponentBuilders();

  List<CharacterShortcutEvent> get characterShortcutEvents => [
        // code block
        ...codeBlockCharacterEvents,

        // toggle list
        formatGreaterToToggleList,
        insertChildNodeInsideToggleList,

        // customize the slash menu command
        customSlashCommand(
          slashMenuItems,
          style: styleCustomizer.selectionMenuStyleBuilder(),
        ),

        ...standardCharacterShortcutEvents
          ..removeWhere(
            (element) => element == slashCommand,
          ), // remove the default slash command.

        /// Inline Actions
        /// - Reminder
        /// - Inline-page reference
        inlineActionsCommand(
          inlineActionsService,
          style: styleCustomizer.inlineActionsMenuStyleBuilder(),
        ),
      ];

  late final showSlashMenu = customSlashCommand(
    slashMenuItems,
    shouldInsertSlash: false,
    style: styleCustomizer.selectionMenuStyleBuilder(),
  ).handler;

  EditorStyleCustomizer get styleCustomizer => widget.styleCustomizer;
  DocumentBloc get documentBloc => context.read<DocumentBloc>();

  @override
  void initState() {
    super.initState();

    _initializeShortcuts();
    indentableBlockTypes.add(ToggleListBlockKeys.type);
    convertibleBlockTypes.add(ToggleListBlockKeys.type);
    slashMenuItems = _customSlashMenuItems();
    effectiveScrollController = widget.scrollController ?? ScrollController();

    // keep the previous font style when typing new text.
    AppFlowyRichTextKeys.supportSliced.add(AppFlowyRichTextKeys.fontFamily);
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      effectiveScrollController.dispose();
    }
    inlineActionsService.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (bool autoFocus, Selection? selection) =
        _computeAutoFocusParameters();

    final isRTL =
        context.read<AppearanceSettingsCubit>().state.layoutDirection ==
            LayoutDirection.rtlLayout;
    final layoutDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;

    _setRTLToolbarItems(isRTL);

    final editorScrollController = EditorScrollController(
      editorState: widget.editorState,
      shrinkWrap: widget.shrinkWrap,
      scrollController: effectiveScrollController,
    );

    final editor = AppFlowyEditor(
      editorState: widget.editorState,
      editable: true,
      editorScrollController: editorScrollController,
      // setup the auto focus parameters
      autoFocus: widget.autoFocus ?? autoFocus,
      focusedSelection: selection,
      // setup the theme
      editorStyle: styleCustomizer.style(),
      // customize the block builder
      blockComponentBuilders: blockComponentBuilders,
      // customize the shortcuts
      characterShortcutEvents: characterShortcutEvents,
      commandShortcutEvents: commandShortcutEvents,
      contextMenuItems: customContextMenuItems,
      header: widget.header,
      footer: const VSpace(200),
    );

    return Center(
      child: FloatingToolbar(
        style: styleCustomizer.floatingToolbarStyleBuilder(),
        items: toolbarItems,
        editorState: widget.editorState,
        editorScrollController: editorScrollController,
        child: Directionality(
          textDirection: layoutDirection,
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

    final calloutBGColor = AFThemeExtension.of(context).calloutBGColor;

    final configuration = BlockComponentConfiguration(
      padding: (_) => const EdgeInsets.symmetric(vertical: 5.0),
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
        showMenu: true,
        menuBuilder: (node, state) => Positioned(
          top: 0,
          right: 10,
          child: ImageMenu(
            node: node,
            state: state,
          ),
        ),
      ),
      TableBlockKeys.type: TableBlockComponentBuilder(
        menuBuilder: (node, editorState, position, dir, onBuild, onClose) =>
            TableMenu(
          node: node,
          editorState: editorState,
          position: position,
          dir: dir,
          onBuild: onBuild,
          onClose: onClose,
        ),
      ),
      TableCellBlockKeys.type: TableCellBlockComponentBuilder(
        menuBuilder: (node, editorState, position, dir, onBuild, onClose) =>
            TableMenu(
          node: node,
          editorState: editorState,
          position: position,
          dir: dir,
          onBuild: onBuild,
          onClose: onClose,
        ),
      ),
      DatabaseBlockKeys.gridType: DatabaseViewBlockComponentBuilder(
        configuration: configuration.copyWith(
          padding: (_) => const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
      DatabaseBlockKeys.boardType: DatabaseViewBlockComponentBuilder(
        configuration: configuration.copyWith(
          padding: (_) => const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
      DatabaseBlockKeys.calendarType: DatabaseViewBlockComponentBuilder(
        configuration: configuration.copyWith(
          padding: (_) => const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
      CalloutBlockKeys.type: CalloutBlockComponentBuilder(
        configuration: configuration,
        defaultColor: calloutBGColor,
      ),
      DividerBlockKeys.type: DividerBlockComponentBuilder(
        configuration: configuration,
        height: 28.0,
      ),
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
      ToggleListBlockKeys.type: ToggleListBlockComponentBuilder(
        configuration: configuration,
      ),
      OutlineBlockKeys.type: OutlineBlockComponentBuilder(
        configuration: configuration.copyWith(
          placeholderTextStyle: (_) =>
              styleCustomizer.outlineBlockPlaceholderStyleBuilder(),
        ),
      ),
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
        CalloutBlockKeys.type,
        OutlineBlockKeys.type,
        ToggleListBlockKeys.type,
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

      builder.showActions =
          (node) => node.parent?.type != TableCellBlockKeys.type;
      builder.actionBuilder = (context, state) {
        final top = builder.configuration.padding(context.node).top;
        final padding = context.node.type == HeadingBlockKeys.type
            ? EdgeInsets.only(top: top + 8.0)
            : EdgeInsets.only(top: top + 2.0);
        return Padding(
          padding: padding,
          child: BlockActionList(
            blockComponentContext: context,
            blockComponentState: state,
            editorState: widget.editorState,
            actions: actions,
            showSlashMenu: () => showSlashMenu(widget.editorState),
          ),
        );
      };
    }

    return builders;
  }

  List<SelectionMenuItem> _customSlashMenuItems() {
    final items = [...standardSelectionMenuItems];
    final imageItem = items.firstWhereOrNull(
      (element) => element.name == AppFlowyEditorLocalizations.current.image,
    );
    if (imageItem != null) {
      final imageItemIndex = items.indexOf(imageItem);
      if (imageItemIndex != -1) {
        items[imageItemIndex] = customImageMenuItem;
      }
    }
    return [
      ...items,
      inlineGridMenuItem(documentBloc),
      referencedGridMenuItem,
      inlineBoardMenuItem(documentBloc),
      referencedBoardMenuItem,
      inlineCalendarMenuItem(documentBloc),
      referencedCalendarMenuItem,
      calloutItem,
      outlineItem,
      mathEquationItem,
      codeBlockItem,
      toggleListBlockItem,
      emojiMenuItem,
      autoGeneratorMenuItem,
    ];
  }

  (bool, Selection?) _computeAutoFocusParameters() {
    if (widget.editorState.document.isEmpty) {
      return (
        true,
        Selection.collapsed(
          Position(path: [0], offset: 0),
        ),
      );
    }
    final nodes = widget.editorState.document.root.children
        .where((element) => element.delta != null);
    final isAllEmpty =
        nodes.isNotEmpty && nodes.every((element) => element.delta!.isEmpty);
    if (isAllEmpty) {
      return (
        true,
        Selection.collapsed(
          Position(path: nodes.first.path, offset: 0),
        )
      );
    }
    return const (false, null);
  }

  Future<void> _initializeShortcuts() async {
    final settingsShortcutService = SettingsShortcutService();
    final customizeShortcuts =
        await settingsShortcutService.getCustomizeShortcuts();
    await settingsShortcutService.updateCommandShortcuts(
      standardCommandShortcutEvents,
      customizeShortcuts,
    );
  }

  void _setRTLToolbarItems(bool isRTL) {
    final textDirectionItemIds = textDirectionItems.map((e) => e.id);
    // clear all the text direction items
    toolbarItems.removeWhere(
      (item) => textDirectionItemIds.contains(item.id),
    );
    // only show the rtl item when the layout direction is ltr.
    if (isRTL) {
      toolbarItems.addAll(textDirectionItems);
    }
  }
}
