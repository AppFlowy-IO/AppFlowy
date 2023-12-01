import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_item/utils.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final customTextDecorationMobileToolbarItem = MobileToolbarItem.withMenu(
  itemIconBuilder: (_, __, ___) => const FlowySvg(
    FlowySvgs.text_s,
    size: Size.square(24),
  ),
  itemMenuBuilder: (_, editorState, service) {
    final selection = editorState.selection;
    if (selection == null) {
      return const SizedBox.shrink();
    }
    return _TextDecorationMenu(
      editorState,
      selection,
      service,
    );
  },
);

class _TextDecorationMenu extends StatefulWidget {
  const _TextDecorationMenu(
    this.editorState,
    this.selection,
    this.service,
  );

  final EditorState editorState;
  final Selection selection;
  final MobileToolbarWidgetService service;

  @override
  State<_TextDecorationMenu> createState() => _TextDecorationMenuState();
}

class _TextDecorationMenuState extends State<_TextDecorationMenu> {
  EditorState get editorState => widget.editorState;

  final textDecorations = [
    // BIUS
    TextDecorationUnit(
      icon: AFMobileIcons.bold,
      label: AppFlowyEditorL10n.current.bold,
      name: AppFlowyRichTextKeys.bold,
    ),
    TextDecorationUnit(
      icon: AFMobileIcons.italic,
      label: AppFlowyEditorL10n.current.italic,
      name: AppFlowyRichTextKeys.italic,
    ),
    TextDecorationUnit(
      icon: AFMobileIcons.underline,
      label: AppFlowyEditorL10n.current.underline,
      name: AppFlowyRichTextKeys.underline,
    ),
    TextDecorationUnit(
      icon: AFMobileIcons.strikethrough,
      label: AppFlowyEditorL10n.current.strikethrough,
      name: AppFlowyRichTextKeys.strikethrough,
    ),

    // Code
    TextDecorationUnit(
      icon: AFMobileIcons.code,
      label: AppFlowyEditorL10n.current.embedCode,
      name: AppFlowyRichTextKeys.code,
    ),

    // link
    TextDecorationUnit(
      icon: AFMobileIcons.link,
      label: AppFlowyEditorL10n.current.link,
      name: AppFlowyRichTextKeys.href,
    ),
  ];

  @override
  void dispose() {
    widget.editorState.selectionExtraInfo = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final children = textDecorations
        .map((currentDecoration) {
          // Check current decoration is active or not
          final selection = widget.selection;

          // only show edit link bottom sheet when selection is not collapsed
          if (selection.isCollapsed &&
              currentDecoration.name == AppFlowyRichTextKeys.href) {
            return null;
          }

          final nodes = editorState.getNodesInSelection(selection);
          final bool isSelected;
          if (selection.isCollapsed) {
            isSelected = editorState.toggledStyle.containsKey(
              currentDecoration.name,
            );
          } else {
            isSelected = nodes.allSatisfyInSelection(selection, (delta) {
              return delta.everyAttributes(
                (attributes) => attributes[currentDecoration.name] == true,
              );
            });
          }

          return MobileToolbarItemMenuBtn(
            icon: AFMobileIcon(
              afMobileIcons: currentDecoration.icon,
              color: MobileToolbarTheme.of(context).iconColor,
            ),
            label: FlowyText(currentDecoration.label),
            isSelected: isSelected,
            onPressed: () {
              if (currentDecoration.name == AppFlowyRichTextKeys.href) {
                if (selection.isCollapsed) {
                  return;
                }

                _closeKeyboard();

                // show edit link bottom sheet
                final context = nodes.firstOrNull?.context;
                if (context != null) {
                  final text = editorState
                      .getTextInSelection(
                        widget.selection,
                      )
                      .join('');
                  final href =
                      editorState.getDeltaAttributeValueInSelection<String>(
                    AppFlowyRichTextKeys.href,
                    widget.selection,
                  );
                  showEditLinkBottomSheet(
                    context,
                    text,
                    href,
                    (context, newText, newHref) {
                      _updateTextAndHref(text, href, newText, newHref);
                      context.pop();
                    },
                  );
                }
              } else {
                setState(() {
                  editorState.toggleAttribute(currentDecoration.name);
                });
              }
            },
          );
        })
        .nonNulls
        .toList();

    return GridView.count(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 4,
      children: children,
    );
  }

  void _closeKeyboard() {
    editorState.updateSelectionWithReason(
      widget.selection,
      extraInfo: {
        disableMobileToolbarKey: true,
      },
    );
    editorState.service.keyboardService?.closeKeyboard();
  }

  void _updateTextAndHref(
    String prevText,
    String? prevHref,
    String text,
    String href,
  ) async {
    final selection = widget.selection;
    if (!selection.isSingle) {
      return;
    }
    final node = editorState.getNodeAtPath(selection.start.path);
    if (node == null) {
      return;
    }
    final transaction = editorState.transaction;
    if (prevText != text) {
      transaction.replaceText(
        node,
        selection.startIndex,
        selection.length,
        text,
      );
    }
    // if the text is empty, it means the user wants to remove the text
    if (text.isNotEmpty && prevHref != href) {
      transaction.formatText(node, selection.startIndex, text.length, {
        AppFlowyRichTextKeys.href: href.isEmpty ? null : href,
      });
    }
    await editorState.apply(transaction);
  }
}
