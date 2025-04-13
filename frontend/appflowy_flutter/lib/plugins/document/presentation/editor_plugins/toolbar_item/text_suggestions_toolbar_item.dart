import 'dart:collection';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/block_action_option_cubit.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/presentation/home/menu/menu_shared_state.dart';
import 'package:appflowy_editor/appflowy_editor.dart'
    hide QuoteBlockComponentBuilder, quoteNode, QuoteBlockKeys;
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';

import 'text_heading_toolbar_item.dart';
import 'toolbar_id_enum.dart';

@visibleForTesting
const kSuggestionsItemKey = ValueKey('SuggestionsItem');

@visibleForTesting
const kSuggestionsItemListKey = ValueKey('SuggestionsItemList');

final ToolbarItem suggestionsItem = ToolbarItem(
  id: ToolbarId.suggestions.id,
  group: 3,
  isActive: enableSuggestions,
  builder: (
    context,
    editorState,
    highlightColor,
    iconColor,
    tooltipBuilder,
  ) {
    return SuggestionsActionList(
      editorState: editorState,
      tooltipBuilder: tooltipBuilder,
    );
  },
);

class SuggestionsActionList extends StatefulWidget {
  const SuggestionsActionList({
    super.key,
    required this.editorState,
    this.tooltipBuilder,
    this.child,
    this.onSelect,
    this.popoverController,
    this.popoverDirection = PopoverDirection.bottomWithLeftAligned,
    this.showOffset = const Offset(0, 2),
  });

  final EditorState editorState;
  final ToolbarTooltipBuilder? tooltipBuilder;
  final Widget? child;
  final VoidCallback? onSelect;
  final PopoverController? popoverController;
  final PopoverDirection popoverDirection;
  final Offset showOffset;

  @override
  State<SuggestionsActionList> createState() => _SuggestionsActionListState();
}

class _SuggestionsActionListState extends State<SuggestionsActionList> {
  late PopoverController popoverController =
      widget.popoverController ?? PopoverController();

  bool isSelected = false;

  final List<SuggestionItem> suggestionItems = suggestions.sublist(0, 4);
  final List<SuggestionItem> turnIntoItems =
      suggestions.sublist(4, suggestions.length);

  EditorState get editorState => widget.editorState;

  SuggestionItem currentSuggestionItem = textSuggestionItem;

  @override
  void initState() {
    super.initState();
    refreshSuggestions();
    editorState.selectionNotifier.addListener(refreshSuggestions);
  }

