import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_page.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/desktop_toolbar/link/link_create_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/desktop_toolbar/link/link_hover_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/desktop_toolbar/toolbar_cubit.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
// ignore: implementation_imports
import 'package:appflowy_editor/src/editor/toolbar/desktop/items/utils/tooltip_util.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'custom_text_align_toolbar_item.dart';
import 'text_suggestions_toolbar_item.dart';

const _kMoreOptionItemId = 'editor.more_option';
const kFontToolbarItemId = 'editor.font';

@visibleForTesting
const kFontFamilyToolbarItemKey = ValueKey('FontFamilyToolbarItem');

final ToolbarItem moreOptionItem = ToolbarItem(
  id: _kMoreOptionItemId,
  group: 5,
  isActive: showInAnyTextType,
  builder: (
    context,
    editorState,
    highlightColor,
    iconColor,
    tooltipBuilder,
  ) {
    return MoreOptionActionList(
      editorState: editorState,
      tooltipBuilder: tooltipBuilder,
      highlightColor: highlightColor,
    );
  },
);

class MoreOptionActionList extends StatefulWidget {
  const MoreOptionActionList({
    super.key,
    required this.editorState,
    required this.highlightColor,
    this.tooltipBuilder,
  });

  final EditorState editorState;
  final ToolbarTooltipBuilder? tooltipBuilder;
  final Color highlightColor;

  @override
  State<MoreOptionActionList> createState() => _MoreOptionActionListState();
}

class _MoreOptionActionListState extends State<MoreOptionActionList> {
  final popoverController = PopoverController();
  PopoverController fontPopoverController = PopoverController();
  PopoverController suggestionsPopoverController = PopoverController();
  PopoverController textAlignPopoverController = PopoverController();

  bool isSelected = false;

  EditorState get editorState => widget.editorState;

  Color get highlightColor => widget.highlightColor;

  MoreOptionCommand? tappedCommand;

