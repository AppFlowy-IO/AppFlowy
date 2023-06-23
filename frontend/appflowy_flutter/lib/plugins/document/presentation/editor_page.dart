import 'package:appflowy/plugins/database_view/application/database_view_service.dart';
import 'package:appflowy/plugins/document/application/doc_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/option_action.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/block_action_list.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/insert_page_command.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/selectable_svg_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/database/referenced_database_menu_tem.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy_backend/log.dart' as log;
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pbserver.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pbenum.dart';
import 'package:appflowy_editor/src/render/selection_menu/selection_menu_icon.dart';
import 'package:highlight/languages/q.dart';

const kPageLinkAttributeKey = "kPageLink";

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
  late List<SelectionMenuItem> pageItems = [];
  final String kInLineReferenceNodeType = "inline_page_reference";
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
    referencedGridMenuItem,
    inlineBoardMenuItem(documentBloc),
    referencedBoardMenuItem,
    inlineCalendarMenuItem(documentBloc),
    referencedCalendarMenuItem,
    calloutItem,
    mathEquationItem,
    codeBlockItem,
    emojiMenuItem,
    autoGeneratorMenuItem,
  ];

  _customPageLinkMenu(
    List<SelectionMenuItem> items, {
    bool shouldInsertSlash = false,
    SelectionMenuStyle style = SelectionMenuStyle.light,
  }) {
    return CharacterShortcutEvent(
      key: 'show page link menu',
      character: '@',
      handler: (editorState) => _showPageSelectionMenu(
        editorState,
        [
          ...pageItems,
        ],
        shouldInsertSlash: shouldInsertSlash,
        style: style,
      ),
    );
  }

  SelectionMenuService? _selectionMenuService;
  Future<bool> _showPageSelectionMenu(
    EditorState editorState,
    List<SelectionMenuItem> items, {
    bool shouldInsertSlash = true,
    SelectionMenuStyle style = SelectionMenuStyle.light,
  }) async {
    if (PlatformExtension.isMobile) {
      return false;
    }

    final selection = editorState.selection;
    if (selection == null) {
      return false;
    }

    // delete the selection
    await editorState.deleteSelection(editorState.selection!);

    final afterSelection = editorState.selection;
    if (afterSelection == null || !afterSelection.isCollapsed) {
      assert(false, 'the selection should be collapsed');
      return true;
    }

    // insert the slash character
    // if (shouldInsertSlash) {
    await editorState.insertTextAtPosition('@', position: selection.start);
    // }

    // show the slash menu
    () {
      // this code is copied from the the old editor.
      // TODO: refactor this code
      final context = editorState.getNodeAtPath(selection.start.path)?.context;
      if (context != null) {
        _selectionMenuService = SelectionMenu(
          context: context,
          editorState: editorState,
          selectionMenuItems: items,
          deleteSlashByDefault: shouldInsertSlash,
          style: style,
        );
        _selectionMenuService?.show();
      }
    }();

    return true;
  }

  Future<List<SelectionMenuItem>> _generatePageItems() async {
    final List<SelectionMenuItem> pages = [];
    List<(ViewPB, List<ViewPB>)> pbViews = [];
    List<ViewPB> views = [];
    pbViews
        .addAll(await ViewBackendService().fetchViews(ViewLayoutPB.Document));
    pbViews.addAll(await ViewBackendService().fetchViews(ViewLayoutPB.Board));
    pbViews.addAll(await ViewBackendService().fetchViews(ViewLayoutPB.Grid));
    pbViews
        .addAll(await ViewBackendService().fetchViews(ViewLayoutPB.Calendar));

    if (pbViews.length > 0) {
      pbViews.forEach((element) {
        views.addAll(element.$2);
      });

      views.sort(((a, b) => a.createTime.compareTo(b.createTime)));

      for (int i = 0; i < views.length; i++) {
        final SelectionMenuItem pageSelectionMenuItem = SelectionMenuItem(
          icon: (editorState, isSelected, style) => SelectableSvgWidget(
            name: 'editor/${_getIconName(views[i])}',
            isSelected: isSelected,
            style: style,
          ),
          keywords: [
            views[i].name.toString(),
          ],
          name: views[i].name.toString(),
          handler: (editorState, menuService, context) async {
            // final _delta = Delta()
            //   ..insert(
            //     '\$',
            //     attributes: {
            //       'mention': {'id': views[i].id, 'handler': views[i].name},
            //     },
            //   );

            final selection = editorState.selection;
            if (selection == null || !selection.isCollapsed) {
              return;
            } else {
              final node = editorState.getNodeAtPath(selection.end.path);
              if (node == null) {
                return;
              } else {
                final index = selection.endIndex;
                final transaction = editorState.transaction
                  ..insertText(node, index, "\$", attributes: {
                    "mention": {
                      "id": views[i].id,
                      "handler": views[i].name,
                    }
                  });
                await editorState.apply(transaction);
              }
            }

            // final startOffset = editorState
            //     .selectionService.currentSelection.value!.normalized.end.offset;
            // await editorState.insertTextAtCurrentSelection(views[i].name);
            // final path = widget
            //     .editorState.selectionService.currentSelection.value!.end.path;
            // final selection = Selection(
            //   start: Position(path: path, offset: startOffset - 1),
            //   end: Position(
            //       path: path, offset: startOffset + views[i].name.length + 1),
            // );
            // await editorState.formatDelta(selection, _delta.last.attributes!);
            // final transaction = editorState.transaction;
            // transaction.insertNode(
            //     editorState.document.last!.path, paragraphNode(delta: _delta));

            // await editorState.apply(transaction);
            // await editorState.formatDelta(selection, {
            //   "mention": {"id": views[i].id, "handler": views[i].name},
            // });
            // print("DOCUMENT AFTER: ${editorState.document.toJson()}");
            // await editorState.updateSelectionWithReason(selection,
            //     reason: SelectionUpdateReason.transaction);
          },
        );
        pages.add(pageSelectionMenuItem);
      }
    }

    return pages;
  }

  _getIconName(ViewPB view) {
    if (view.layout == ViewLayoutPB.Document) {
      return "documents";
    }
    if (view.layout == ViewLayoutPB.Board) {
      return "board";
    }
    if (view.layout == ViewLayoutPB.Calendar) {
      return "board";
    }
    return "grid";
  }

  late final Map<String, BlockComponentBuilder> blockComponentBuilders =
      _customAppFlowyBlockComponentBuilders();
  List<CharacterShortcutEvent> get characterShortcutEvents => [
        // inline link command
        _customPageLinkMenu(
          pageItems,
          style: styleCustomizer.selectionMenuStyleBuilder(),
        ),

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

  EditorStyleCustomizer get styleCustomizer => widget.styleCustomizer;
  DocumentBloc get documentBloc => context.read<DocumentBloc>();

  @override
  void initState() {
    super.initState();
    effectiveScrollController = widget.scrollController ?? ScrollController();

    _generatePageItems().then((value) {
      pageItems = value;
    });
    widget.editorState.selectionNotifier.addListener(() {
      try {
        print(
            "START ${widget.editorState.selectionService.currentSelection.value!.normalized.start.offset} || END ${widget.editorState.selectionService.currentSelection.value!.normalized.end.offset}");
      } catch (e) {}
    });
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      effectiveScrollController.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (bool autoFocus, Selection? selection) =
        _computeAutoFocusParameters();

    final editor = AppFlowyEditor.custom(
      editorState: widget.editorState,
      editable: true,
      shrinkWrap: widget.shrinkWrap,
      scrollController: effectiveScrollController,
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
          scrollController: effectiveScrollController,
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
      DatabaseBlockKeys.gridType: DatabaseViewBlockComponentBuilder(
        configuration: configuration,
      ),
      DatabaseBlockKeys.boardType: DatabaseViewBlockComponentBuilder(
        configuration: configuration,
      ),
      DatabaseBlockKeys.calendarType: DatabaseViewBlockComponentBuilder(
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
