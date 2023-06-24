import 'package:appflowy/plugins/document/presentation/editor_plugins/base/selectable_svg_widget.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

class InlinePageReferenceService {
  customPageLinkMenu({
    bool shouldInsertSlash = false,
    SelectionMenuStyle style = SelectionMenuStyle.light,
    String character = "@",
  }) {
    return CharacterShortcutEvent(
      key: 'show page link menu',
      character: character,
      handler: (editorState) async {
        final items = await generatePageItems(character);
        return _showPageSelectionMenu(
          editorState,
          items,
          shouldInsertSlash: shouldInsertSlash,
          style: style,
          character: character,
        );
      },
    );
  }

  SelectionMenuService? _selectionMenuService;
  Future<bool> _showPageSelectionMenu(
    EditorState editorState,
    List<SelectionMenuItem> items, {
    bool shouldInsertSlash = true,
    SelectionMenuStyle style = SelectionMenuStyle.light,
    String character = "@",
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
    await editorState.insertTextAtPosition(
      character,
      position: selection.start,
    );

    () {
      final context = editorState.getNodeAtPath(selection.start.path)?.context;
      if (context != null) {
        _selectionMenuService = SelectionMenu(
          context: context,
          editorState: editorState,
          selectionMenuItems: items,
          deleteSlashByDefault: false,
          style: style,
          itemCountFilter: 5,
        );
        _selectionMenuService?.show();
      }
    }();

    return true;
  }

  Future<List<SelectionMenuItem>> generatePageItems(String character) async {
    final List<SelectionMenuItem> pages = [];
    final List<(ViewPB, List<ViewPB>)> pbViews = [];
    final List<ViewPB> views = [];
    pbViews
        .addAll(await ViewBackendService().fetchViews(ViewLayoutPB.Document));
    pbViews.addAll(await ViewBackendService().fetchViews(ViewLayoutPB.Board));
    pbViews.addAll(await ViewBackendService().fetchViews(ViewLayoutPB.Grid));
    pbViews
        .addAll(await ViewBackendService().fetchViews(ViewLayoutPB.Calendar));
    if (pbViews.isNotEmpty) {
      for (final element in pbViews) {
        views.addAll(element.$2);
      }
      views.sort(((a, b) => b.createTime.compareTo(a.createTime)));
      for (int i = 0; i < views.length; i++) {
        final SelectionMenuItem pageSelectionMenuItem = SelectionMenuItem(
          icon: (editorState, isSelected, style) => SelectableSvgWidget(
            name: 'editor/${_getIconName(views[i])}',
            isSelected: isSelected,
            style: style,
          ),
          keywords: [
            views[i].name.toLowerCase(),
          ],
          name: views[i].name.toString(),
          handler: (editorState, menuService, context) async {
            await _deleteCharacter(editorState, character);

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
                  ..insertText(
                    node,
                    index,
                    "\$",
                    attributes: {
                      "mention": {
                        "id": views[i].id,
                        "handler": views[i].name,
                        "view": views[i].writeToJson(),
                      }
                    },
                  );

                await editorState.apply(transaction);
              }
            }
          },
        );
        pages.add(pageSelectionMenuItem);
      }
    }

    return pages;
  }

  Future<void> _deleteCharacter(
    EditorState editorState,
    String character,
  ) async {
    final selection = editorState.selection;
    if (selection == null || !selection.isCollapsed) {
      return;
    }
    final node = editorState.getNodeAtPath(selection.end.path);
    final delta = node?.delta;
    if (node == null || delta == null) {
      return;
    }
    final end = selection.start.offset;
    final lastSlashIndex =
        delta.toPlainText().substring(0, end).lastIndexOf(character);
    // delete all the texts after '/' along with '/'
    final transaction = editorState.transaction
      ..deleteText(
        node,
        lastSlashIndex,
        end - lastSlashIndex,
      );

    await editorState.apply(transaction);
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
}
