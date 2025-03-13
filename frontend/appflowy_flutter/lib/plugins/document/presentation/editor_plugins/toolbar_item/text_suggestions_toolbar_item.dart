import 'dart:collection';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/actions/block_action_option_cubit.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy_editor/appflowy_editor.dart'
    hide QuoteBlockComponentBuilder, quoteNode, QuoteBlockKeys;
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';

import 'text_heading_toolbar_item.dart';

const _kSuggestionsItemId = 'editor.suggestions';

@visibleForTesting
const kSuggestionsItemKey = ValueKey('SuggestionsItem');

@visibleForTesting
const kSuggestionsItemListKey = ValueKey('SuggestionsItemList');

final ToolbarItem suggestionsItem = ToolbarItem(
  id: _kSuggestionsItemId,
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
  });

  final EditorState editorState;
  final ToolbarTooltipBuilder? tooltipBuilder;

  @override
  State<SuggestionsActionList> createState() => _SuggestionsActionListState();
}

class _SuggestionsActionListState extends State<SuggestionsActionList> {
  final popoverController = PopoverController();

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
  }

  @override
  void dispose() {
    super.dispose();
    popoverController.close();
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      controller: popoverController,
      direction: PopoverDirection.bottomWithLeftAligned,
      offset: const Offset(-8.0, 2.0),
      onOpen: () => keepEditorFocusNotifier.increase(),
      onClose: () {
        setState(() {
          isSelected = false;
        });
        keepEditorFocusNotifier.decrease();
      },
      constraints: const BoxConstraints(maxWidth: 240, maxHeight: 400),
      popupBuilder: (context) => buildPopoverContent(context),
      child: buildChild(context),
    );
  }

  void showPopover() {
    keepEditorFocusNotifier.increase();
    popoverController.show();
  }

  Widget buildChild(BuildContext context) {
    final iconColor = Theme.of(context).iconTheme.color;
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
                FlowySvg(
                  FlowySvgs.toolbar_arrow_down_m,
                  size: Size.square(20),
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
          _kSuggestionsItemId,
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
        onTap: () {
          item.onTap(widget.editorState);
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
  final ValueChanged<EditorState> onTap;
}

enum SuggestionGroup { textHeading, list, toggle, quote }

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
  quote(SuggestionGroup.quote);

  const SuggestionType(this.group);

  final SuggestionGroup group;
}

final textSuggestionItem = SuggestionItem(
  type: SuggestionType.text,
  title: AppFlowyEditorL10n.current.text,
  svg: FlowySvgs.type_text_m,
  onTap: (state) => formatNodeToText(state),
);

final h1SuggestionItem = SuggestionItem(
  type: SuggestionType.h1,
  title: LocaleKeys.document_toolbar_h1.tr(),
  svg: FlowySvgs.type_h1_m,
  onTap: (state) => _turnInto(state, HeadingBlockKeys.type, level: 1),
);

final h2SuggestionItem = SuggestionItem(
  type: SuggestionType.h2,
  title: LocaleKeys.document_toolbar_h2.tr(),
  svg: FlowySvgs.type_h2_m,
  onTap: (state) => _turnInto(state, HeadingBlockKeys.type, level: 2),
);

final h3SuggestionItem = SuggestionItem(
  type: SuggestionType.h3,
  title: LocaleKeys.document_toolbar_h3.tr(),
  svg: FlowySvgs.type_h3_m,
  onTap: (state) => _turnInto(state, HeadingBlockKeys.type, level: 3),
);

final checkboxSuggestionItem = SuggestionItem(
  type: SuggestionType.checkbox,
  title: LocaleKeys.editor_checkbox.tr(),
  svg: FlowySvgs.type_todo_m,
  onTap: (state) => _turnInto(state, TodoListBlockKeys.type),
);

final bulletedSuggestionItem = SuggestionItem(
  type: SuggestionType.bulleted,
  title: LocaleKeys.editor_bulletedListShortForm.tr(),
  svg: FlowySvgs.type_bulleted_list_m,
  onTap: (state) => _turnInto(state, BulletedListBlockKeys.type),
);

final numberedSuggestionItem = SuggestionItem(
  type: SuggestionType.numbered,
  title: LocaleKeys.editor_numberedListShortForm.tr(),
  svg: FlowySvgs.type_numbered_list_m,
  onTap: (state) => _turnInto(state, NumberedListBlockKeys.type),
);

final toggleSuggestionItem = SuggestionItem(
  type: SuggestionType.toggle,
  title: LocaleKeys.editor_toggleListShortForm.tr(),
  svg: FlowySvgs.type_toggle_list_m,
  onTap: (state) => _turnInto(state, ToggleListBlockKeys.type),
);

final toggleH1SuggestionItem = SuggestionItem(
  type: SuggestionType.toggleH1,
  title: LocaleKeys.editor_toggleHeading1ShortForm.tr(),
  svg: FlowySvgs.type_toggle_h1_m,
  onTap: (state) => _turnInto(state, ToggleListBlockKeys.type, level: 1),
);

final toggleH2SuggestionItem = SuggestionItem(
  type: SuggestionType.toggleH2,
  title: LocaleKeys.editor_toggleHeading2ShortForm.tr(),
  svg: FlowySvgs.type_toggle_h2_m,
  onTap: (state) => _turnInto(state, ToggleListBlockKeys.type, level: 2),
);

final toggleH3SuggestionItem = SuggestionItem(
  type: SuggestionType.toggleH3,
  title: LocaleKeys.editor_toggleHeading3ShortForm.tr(),
  svg: FlowySvgs.type_toggle_h3_m,
  onTap: (state) => _turnInto(state, ToggleListBlockKeys.type, level: 3),
);

final callOutSuggestionItem = SuggestionItem(
  type: SuggestionType.callOut,
  title: LocaleKeys.document_plugins_callout.tr(),
  svg: FlowySvgs.type_callout_m,
  onTap: (state) => _turnInto(state, CalloutBlockKeys.type),
);

final quoteSuggestionItem = SuggestionItem(
  type: SuggestionType.quote,
  title: LocaleKeys.editor_quote.tr(),
  svg: FlowySvgs.type_quote_m,
  onTap: (state) => _turnInto(state, QuoteBlockKeys.type),
);

Future<void> _turnInto(EditorState state, String type, {int? level}) async {
  final selection = state.selection!;
  final node = state.getNodeAtPath(selection.start.path)!;
  await BlockActionOptionCubit.turnIntoBlock(
    type,
    node,
    state,
    level: level,
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
]);

final nodeType2SuggestionType = UnmodifiableMapView({
  ParagraphBlockKeys.type: SuggestionType.text,
  NumberedListBlockKeys.type: SuggestionType.numbered,
  BulletedListBlockKeys.type: SuggestionType.bulleted,
  QuoteBlockKeys.type: SuggestionType.quote,
  TodoListBlockKeys.type: SuggestionType.checkbox,
  CalloutBlockKeys.type: SuggestionType.callOut,
});
