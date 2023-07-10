import 'package:appflowy/plugins/document/presentation/editor_plugins/base/selectable_svg_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_page_block.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

enum MentionType {
  page;

  static MentionType fromString(String value) {
    switch (value) {
      case 'page':
        return page;
      default:
        throw UnimplementedError();
    }
  }
}

class MentionBlockKeys {
  const MentionBlockKeys._();

  static const mention = 'mention';
  static const type = 'type'; // MentionType, String
  static const pageId = 'page_id';
}

class InlinePageReferenceService {
  customPageLinkMenu({
    bool shouldInsertKeyword = false,
    SelectionMenuStyle style = SelectionMenuStyle.light,
    String character = '@',
  }) {
    return CharacterShortcutEvent(
      key: 'show page link menu',
      character: character,
      handler: (editorState) async {
        final items = await generatePageItems(character);
        return _showPageSelectionMenu(
          editorState,
          items,
          shouldInsertKeyword: shouldInsertKeyword,
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
    bool shouldInsertKeyword = true,
    SelectionMenuStyle style = SelectionMenuStyle.light,
    String character = '@',
  }) async {
    if (PlatformExtension.isMobile) {
      return false;
    }

    final selection = editorState.selection;
    if (selection == null) {
      return false;
    }

    // delete the selection
    await editorState.deleteSelection(selection);

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
    final service = ViewBackendService();
    final List<(ViewPB, List<ViewPB>)> pbViews = await service.fetchViews(
      (_, __) => true,
    );
    if (pbViews.isEmpty) {
      return [];
    }
    final List<SelectionMenuItem> pages = [];
    final List<ViewPB> views = [];
    for (final element in pbViews) {
      views.addAll(element.$2);
    }
    views.sort(((a, b) => b.createTime.compareTo(a.createTime)));

    for (final view in views) {
      final SelectionMenuItem pageSelectionMenuItem = SelectionMenuItem(
        icon: (editorState, isSelected, style) => SelectableSvgWidget(
          name: view.iconName,
          isSelected: isSelected,
          style: style,
        ),
        keywords: [
          view.name.toLowerCase(),
        ],
        name: view.name,
        handler: (editorState, menuService, context) async {
          final selection = editorState.selection;
          if (selection == null || !selection.isCollapsed) {
            return;
          }
          final node = editorState.getNodeAtPath(selection.end.path);
          final delta = node?.delta;
          if (node == null || delta == null) {
            return;
          }
          final index = selection.endIndex;
          final lastKeywordIndex =
              delta.toPlainText().substring(0, index).lastIndexOf(character);
          // @page name -> $
          // preload the page infos
          pageMemorizer[view.id] = view;
          final transaction = editorState.transaction
            ..replaceText(
              node,
              lastKeywordIndex,
              index - lastKeywordIndex,
              '\$',
              attributes: {
                MentionBlockKeys.mention: {
                  MentionBlockKeys.type: MentionType.page.name,
                  MentionBlockKeys.pageId: view.id,
                }
              },
            );
          await editorState.apply(transaction);
        },
      );
      pages.add(pageSelectionMenuItem);
    }

    return pages;
  }
}
