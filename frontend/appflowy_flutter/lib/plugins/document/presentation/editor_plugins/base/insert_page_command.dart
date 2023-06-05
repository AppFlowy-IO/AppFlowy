import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/database_view_service.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/board/board_node_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/grid/grid_node_widget.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';

class DatabaseBlockKeys {
  const DatabaseBlockKeys._();

  static const String parentID = 'parent_id';
  static const String viewID = 'view_id';
}

extension InsertDatabase on EditorState {
  Future<void> insertInlinePage(String parentViewId, ViewPB childView) async {
    final selection = this.selection;
    if (selection == null || !selection.isCollapsed) {
      return;
    }
    final node = getNodeAtPath(selection.end.path);
    if (node == null) {
      return;
    }

    final transaction = this.transaction;
    transaction.insertNode(
      selection.end.path,
      Node(
        type: _convertPageType(childView),
        attributes: {
          DatabaseBlockKeys.parentID: parentViewId,
          DatabaseBlockKeys.viewID: childView.id,
        },
      ),
    );
    await apply(transaction);
  }

  Future<void> insertReferencePage(ViewPB childView) async {
    final selection = this.selection;
    if (selection == null || !selection.isCollapsed) {
      return;
    }
    final node = getNodeAtPath(selection.end.path);
    if (node == null) {
      return;
    }

    // get the database id that the view is associated with
    final databaseId = await DatabaseViewBackendService(viewId: childView.id)
        .getDatabaseId()
        .then((value) => value.swap().toOption().toNullable());

    if (databaseId == null) {
      throw StateError(
        'The database associated with ${childView.id} could not be found while attempting to create a referenced ${childView.layout.name}.',
      );
    }

    final prefix = _referencedDatabasePrefix(childView.layout);
    final ref = await ViewBackendService.createDatabaseReferenceView(
      parentViewId: childView.id,
      name: "$prefix ${childView.name}",
      layoutType: childView.layout,
      databaseId: databaseId,
    ).then((value) => value.swap().toOption().toNullable());

    // TODO(a-wallen): Show error dialog here.
    if (ref == null) {
      return;
    }

    final transaction = this.transaction;
    transaction.insertNode(
      selection.end.path,
      Node(
        type: _convertPageType(childView),
        attributes: {
          DatabaseBlockKeys.parentID: childView.id,
          DatabaseBlockKeys.viewID: ref.id,
        },
      ),
    );
    await apply(transaction);
  }

  String _referencedDatabasePrefix(ViewLayoutPB layout) {
    switch (layout) {
      case ViewLayoutPB.Grid:
        return LocaleKeys.grid_referencedGridPrefix.tr();
      case ViewLayoutPB.Board:
        return LocaleKeys.board_referencedBoardPrefix.tr();
      default:
        throw UnimplementedError();
    }
  }

  String _convertPageType(ViewPB viewPB) {
    switch (viewPB.layout) {
      case ViewLayoutPB.Grid:
        return GridBlockKeys.type;
      case ViewLayoutPB.Board:
        return BoardBlockKeys.type;
      default:
        throw Exception('Unknown layout type');
    }
  }
}