  @override
  void dispose() {
    super.dispose();
    popoverController.close();
    fontPopoverController.close();
    suggestionsPopoverController.close();
    textAlignPopoverController.close();
  }

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      controller: popoverController,
      direction: PopoverDirection.bottomWithLeftAligned,
      offset: const Offset(0, 2.0),
      onOpen: () => keepEditorFocusNotifier.increase(),
      onClose: () {
        setState(() {
          isSelected = false;
        });
        keepEditorFocusNotifier.decrease();
      },
      popupBuilder: (context) => buildPopoverContent(),
      child: buildChild(context),
    );
  }

  void showPopover() {
    keepEditorFocusNotifier.increase();
    popoverController.show();
  }

  Widget buildChild(BuildContext context) {
    final iconColor = Theme.of(context).iconTheme.color;
    final child = FlowyIconButton(
      width: 36,
      height: 32,
      isSelected: isSelected,
      hoverColor: EditorStyleCustomizer.toolbarHoverColor(context),
      icon: FlowySvg(
        FlowySvgs.toolbar_more_m,
        size: Size.square(20),
        color: iconColor,
      ),
      onPressed: () {
        setState(() {
          isSelected = true;
        });
        showPopover();
      },
    );

    return widget.tooltipBuilder?.call(
          context,
          _kMoreOptionItemId,
          LocaleKeys.document_toolbar_moreOptions.tr(),
          child,
        ) ??
        child;
  }

  Color? getFormulaColor() {
    if (isFormulaHighlight(editorState)) {
      return widget.highlightColor;
    }
    return null;
  }

  Color? getStrikethroughColor() {
    final selection = editorState.selection;
    if (selection == null || selection.isCollapsed) {
      return null;
    }
    final node = editorState.getNodeAtPath(selection.start.path);
    final delta = node?.delta;
    if (node == null || delta == null) {
      return null;
    }

    final nodes = editorState.getNodesInSelection(selection);
    final isHighlight = nodes.allSatisfyInSelection(
      selection,
      (delta) =>
          delta.isNotEmpty &&
          delta.everyAttributes(
            (attr) => attr[MoreOptionCommand.strikethrough.name] == true,
          ),
    );
    return isHighlight ? widget.highlightColor : null;
  }

  Widget buildPopoverContent() {
    final showFormula = onlyShowInSingleSelectionAndTextType(editorState);
    const fontColor = Color(0xff99A1A8);
    final isNarrow = isNarrowWindow(editorState);
    return MouseRegion(
      child: SeparatedColumn(
        mainAxisSize: MainAxisSize.min,
        separatorBuilder: () => const VSpace(4.0),
        children: [
          if (isNarrow) ...[
            buildTurnIntoSelector(),
            buildCommandItem(MoreOptionCommand.link),
            buildTextAlignSelector(),
          ],
          buildFontSelector(),
          buildCommandItem(
            MoreOptionCommand.strikethrough,
            rightIcon: FlowyText(
              shortcutTooltips(
                '⌘⇧S',
                'Ctrl⇧S',
                'Ctrl⇧S',
              ).trim(),
              color: fontColor,
              fontSize: 12,
              figmaLineHeight: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          if (showFormula)
            buildCommandItem(
              MoreOptionCommand.formula,
              rightIcon: FlowyText(
                shortcutTooltips(
                  '⌘⇧E',
                  'Ctrl⇧E',
                  'Ctrl⇧E',
                ).trim(),
                color: fontColor,
                fontSize: 12,
                figmaLineHeight: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
    );
  }

  Widget buildCommandItem(
    MoreOptionCommand command, {
    Widget? rightIcon,
    VoidCallback? onTap,
  }) {
    final isFontCommand = command == MoreOptionCommand.font;
    return SizedBox(
      height: 36,
      child: FlowyButton(
        key: isFontCommand ? kFontFamilyToolbarItemKey : null,
        leftIconSize: const Size.square(20),
        leftIcon: FlowySvg(command.svg),
        rightIcon: rightIcon,
        iconPadding: 12,
        text: FlowyText(
          command.title,
          figmaLineHeight: 20,
          fontWeight: FontWeight.w400,
        ),
        onTap: onTap ??
            () {
              command.onExecute(editorState, context);
              hideOtherPopovers(command);
              if (command != MoreOptionCommand.font) {
                popoverController.close();
              }
            },
      ),
    );
  }

  Widget buildFontSelector() {
    final selection = editorState.selection!;
    final String? currentFontFamily = editorState
        .getDeltaAttributeValueInSelection(AppFlowyRichTextKeys.fontFamily);
    return FontFamilyDropDown(
      currentFontFamily: currentFontFamily ?? '',
      offset: const Offset(-240, 0),
      popoverController: fontPopoverController,
      onOpen: () => keepEditorFocusNotifier.increase(),
      onClose: () => keepEditorFocusNotifier.decrease(),
      onFontFamilyChanged: (fontFamily) async {
        fontPopoverController.close();
        popoverController.close();
        try {
          await editorState.formatDelta(selection, {
            AppFlowyRichTextKeys.fontFamily: fontFamily,
          });
        } catch (e) {
          Log.error('Failed to set font family: $e');
        }
      },
      onResetFont: () async {
        fontPopoverController.close();
        popoverController.close();
        await editorState
            .formatDelta(selection, {AppFlowyRichTextKeys.fontFamily: null});
      },
      child: buildCommandItem(
        MoreOptionCommand.font,
        rightIcon: FlowySvg(FlowySvgs.toolbar_arrow_right_m),
      ),
    );
  }

  Widget buildTurnIntoSelector() {
    final selectionRects = editorState.selectionRects();
    double height = -6;
    if (selectionRects.isNotEmpty) height = selectionRects.first.height;
    return SuggestionsActionList(
      editorState: editorState,
      popoverController: suggestionsPopoverController,
      popoverDirection: PopoverDirection.leftWithTopAligned,
      showOffset: Offset(-8, height),
      onSelect: () => context.read<ToolbarCubit?>()?.dismiss(),
      child: buildCommandItem(
        MoreOptionCommand.suggestions,
        rightIcon: FlowySvg(FlowySvgs.toolbar_arrow_right_m),
        onTap: () {
          if (tappedCommand == MoreOptionCommand.suggestions) return;
          hideOtherPopovers(MoreOptionCommand.suggestions);
          keepEditorFocusNotifier.increase();
          suggestionsPopoverController.show();
        },
      ),
    );
  }

  Widget buildTextAlignSelector() {
    return TextAlignActionList(
      editorState: editorState,
      popoverController: textAlignPopoverController,
      popoverDirection: PopoverDirection.leftWithTopAligned,
      showOffset: Offset(-8, 0),
      onSelect: () => context.read<ToolbarCubit?>()?.dismiss(),
      highlightColor: highlightColor,
      child: buildCommandItem(
        MoreOptionCommand.textAlign,
        rightIcon: FlowySvg(FlowySvgs.toolbar_arrow_right_m),
        onTap: () {
          if (tappedCommand == MoreOptionCommand.textAlign) return;
          hideOtherPopovers(MoreOptionCommand.textAlign);
          keepEditorFocusNotifier.increase();
          textAlignPopoverController.show();
        },
      ),
    );
  }

  void hideOtherPopovers(MoreOptionCommand currentCommand) {
    if (tappedCommand == currentCommand) return;
    if (tappedCommand == MoreOptionCommand.font) {
      fontPopoverController.close();
      fontPopoverController = PopoverController();
    } else if (tappedCommand == MoreOptionCommand.suggestions) {
      suggestionsPopoverController.close();
      suggestionsPopoverController = PopoverController();
    } else if (tappedCommand == MoreOptionCommand.textAlign) {
      textAlignPopoverController.close();
      textAlignPopoverController = PopoverController();
    }
    tappedCommand = currentCommand;
  }
}

enum MoreOptionCommand {
  suggestions(FlowySvgs.turninto_s),
  link(FlowySvgs.toolbar_link_m),
  textAlign(
    FlowySvgs.toolbar_alignment_m,
  ),
  font(FlowySvgs.type_font_m),
  strikethrough(FlowySvgs.type_strikethrough_m),
  formula(FlowySvgs.type_formula_m);

  const MoreOptionCommand(this.svg);

  final FlowySvgData svg;

  String get title {
    switch (this) {
      case suggestions:
        return LocaleKeys.document_toolbar_turnInto.tr();
      case link:
        return LocaleKeys.document_toolbar_link.tr();
      case textAlign:
        return LocaleKeys.button_align.tr();
      case font:
        return LocaleKeys.document_toolbar_font.tr();
      case strikethrough:
        return LocaleKeys.editor_strikethrough.tr();
      case formula:
        return LocaleKeys.document_toolbar_equation.tr();
    }
  }

  Future<void> onExecute(EditorState editorState, BuildContext context) async {
    final selection = editorState.selection!;
    if (this == link) {
      final nodes = editorState.getNodesInSelection(selection);
      final isHref = nodes.allSatisfyInSelection(selection, (delta) {
        return delta.everyAttributes(
          (attributes) => attributes[AppFlowyRichTextKeys.href] != null,
        );
      });
      context.read<ToolbarCubit?>()?.dismiss();
      if (isHref) {
        getIt<LinkHoverTriggers>().call(
          HoverTriggerKey(nodes.first.id, selection),
        );
      } else {
        showLinkCreateMenu(context, editorState, selection);
      }
    } else if (this == strikethrough) {
      await editorState.toggleAttribute(name);
    } else if (this == formula) {
      final node = editorState.getNodeAtPath(selection.start.path);
      final delta = node?.delta;
      if (node == null || delta == null) {
        return;
      }

      final transaction = editorState.transaction;
      final isHighlight = isFormulaHighlight(editorState);
      if (isHighlight) {
        final formula = delta
            .slice(selection.startIndex, selection.endIndex)
            .whereType<TextInsert>()
            .firstOrNull
            ?.attributes?[InlineMathEquationKeys.formula];
        assert(formula != null);
        if (formula == null) {
          return;
        }
        // clear the format
        transaction.replaceText(
          node,
          selection.startIndex,
          selection.length,
          formula,
          attributes: {},
        );
      } else {
        final text = editorState.getTextInSelection(selection).join();
        transaction.replaceText(
          node,
          selection.startIndex,
          selection.length,
          MentionBlockKeys.mentionChar,
          attributes: {
            InlineMathEquationKeys.formula: text,
          },
        );
      }
      await editorState.apply(transaction);
    }
  }
}

bool isFormulaHighlight(EditorState editorState) {
  final selection = editorState.selection;
  if (selection == null || selection.isCollapsed) {
    return false;
  }
  final node = editorState.getNodeAtPath(selection.start.path);
  final delta = node?.delta;
  if (node == null || delta == null) {
    return false;
  }

  final nodes = editorState.getNodesInSelection(selection);
  return nodes.allSatisfyInSelection(selection, (delta) {
    return delta.everyAttributes(
      (attributes) => attributes[InlineMathEquationKeys.formula] != null,
    );
  });
}
