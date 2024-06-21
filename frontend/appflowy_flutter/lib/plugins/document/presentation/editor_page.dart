import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_configuration.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/align_toolbar_item/custom_text_align_command.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/background_color/theme_background_color.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/format_arrow_character.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/page_reference_commands.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/callout/callout_block_shortcuts.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/i18n/editor_i18n.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/slash_menu_items.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy/plugins/inline_actions/handlers/date_reference.dart';
import 'package:appflowy/plugins/inline_actions/handlers/inline_page_reference.dart';
import 'package:appflowy/plugins/inline_actions/handlers/reminder_reference.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_command.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_service.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/application/settings/shortcuts/settings_shortcuts_service.dart';
import 'package:appflowy/workspace/application/view_info/view_info_bloc.dart';
import 'package:appflowy/workspace/presentation/home/af_focus_manager.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/emoji_picker/emoji_picker.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final codeBlockLocalization = CodeBlockLocalizations(
  codeBlockNewParagraph:
      LocaleKeys.settings_shortcutsPage_commands_codeBlockNewParagraph.tr(),
  codeBlockIndentLines:
      LocaleKeys.settings_shortcutsPage_commands_codeBlockIndentLines.tr(),
  codeBlockOutdentLines:
      LocaleKeys.settings_shortcutsPage_commands_codeBlockOutdentLines.tr(),
  codeBlockSelectAll:
      LocaleKeys.settings_shortcutsPage_commands_codeBlockSelectAll.tr(),
  codeBlockPasteText:
      LocaleKeys.settings_shortcutsPage_commands_codeBlockPasteText.tr(),
  codeBlockAddTwoSpaces:
      LocaleKeys.settings_shortcutsPage_commands_codeBlockAddTwoSpaces.tr(),
);

final localizedCodeBlockCommands =
    codeBlockCommands(localizations: codeBlockLocalization);

final List<CommandShortcutEvent> commandShortcutEvents = [
  toggleToggleListCommand,
  ...localizedCodeBlockCommands,
  customCopyCommand,
  customPasteCommand,
  customCutCommand,
  ...customTextAlignCommands,

  // remove standard shortcuts for copy, cut, paste, todo
  ...standardCommandShortcutEvents
    ..removeWhere(
      (shortcut) => [
        copyCommand,
        cutCommand,
        pasteCommand,
        toggleTodoListCommand,
      ].contains(shortcut),
    ),

  emojiShortcutEvent,
];

final List<CommandShortcutEvent> defaultCommandShortcutEvents = [
  ...commandShortcutEvents.map((e) => e.copyWith()),
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
    this.showParagraphPlaceholder,
    this.placeholderText,
    this.initialSelection,
    this.useViewInfoBloc = true,
  });

  final Widget? header;
  final EditorState editorState;
  final ScrollController? scrollController;
  final bool shrinkWrap;
  final bool? autoFocus;
  final EditorStyleCustomizer styleCustomizer;
  final ShowPlaceholder? showParagraphPlaceholder;
  final String Function(Node)? placeholderText;

  /// Used to provide an initial selection on Page-load
  final Selection? initialSelection;

  final bool useViewInfoBloc;

  @override
  State<AppFlowyEditorPage> createState() => _AppFlowyEditorPageState();
}

class _AppFlowyEditorPageState extends State<AppFlowyEditorPage> {
  late final ScrollController effectiveScrollController;

  late final InlineActionsService inlineActionsService = InlineActionsService(
    context: context,
    handlers: [
      InlinePageReferenceService(currentViewId: documentBloc.documentId),
      DateReferenceService(context),
      ReminderReferenceService(context),
    ],
  );

  late final List<CommandShortcutEvent> cmdShortcutEvents = [
    ...commandShortcutEvents,
    ..._buildFindAndReplaceCommands(),
  ];