  @override
  void dispose() {
    editorState.selectionNotifier.removeListener(refreshSuggestions);
    popoverController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      controller: popoverController,
      direction: widget.popoverDirection,
      offset: widget.showOffset,
      onOpen: () => keepEditorFocusNotifier.increase(),
      onClose: () {
        setState(() {
          isSelected = false;
        });
        keepEditorFocusNotifier.decrease();
      },
      constraints: const BoxConstraints(maxWidth: 240, maxHeight: 400),
      popupBuilder: (context) => buildPopoverContent(context),
      child: widget.child ?? buildChild(context),
    );
  }

  void showPopover() {
    keepEditorFocusNotifier.increase();
    popoverController.show();
  }

  Widget buildChild(BuildContext context) {
    final theme = AppFlowyTheme.of(context),
        iconColor = theme.iconColorTheme.primary;
    final child = FlowyHover(
      isSelected: () => isSelected,
      style: HoverStyle(
        hoverColor: EditorStyleCustomizer.toolbarHoverColor(context),
        foregroundColorOnHover: Theme.of(context).iconTheme.color,
      ),
      resetHoverOnRebuild: false,
      child: FlowyTooltip(
        preferBelow: true,
        child: RawMaterialButton(
          key: kSuggestionsItemKey,
          constraints: BoxConstraints(maxHeight: 32, minWidth: 60),
          clipBehavior: Clip.antiAlias,
          hoverElevation: 0,
          highlightElevation: 0,
          shape: RoundedRectangleBorder(borderRadius: Corners.s6Border),
          fillColor: Colors.transparent,
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          elevation: 0,
          onPressed: () {
            setState(() {
              isSelected = true;
            });
            showPopover();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FlowyText(
                  currentSuggestionItem.title,
                  fontWeight: FontWeight.w400,
                  figmaLineHeight: 20,
                ),
                HSpace(4),
                FlowySvg(
                  FlowySvgs.toolbar_arrow_down_m,
                  size: Size(12, 20),
                  color: iconColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return widget.tooltipBuilder?.call(
          context,
          ToolbarId.suggestions.id,
          currentSuggestionItem.title,
          child,
        ) ??
        child;
  }

  Widget buildPopoverContent(BuildContext context) {
    final textColor = Color(0xff99A1A8);
    return MouseRegion(
      child: SingleChildScrollView(
        key: kSuggestionsItemListKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildSubTitle(
              LocaleKeys.document_toolbar_suggestions.tr(),
              textColor,
            ),
            ...List.generate(suggestionItems.length, (index) {
              return buildItem(suggestionItems[index]);
            }),
            buildSubTitle(LocaleKeys.document_toolbar_turnInto.tr(), textColor),
            ...List.generate(turnIntoItems.length, (index) {
              return buildItem(turnIntoItems[index]);
            }),
          ],
        ),
      ),
    );
  }

  Widget buildItem(SuggestionItem item) {
    final isSelected = item.type == currentSuggestionItem.type;
    return SizedBox(
      height: 36,
      child: FlowyButton(
        leftIconSize: const Size.square(20),
        leftIcon: FlowySvg(item.svg),
        iconPadding: 12,
        text: FlowyText(
          item.title,
          fontWeight: FontWeight.w400,
          figmaLineHeight: 20,
        ),
        rightIcon: isSelected ? FlowySvg(FlowySvgs.toolbar_check_m) : null,
        onTap: () {
          item.onTap(widget.editorState, true);
          widget.onSelect?.call();
          popoverController.close();
        },
      ),
    );
  }

  Widget buildSubTitle(String text, Color color) {
    return Container(
      height: 32,
      margin: EdgeInsets.symmetric(horizontal: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FlowyText.semibold(
          text,
          color: color,
          figmaLineHeight: 16,
        ),
      ),
    );
  }

  void refreshSuggestions() {
    final selection = editorState.selection;
    if (selection == null || !selection.isSingle) {
      return;
    }
    final node = editorState.getNodeAtPath(selection.start.path);
    if (node == null || node.delta == null) {
      return;
    }
    final nodeType = node.type;
    SuggestionType? suggestionType;
    if (nodeType == HeadingBlockKeys.type) {
      final level = node.attributes[HeadingBlockKeys.level] ?? 1;
      if (level == 1) {
        suggestionType = SuggestionType.h1;
      } else if (level == 2) {
        suggestionType = SuggestionType.h2;
      } else if (level == 3) {
        suggestionType = SuggestionType.h3;
      }
    } else if (nodeType == ToggleListBlockKeys.type) {
      final level = node.attributes[ToggleListBlockKeys.level];
      if (level == null) {
        suggestionType = SuggestionType.toggle;
      } else if (level == 1) {
        suggestionType = SuggestionType.toggleH1;
      } else if (level == 2) {
        suggestionType = SuggestionType.toggleH2;
      } else if (level == 3) {
        suggestionType = SuggestionType.toggleH3;
      }
    } else {
      suggestionType = nodeType2SuggestionType[nodeType];
    }
    if (suggestionType == null) return;
    suggestionItems.clear();
    turnIntoItems.clear();
    for (final item in suggestions) {
      if (item.type.group == suggestionType.group &&
          item.type != suggestionType) {
        suggestionItems.add(item);
      } else {
        turnIntoItems.add(item);
      }
    }
    currentSuggestionItem =
        suggestions.where((item) => item.type == suggestionType).first;
    if (mounted) setState(() {});
  }
}

class SuggestionItem {
  SuggestionItem({
    required this.type,
    required this.title,
    required this.svg,
    required this.onTap,
  });

  final SuggestionType type;
  final String title;
  final FlowySvgData svg;
  final Function(EditorState state, bool keepSelection) onTap;
}

enum SuggestionGroup { textHeading, list, toggle, quote, page }

enum SuggestionType {
  text(SuggestionGroup.textHeading),
  h1(SuggestionGroup.textHeading),
  h2(SuggestionGroup.textHeading),
  h3(SuggestionGroup.textHeading),
  checkbox(SuggestionGroup.list),
  bulleted(SuggestionGroup.list),
  numbered(SuggestionGroup.list),
  toggle(SuggestionGroup.toggle),
  toggleH1(SuggestionGroup.toggle),
  toggleH2(SuggestionGroup.toggle),
  toggleH3(SuggestionGroup.toggle),
  callOut(SuggestionGroup.quote),
  quote(SuggestionGroup.quote),
  page(SuggestionGroup.page);

  const SuggestionType(this.group);

  final SuggestionGroup group;
}

final textSuggestionItem = SuggestionItem(
  type: SuggestionType.text,
  title: AppFlowyEditorL10n.current.text,
  svg: FlowySvgs.type_text_m,
  onTap: (state, _) => formatNodeToText(state),
);

final h1SuggestionItem = SuggestionItem(
  type: SuggestionType.h1,
  title: LocaleKeys.document_toolbar_h1.tr(),
  svg: FlowySvgs.type_h1_m,
  onTap: (state, keepSelection) => _turnInto(
    state,
    HeadingBlockKeys.type,
    level: 1,
    keepSelection: keepSelection,
  ),
);

final h2SuggestionItem = SuggestionItem(
  type: SuggestionType.h2,
  title: LocaleKeys.document_toolbar_h2.tr(),
  svg: FlowySvgs.type_h2_m,
  onTap: (state, keepSelection) => _turnInto(
    state,
    HeadingBlockKeys.type,
    level: 2,
    keepSelection: keepSelection,
  ),
);

final h3SuggestionItem = SuggestionItem(
  type: SuggestionType.h3,
  title: LocaleKeys.document_toolbar_h3.tr(),
  svg: FlowySvgs.type_h3_m,
  onTap: (state, keepSelection) => _turnInto(
    state,
    HeadingBlockKeys.type,
    level: 3,
    keepSelection: keepSelection,
  ),
);

final checkboxSuggestionItem = SuggestionItem(
  type: SuggestionType.checkbox,
  title: LocaleKeys.editor_checkbox.tr(),
  svg: FlowySvgs.type_todo_m,
  onTap: (state, keepSelection) => _turnInto(
    state,
    TodoListBlockKeys.type,
    keepSelection: keepSelection,
  ),
);

final bulletedSuggestionItem = SuggestionItem(
  type: SuggestionType.bulleted,
  title: LocaleKeys.editor_bulletedListShortForm.tr(),
  svg: FlowySvgs.type_bulleted_list_m,
  onTap: (state, keepSelection) => _turnInto(
    state,
    BulletedListBlockKeys.type,
    keepSelection: keepSelection,
  ),
);

final numberedSuggestionItem = SuggestionItem(
  type: SuggestionType.numbered,
  title: LocaleKeys.editor_numberedListShortForm.tr(),
  svg: FlowySvgs.type_numbered_list_m,
  onTap: (state, keepSelection) => _turnInto(
    state,
    NumberedListBlockKeys.type,
    keepSelection: keepSelection,
  ),
);

final toggleSuggestionItem = SuggestionItem(
  type: SuggestionType.toggle,
  title: LocaleKeys.editor_toggleListShortForm.tr(),
  svg: FlowySvgs.type_toggle_list_m,
  onTap: (state, keepSelection) => _turnInto(
    state,
    ToggleListBlockKeys.type,
    keepSelection: keepSelection,
  ),
);

final toggleH1SuggestionItem = SuggestionItem(
  type: SuggestionType.toggleH1,
  title: LocaleKeys.editor_toggleHeading1ShortForm.tr(),
  svg: FlowySvgs.type_toggle_h1_m,
  onTap: (state, keepSelection) => _turnInto(
    state,
    ToggleListBlockKeys.type,
    level: 1,
    keepSelection: keepSelection,
  ),
);

final toggleH2SuggestionItem = SuggestionItem(
  type: SuggestionType.toggleH2,
  title: LocaleKeys.editor_toggleHeading2ShortForm.tr(),
  svg: FlowySvgs.type_toggle_h2_m,
  onTap: (state, keepSelection) => _turnInto(
    state,
    ToggleListBlockKeys.type,
    level: 2,
    keepSelection: keepSelection,
  ),
);

final toggleH3SuggestionItem = SuggestionItem(
  type: SuggestionType.toggleH3,
  title: LocaleKeys.editor_toggleHeading3ShortForm.tr(),
  svg: FlowySvgs.type_toggle_h3_m,
  onTap: (state, keepSelection) => _turnInto(
    state,
    ToggleListBlockKeys.type,
    level: 3,
    keepSelection: keepSelection,
  ),
);

final callOutSuggestionItem = SuggestionItem(
  type: SuggestionType.callOut,
  title: LocaleKeys.document_plugins_callout.tr(),
  svg: FlowySvgs.type_callout_m,
  onTap: (state, keepSelection) => _turnInto(
    state,
    CalloutBlockKeys.type,
    keepSelection: keepSelection,
  ),
);

final quoteSuggestionItem = SuggestionItem(
  type: SuggestionType.quote,
  title: LocaleKeys.editor_quote.tr(),
  svg: FlowySvgs.type_quote_m,
  onTap: (state, keepSelection) => _turnInto(
    state,
    QuoteBlockKeys.type,
    keepSelection: keepSelection,
  ),
);

final pateItem = SuggestionItem(
  type: SuggestionType.page,
  title: LocaleKeys.editor_page.tr(),
  svg: FlowySvgs.icon_document_s,
  onTap: (state, keepSelection) => _turnInto(
    state,
    SubPageBlockKeys.type,
    viewId: getIt<MenuSharedState>().latestOpenView?.id,
    keepSelection: keepSelection,
  ),
);

Future<void> _turnInto(
  EditorState state,
  String type, {
  int? level,
  String? viewId,
  bool keepSelection = true,
}) async {
  final selection = state.selection!;
  final node = state.getNodeAtPath(selection.start.path)!;
  await BlockActionOptionCubit.turnIntoBlock(
    type,
    node,
    state,
    level: level,
    currentViewId: viewId,
    keepSelection: keepSelection,
  );
}

final suggestions = UnmodifiableListView([
  textSuggestionItem,
  h1SuggestionItem,
  h2SuggestionItem,
  h3SuggestionItem,
  checkboxSuggestionItem,
  bulletedSuggestionItem,
  numberedSuggestionItem,
  toggleSuggestionItem,
  toggleH1SuggestionItem,
  toggleH2SuggestionItem,
  toggleH3SuggestionItem,
  callOutSuggestionItem,
  quoteSuggestionItem,
  pateItem,
]);

final nodeType2SuggestionType = UnmodifiableMapView({
  ParagraphBlockKeys.type: SuggestionType.text,
  NumberedListBlockKeys.type: SuggestionType.numbered,
  BulletedListBlockKeys.type: SuggestionType.bulleted,
  QuoteBlockKeys.type: SuggestionType.quote,
  TodoListBlockKeys.type: SuggestionType.checkbox,
  CalloutBlockKeys.type: SuggestionType.callOut,
});
