import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/desktop_toolbar/link/link_styles.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/toolbar_item/custom_link_toolbar_item.dart';
import 'package:appflowy/plugins/shared/share/constants.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'link_search_text_field.dart';

class LinkCreateMenu extends StatefulWidget {
  const LinkCreateMenu({
    super.key,
    required this.editorState,
    required this.onSubmitted,
    required this.onDismiss,
    required this.alignment,
  });

  final EditorState editorState;
  final void Function(String link, bool isPage) onSubmitted;
  final VoidCallback onDismiss;
  final LinkMenuAlignment alignment;

  @override
  State<LinkCreateMenu> createState() => _LinkCreateMenuState();
}

class _LinkCreateMenuState extends State<LinkCreateMenu> {
  late LinkSearchTextField searchTextField = LinkSearchTextField(
    onEnter: () {
      searchTextField.onSearchResult(
        onLink: () => onSubmittedLink(),
        onRecentViews: () =>
            onSubmittedPageLink(searchTextField.currentRecentView),
        onSearchViews: () =>
            onSubmittedPageLink(searchTextField.currentSearchedView),
        onEmpty: () {},
      );
    },
    onEscape: widget.onDismiss,
    onDataRefresh: () {
      if (mounted) setState(() {});
    },
  );

  bool get isButtonEnable => searchText.isNotEmpty;

  String get searchText => searchTextField.searchText;

  bool get showAtTop => widget.alignment.isTop;

  @override
  void initState() {
    super.initState();
    searchTextField.requestFocus();
    searchTextField.searchRecentViews();
  }

  @override
  void dispose() {
    searchTextField.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: Column(
        children: showAtTop
            ? [
                searchTextField.buildResultContainer(
                  margin: EdgeInsets.only(bottom: 2),
                  context: context,
                  onLinkSelected: onSubmittedLink,
                  onPageLinkSelected: onSubmittedPageLink,
                ),
                buildSearchContainer(),
              ]
            : [
                buildSearchContainer(),
                searchTextField.buildResultContainer(
                  margin: EdgeInsets.only(top: 2),
                  context: context,
                  onLinkSelected: onSubmittedLink,
                  onPageLinkSelected: onSubmittedPageLink,
                ),
              ],
      ),
    );
  }

  Widget buildSearchContainer() {
    return Container(
      width: 320,
      height: 48,
      decoration: buildToolbarLinkDecoration(context),
      padding: EdgeInsets.all(8),
      child: ValueListenableBuilder(
        valueListenable: searchTextField.textEditingController,
        builder: (context, _, __) {
          return Row(
            children: [
              Expanded(child: searchTextField.buildTextField()),
              HSpace(8),
              FlowyTextButton(
                LocaleKeys.document_toolbar_insert.tr(),
                mainAxisAlignment: MainAxisAlignment.center,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(maxWidth: 72, minHeight: 32),
                fontSize: 14,
                fontColor:
                    isButtonEnable ? Colors.white : LinkStyle.textTertiary,
                fillColor: isButtonEnable
                    ? LinkStyle.fillThemeThick
                    : LinkStyle.borderColor,
                hoverColor: LinkStyle.fillThemeThick,
                lineHeight: 20 / 14,
                fontWeight: FontWeight.w600,
                onPressed: isButtonEnable ? () => onSubmittedLink() : null,
              ),
            ],
          );
        },
      ),
    );
  }

  void onSubmittedLink() => widget.onSubmitted(searchText, false);

  void onSubmittedPageLink(ViewPB view) async {
    final workspaceId = context
            .read<UserWorkspaceBloc?>()
            ?.state
            .currentWorkspace
            ?.workspaceId ??
        '';
    final link = ShareConstants.buildShareUrl(
      workspaceId: workspaceId,
      viewId: view.id,
    );
    widget.onSubmitted(link, true);
  }
}

void showLinkCreateMenu(
  BuildContext context,
  EditorState editorState,
  Selection selection,
) {
  final (left, top, right, bottom, alignment) = _getPosition(editorState);

  final node = editorState.getNodeAtPath(selection.end.path);
  if (node == null) {
    return;
  }

  OverlayEntry? overlay;

  void dismissOverlay() {
    keepEditorFocusNotifier.decrease();
    overlay?.remove();
    overlay = null;
  }

  keepEditorFocusNotifier.increase();
  overlay = FullScreenOverlayEntry(
    top: top,
    bottom: bottom,
    left: left,
    right: right,
    dismissCallback: () => keepEditorFocusNotifier.decrease(),
    builder: (context) {
      return LinkCreateMenu(
        alignment: alignment,
        editorState: editorState,
        onSubmitted: (link, isPage) async {
          await editorState.formatDelta(selection, {
            BuiltInAttributeKey.href: link,
            kIsPageLink: isPage,
          });
          dismissOverlay();
        },
        onDismiss: dismissOverlay,
      );
    },
  ).build();

  Overlay.of(context, rootOverlay: true).insert(overlay!);
}

// get a proper position for link menu
(
  double? left,
  double? top,
  double? right,
  double? bottom,
  LinkMenuAlignment alignment,
) _getPosition(
  EditorState editorState,
) {
  final rect = editorState.selectionRects().first;
  const menuHeight = 222.0, menuWidth = 320.0;

  double? left, right, top, bottom;
  LinkMenuAlignment alignment = LinkMenuAlignment.topLeft;
  final editorOffset = editorState.renderBox!.localToGlobal(Offset.zero),
      editorSize = editorState.renderBox!.size;
  final editorBottom = editorSize.height + editorOffset.dy,
      editorRight = editorSize.width + editorOffset.dx;
  final overflowBottom = rect.bottom + menuHeight > editorBottom,
      overflowTop = rect.top - menuHeight < 0,
      overflowLeft = rect.left - menuWidth < 0,
      overflowRight = rect.right + menuWidth > editorRight;

  if (overflowTop && !overflowBottom) {
    /// show at bottom
    top = rect.bottom;
  } else if (overflowBottom && !overflowTop) {
    /// show at top
    bottom = editorBottom - rect.top;
  } else if (!overflowTop && !overflowBottom) {
    /// show at bottom
    top = rect.bottom;
  } else {
    top = 0;
  }

  if (overflowLeft && !overflowRight) {
    /// show at right
    left = rect.left;
  } else if (overflowRight && !overflowLeft) {
    /// show at left
    right = editorRight - rect.right;
  } else if (!overflowLeft && !overflowRight) {
    /// show at right
    left = rect.left;
  } else {
    left = 0;
  }

  if (left != null && top != null) {
    alignment = LinkMenuAlignment.bottomRight;
  } else if (left != null && bottom != null) {
    alignment = LinkMenuAlignment.topRight;
  } else if (right != null && top != null) {
    alignment = LinkMenuAlignment.bottomLeft;
  } else if (right != null && bottom != null) {
    alignment = LinkMenuAlignment.topLeft;
  }

  return (left, top, right, bottom, alignment);
}

ShapeDecoration buildToolbarLinkDecoration(BuildContext context) =>
    ShapeDecoration(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      shadows: [
        const BoxShadow(
          color: LinkStyle.shadowMedium,
          blurRadius: 24,
          offset: Offset(0, 4),
        ),
      ],
    );