  final List<ToolbarItem> toolbarItems = [
    smartEditItem..isActive = onlyShowInSingleTextTypeSelectionAndExcludeTable,
    paragraphItem..isActive = onlyShowInSingleTextTypeSelectionAndExcludeTable,
    ...headingItems
      ..forEach((e) => e.isActive = onlyShowInSingleSelectionAndTextType),
    ...markdownFormatItems..forEach((e) => e.isActive = showInAnyTextType),
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

  List<CharacterShortcutEvent> get characterShortcutEvents => [
        // code block
        ...codeBlockCharacterEvents,

        // callout block
        insertNewLineInCalloutBlock,

        // toggle list
        formatGreaterToToggleList,
        insertChildNodeInsideToggleList,

        // customize the slash menu command
        customSlashCommand(
          slashMenuItems,
          style: styleCustomizer.selectionMenuStyleBuilder(),
        ),

        customFormatGreaterEqual,

        ...standardCharacterShortcutEvents
          ..removeWhere(
            (shortcut) => [
              slashCommand, // Remove default slash command
              formatGreaterEqual, // Overridden by customFormatGreaterEqual
            ].contains(shortcut),
          ),

        /// Inline Actions
        /// - Reminder
        /// - Inline-page reference
        inlineActionsCommand(
          inlineActionsService,
          style: styleCustomizer.inlineActionsMenuStyleBuilder(),
        ),

        /// Inline page menu
        /// - Using `[[`
        pageReferenceShortcutBrackets(
          context,
          documentBloc.documentId,
          styleCustomizer.inlineActionsMenuStyleBuilder(),
        ),

        /// - Using `+`
        pageReferenceShortcutPlusSign(
          context,
          documentBloc.documentId,
          styleCustomizer.inlineActionsMenuStyleBuilder(),
        ),
      ];

  EditorStyleCustomizer get styleCustomizer => widget.styleCustomizer;
  DocumentBloc get documentBloc => context.read<DocumentBloc>();

  late final EditorScrollController editorScrollController;

  late final ViewInfoBloc viewInfoBloc = context.read<ViewInfoBloc>();

  Future<bool> showSlashMenu(editorState) async => customSlashCommand(
        slashMenuItems,
        shouldInsertSlash: false,
        style: styleCustomizer.selectionMenuStyleBuilder(),
      ).handler(editorState);

  AFFocusManager? focusManager;

  void _loseFocus() => widget.editorState.selection = null;

  @override
  void initState() {
    super.initState();

    if (widget.useViewInfoBloc) {
      viewInfoBloc.add(
        ViewInfoEvent.registerEditorState(editorState: widget.editorState),
      );
    }

    _initEditorL10n();
    _initializeShortcuts();
    appFlowyEditorAutoScrollEdgeOffset = 220;
    indentableBlockTypes.add(ToggleListBlockKeys.type);
    convertibleBlockTypes.add(ToggleListBlockKeys.type);
    slashMenuItems = _customSlashMenuItems();
    effectiveScrollController = widget.scrollController ?? ScrollController();
    // disable the color parse in the HTML decoder.
    DocumentHTMLDecoder.enableColorParse = false;

    editorScrollController = EditorScrollController(
      editorState: widget.editorState,
      shrinkWrap: widget.shrinkWrap,
      scrollController: effectiveScrollController,
    );

    // keep the previous font style when typing new text.
    supportSlashMenuNodeWhiteList.addAll([
      ToggleListBlockKeys.type,
    ]);
    toolbarItemWhiteList.addAll([
      ToggleListBlockKeys.type,
      CalloutBlockKeys.type,
      TableBlockKeys.type,
    ]);
    AppFlowyRichTextKeys.supportSliced.add(AppFlowyRichTextKeys.fontFamily);

    // customize the dynamic theme color
    _customizeBlockComponentBackgroundColorDecorator();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      focusManager = AFFocusManager.maybeOf(context);
      focusManager?.loseFocusNotifier.addListener(_loseFocus);

      if (widget.initialSelection != null) {
        widget.editorState.updateSelectionWithReason(widget.initialSelection);
      }
    });
  }

  @override
  void didChangeDependencies() {
    final currFocusManager = AFFocusManager.maybeOf(context);
    if (focusManager != currFocusManager) {
      focusManager?.loseFocusNotifier.removeListener(_loseFocus);
      focusManager = currFocusManager;
      focusManager?.loseFocusNotifier.addListener(_loseFocus);
    }
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    focusManager?.loseFocusNotifier.removeListener(_loseFocus);

    if (widget.useViewInfoBloc && !viewInfoBloc.isClosed) {
      viewInfoBloc.add(const ViewInfoEvent.unregisterEditorState());
    }

    SystemChannels.textInput.invokeMethod('TextInput.hide');

    if (widget.scrollController == null) {
      effectiveScrollController.dispose();
    }
    inlineActionsService.dispose();
    editorScrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (bool autoFocus, Selection? selection) =
        _computeAutoFocusParameters();

    final isRTL =
        context.read<AppearanceSettingsCubit>().state.layoutDirection ==
            LayoutDirection.rtlLayout;
    final textDirection = isRTL ? ui.TextDirection.rtl : ui.TextDirection.ltr;

    _setRTLToolbarItems(
      context.read<AppearanceSettingsCubit>().state.enableRtlToolbarItems,
    );

    final editor = Directionality(
      textDirection: textDirection,
      child: AppFlowyEditor(
        editorState: widget.editorState,
        editorScrollController: editorScrollController,
        // setup the auto focus parameters
        autoFocus: widget.autoFocus ?? autoFocus,
        focusedSelection: selection,
        // setup the theme
        editorStyle: styleCustomizer.style(),
        // customize the block builders
        blockComponentBuilders: getEditorBuilderMap(
          slashMenuItems: slashMenuItems,
          context: context,
          editorState: widget.editorState,
          styleCustomizer: widget.styleCustomizer,
          showParagraphPlaceholder: widget.showParagraphPlaceholder,
          placeholderText: widget.placeholderText,
        ),
        // customize the shortcuts
        characterShortcutEvents: characterShortcutEvents,
        commandShortcutEvents: cmdShortcutEvents,
        // customize the context menu items
        contextMenuItems: customContextMenuItems,
        // customize the header and footer.
        header: widget.header,
        footer: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () async {
            // if the last one isn't a empty node, insert a new empty node.
            await _focusOnLastEmptyParagraph();
          },
          child: VSpace(PlatformExtension.isDesktopOrWeb ? 200 : 400),
        ),
      ),
    );

    final editorState = widget.editorState;

    if (PlatformExtension.isMobile) {
      return AppFlowyMobileToolbar(
        toolbarHeight: 42.0,
        editorState: editorState,
        toolbarItemsBuilder: (sel) => buildMobileToolbarItems(editorState, sel),
        child: MobileFloatingToolbar(
          editorState: editorState,
          editorScrollController: editorScrollController,
          toolbarBuilder: (_, anchor, closeToolbar) =>
              CustomMobileFloatingToolbar(
            editorState: editorState,
            anchor: anchor,
            closeToolbar: closeToolbar,
          ),
          child: editor,
        ),
      );
    }

    return Center(
      child: FloatingToolbar(
        style: styleCustomizer.floatingToolbarStyleBuilder(),
        items: toolbarItems,
        editorState: editorState,
        editorScrollController: editorScrollController,
        textDirection: textDirection,
        child: editor,
      ),
    );
  }

  List<SelectionMenuItem> _customSlashMenuItems() {
    final items = [...standardSelectionMenuItems];
    final imageItem = items
        .firstWhereOrNull((e) => e.name == AppFlowyEditorL10n.current.image);
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
      referencedDocumentMenuItem,
      calloutItem,
      outlineItem,
      mathEquationItem,
      codeBlockItem(LocaleKeys.document_selectionMenu_codeBlock.tr()),
      toggleListBlockItem,
      emojiMenuItem,
      autoGeneratorMenuItem,
      dateMenuItem,
    ];
  }

  (bool, Selection?) _computeAutoFocusParameters() {
    if (widget.editorState.document.isEmpty) {
      return (true, Selection.collapsed(Position(path: [0])));
    }
    return const (false, null);
  }

  Future<void> _initializeShortcuts() async {
    defaultCommandShortcutEvents;
    final settingsShortcutService = SettingsShortcutService();
    final customizeShortcuts =
        await settingsShortcutService.getCustomizeShortcuts();
    await settingsShortcutService.updateCommandShortcuts(
      cmdShortcutEvents,
      customizeShortcuts,
    );
  }

  void _setRTLToolbarItems(bool enableRtlToolbarItems) {
    final textDirectionItemIds = textDirectionItems.map((e) => e.id);
    // clear all the text direction items
    toolbarItems.removeWhere((item) => textDirectionItemIds.contains(item.id));
    // only show the rtl item when the layout direction is ltr.
    if (enableRtlToolbarItems) {
      toolbarItems.addAll(textDirectionItems);
    }
  }

  List<CommandShortcutEvent> _buildFindAndReplaceCommands() {
    return findAndReplaceCommands(
      context: context,
      style: FindReplaceStyle(
        findMenuBuilder: (
          context,
          editorState,
          localizations,
          style,
          showReplaceMenu,
          onDismiss,
        ) =>
            Material(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FindAndReplaceMenuWidget(
              editorState: editorState,
              onDismiss: onDismiss,
            ),
          ),
        ),
      ),
    );
  }

  void _customizeBlockComponentBackgroundColorDecorator() {
    blockComponentBackgroundColorDecorator = (Node node, String colorString) =>
        buildEditorCustomizedColor(context, node, colorString);
  }

  void _initEditorL10n() => AppFlowyEditorL10n.current = EditorI18n();

  Future<void> _focusOnLastEmptyParagraph() async {
    final editorState = widget.editorState;
    final root = editorState.document.root;
    final lastNode = root.children.lastOrNull;
    final transaction = editorState.transaction;
    if (lastNode == null ||
        lastNode.delta?.isEmpty == false ||
        lastNode.type != ParagraphBlockKeys.type) {
      transaction.insertNode([root.children.length], paragraphNode());
      transaction.afterSelection = Selection.collapsed(
        Position(path: [root.children.length]),
      );
    } else {
      transaction.afterSelection = Selection.collapsed(
        Position(path: lastNode.path),
      );
    }
    await editorState.apply(transaction);
  }
}

Color? buildEditorCustomizedColor(
  BuildContext context,
  Node node,
  String colorString,
) {
  // the color string is from FlowyTint.
  final tintColor = FlowyTint.values.firstWhereOrNull(
    (e) => e.id == colorString,
  );
  if (tintColor != null) {
    return tintColor.color(context);
  }

  final themeColor = themeBackgroundColors[colorString];
  if (themeColor != null) {
    return themeColor.color(context);
  }

  if (colorString == optionActionColorDefaultColor) {
    final defaultColor = node.type == CalloutBlockKeys.type
        ? AFThemeExtension.of(context).calloutBGColor
        : Colors.transparent;
    return defaultColor;
  }

  if (colorString == tableCellDefaultColor) {
    return AFThemeExtension.of(context).tableCellBGColor;
  }

  return null;
}

bool showInAnyTextType(EditorState editorState) {
  final selection = editorState.selection;
  if (selection == null) {
    return false;
  }

  final nodes = editorState.getNodesInSelection(selection);
  return nodes.any((node) => toolbarItemWhiteList.contains(node.type));
}
