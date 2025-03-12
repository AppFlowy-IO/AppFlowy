import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

import '../../editor_page.dart';

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
  final fontPopoverController = PopoverController();

  bool isSelected = false;

  EditorState get editorState => widget.editorState;

  Color get highlightColor => widget.highlightColor;

  @override
  void dispose() {
    super.dispose();
    popoverController.close();
    fontPopoverController.close();
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
      hoverColor: AFThemeExtension.of(context).toolbarHoverColor,
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
    return MouseRegion(
      child: SeparatedColumn(
        mainAxisSize: MainAxisSize.min,
        separatorBuilder: () => const VSpace(4.0),
        children: [
          buildFontSelector(),
          buildCommandItem(
            MoreOptionCommand.strikethrough,
            getStrikethroughColor(),
          ),
          if (showFormula)
            buildCommandItem(
              MoreOptionCommand.formula,
              getFormulaColor(),
            ),
        ],
      ),
    );
  }

  Widget buildCommandItem(MoreOptionCommand command, Color? color) {
    return SizedBox(
      height: 36,
      child: FlowyButton(
        key: command == MoreOptionCommand.font
            ? kFontFamilyToolbarItemKey
            : null,
        leftIconSize: const Size.square(20),
        leftIcon: FlowySvg(
          command.svg,
          color: color,
        ),
        iconPadding: 12,
        text: FlowyText(
          command.title,
          figmaLineHeight: 20,
          fontWeight: FontWeight.w400,
          color: color,
        ),
        onTap: () {
          command.onExecute(editorState);
          if (command != MoreOptionCommand.font) {
            popoverController.close();
          }
        },
      ),
    );
  }

  Widget buildFontSelector() {
    final selection = editorState.selection!;
    return FontFamilyDropDown(
      currentFontFamily: '',
      offset: const Offset(-240, 0),
      popoverController: fontPopoverController,
      onOpen: () => keepEditorFocusNotifier.increase(),
      onClose: () => keepEditorFocusNotifier.decrease(),
      onFontFamilyChanged: (fontFamily) async {
        fontPopoverController.close();
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
      child: buildCommandItem(MoreOptionCommand.font, null),
    );
  }
}

enum MoreOptionCommand {
  font(FlowySvgs.type_font_m),
  strikethrough(FlowySvgs.type_strikethrough_m),
  formula(FlowySvgs.type_formula_m);

  const MoreOptionCommand(this.svg);

  final FlowySvgData svg;

  String get title {
    switch (this) {
      case font:
        return LocaleKeys.document_toolbar_font.tr();
      case strikethrough:
        return LocaleKeys.editor_strikethrough.tr();
      case formula:
        return LocaleKeys.editor_mathEquationShortForm.tr();
    }
  }

  Future<void> onExecute(EditorState editorState) async {
    if (this == strikethrough) {
      await editorState.toggleAttribute(name);
    } else if (this == formula) {
      final selection = editorState.selection;
      if (selection == null || selection.isCollapsed) {
        return;
      }
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
