import 'package:appflowy/plugins/document/application/doc_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_configuration.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/background_color/theme_background_color.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/page_reference_commands.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/i18n/editor_i18n.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/slash_menu_items.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy/plugins/inline_actions/handlers/date_reference.dart';
import 'package:appflowy/plugins/inline_actions/handlers/inline_page_reference.dart';
import 'package:appflowy/plugins/inline_actions/handlers/reminder_reference.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_command.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_service.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/notifications/notification_action.dart';
import 'package:appflowy/workspace/application/notifications/notification_action_bloc.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/application/settings/shortcuts/settings_shortcuts_service.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/emoji_picker/emoji_picker.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:collection/collection.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final List<CommandShortcutEvent> commandShortcutEvents = [
  toggleToggleListCommand,
  ...codeBlockCommands,
  customCopyCommand,
  customPasteCommand,
  customCutCommand,
  ...standardCommandShortcutEvents,
];

final List<CommandShortcutEvent> defaultCommandShortcutEvents = [
  ...commandShortcutEvents.map((e) => e.copyWith()).toList(),
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
      InlinePageReferenceService(
        currentViewId: documentBloc.view.id,
      ).inlinePageReferenceDelegate,
      DateReferenceService(context).dateReferenceDelegate,
      ReminderReferenceService(context).reminderReferenceDelegate,
    ],
  );

  late final List<CommandShortcutEvent> commandShortcutEvents = [
    toggleToggleListCommand,
    ...codeBlockCommands,
    customCopyCommand,
    customPasteCommand,
    customCutCommand,
    ...standardCommandShortcutEvents,
    ..._buildFindAndReplaceCommands(),
  ];

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
      getEditorBuilderMap(
    context: context,
    editorState: widget.editorState,
    styleCustomizer: widget.styleCustomizer,
  );

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

        /// Inline page menu
        /// - Using `[[`
        pageReferenceShortcutBrackets(
          context,
          documentBloc.view.id,
          styleCustomizer.inlineActionsMenuStyleBuilder(),
        ),

        /// - Using `+`
        pageReferenceShortcutPlusSign(
          context,
          documentBloc.view.id,
          styleCustomizer.inlineActionsMenuStyleBuilder(),
        ),
      ];

  EditorStyleCustomizer get styleCustomizer => widget.styleCustomizer;
  DocumentBloc get documentBloc => context.read<DocumentBloc>();

  Future<bool> showSlashMenu(editorState) async {
    final result = await customSlashCommand(
      slashMenuItems,
      shouldInsertSlash: false,
      style: styleCustomizer.selectionMenuStyleBuilder(),
    ).handler(editorState);
    return result;
  }

  @override
  void initState() {
    super.initState();

    _initEditorL10n();
    _initializeShortcuts();
    indentableBlockTypes.add(ToggleListBlockKeys.type);
    convertibleBlockTypes.add(ToggleListBlockKeys.type);
    slashMenuItems = _customSlashMenuItems();
    effectiveScrollController = widget.scrollController ?? ScrollController();

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
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      effectiveScrollController.dispose();
    }
    inlineActionsService.dispose();

    widget.editorState.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (bool autoFocus, Selection? selection) =
        _computeAutoFocusParameters();

    final isRTL =
        context.read<AppearanceSettingsCubit>().state.layoutDirection ==
            LayoutDirection.rtlLayout;
    final textDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;

    _setRTLToolbarItems(isRTL);

    final editorScrollController = EditorScrollController(
      editorState: widget.editorState,
      shrinkWrap: widget.shrinkWrap,
      scrollController: effectiveScrollController,
    );

    final editor = Directionality(
      textDirection: textDirection,
      child: AppFlowyEditor(
        editorState: widget.editorState,
        editable: true,
        editorScrollController: editorScrollController,
        // setup the auto focus parameters
        autoFocus: widget.autoFocus ?? autoFocus,
        focusedSelection: selection,
        // setup the theme
        editorStyle: styleCustomizer.style(),
        // customize the block builders
        blockComponentBuilders: blockComponentBuilders,
        // customize the shortcuts
        characterShortcutEvents: characterShortcutEvents,
        commandShortcutEvents: commandShortcutEvents,
        // customize the context menu items
        contextMenuItems: customContextMenuItems,
        // customize the header and footer.
        header: widget.header,
        footer: const VSpace(200),
      ),
    );

    final editorState = widget.editorState;
    _setInitialSelection(editorScrollController);

    if (PlatformExtension.isMobile) {
      return Column(
        children: [
          Expanded(
            child: MobileFloatingToolbar(
              editorState: editorState,
              editorScrollController: editorScrollController,
              toolbarBuilder: (context, anchor) {
                return AdaptiveTextSelectionToolbar.editable(
                  clipboardStatus: ClipboardStatus.pasteable,
                  onCopy: () => copyCommand.execute(editorState),
                  onCut: () => cutCommand.execute(editorState),
                  onPaste: () => pasteCommand.execute(editorState),
                  onSelectAll: () => selectAllCommand.execute(editorState),
                  anchors: TextSelectionToolbarAnchors(
                    primaryAnchor: anchor,
                  ),
                );
              },
              child: editor,
            ),
          ),
          MobileToolbar(
            editorState: editorState,
            toolbarItems: [
              textDecorationMobileToolbarItem,
              buildTextAndBackgroundColorMobileToolbarItem(),
              headingMobileToolbarItem,
              todoListMobileToolbarItem,
              listMobileToolbarItem,
              linkMobileToolbarItem,
              quoteMobileToolbarItem,
              dividerMobileToolbarItem,
              codeMobileToolbarItem,
            ],
          ),
        ],
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

  void _setInitialSelection(EditorScrollController scrollController) {
    final action = getIt<NotificationActionBloc>().state.action;
    final viewId = action?.objectId;
    final nodePath =
        action?.arguments?[ActionArgumentKeys.nodePath.name] as int?;

    if (viewId != null && viewId == documentBloc.view.id && nodePath != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollController.itemScrollController.jumpTo(index: nodePath);
        widget.editorState.selection =
            Selection.collapsed(Position(path: [nodePath]));
      });
    }
  }

  List<SelectionMenuItem> _customSlashMenuItems() {
    final items = [...standardSelectionMenuItems];
    final imageItem = items.firstWhereOrNull(
      (element) => element.name == AppFlowyEditorL10n.current.image,
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
      referencedDocumentMenuItem,
      calloutItem,
      outlineItem,
      mathEquationItem,
      codeBlockItem,
      toggleListBlockItem,
      emojiMenuItem,
      autoGeneratorMenuItem,
      dateMenuItem,
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
    // TODO(Xazin): Refactor lazy initialization
    defaultCommandShortcutEvents;
    final settingsShortcutService = SettingsShortcutService();
    final customizeShortcuts =
        await settingsShortcutService.getCustomizeShortcuts();
    await settingsShortcutService.updateCommandShortcuts(
      commandShortcutEvents,
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
        ) {
          return Material(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
              child: FindAndReplaceMenuWidget(
                editorState: editorState,
                onDismiss: onDismiss,
              ),
            ),
          );
        },
      ),
    );
  }

  void _customizeBlockComponentBackgroundColorDecorator() {
    blockComponentBackgroundColorDecorator = (Node node, String colorString) {
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
    };
  }

  void _initEditorL10n() {
    AppFlowyEditorL10n.current = EditorI18n();
  }
}
