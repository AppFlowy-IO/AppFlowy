import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/domain/database_view_service.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_block.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';

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

  Future<void> insertReferencePage(
    ViewPB childView,
    ViewLayoutPB viewType,
  ) async {
    final selection = this.selection;
    if (selection == null || !selection.isCollapsed) {
      throw FlowyError(
        msg:
            "Could not insert the reference page because the current selection was null or collapsed.",
      );
    }
    final node = getNodeAtPath(selection.end.path);
    if (node == null) {
      throw FlowyError(
        msg:
            "Could not insert the reference page because the current node at the selection does not exist.",
      );
    }

    final Transaction transaction = viewType == ViewLayoutPB.Document
        ? await _insertDocumentReference(childView, selection, node)
        : await _insertDatabaseReference(childView, selection.end.path);

    await apply(transaction);
  }

  Future<Transaction> _insertDocumentReference(
    ViewPB view,
    Selection selection,
    Node node,
  ) async {
    return transaction
      ..replaceText(
        node,
        selection.end.offset,
        0,
        r'$',
        attributes: {
          MentionBlockKeys.mention: {
            MentionBlockKeys.type: MentionType.page.name,
            MentionBlockKeys.pageId: view.id,
          },
        },
      );
  }

  Future<Transaction> _insertDatabaseReference(
    ViewPB view,
    List<int> path,
  ) async {
    // get the database id that the view is associated with
    final databaseId = await DatabaseViewBackendService(viewId: view.id)
        .getDatabaseId()
        .then((value) => value.toNullable());

    if (databaseId == null) {
      throw StateError(
        'The database associated with ${view.id} could not be found while attempting to create a referenced ${view.layout.name}.',
      );
    }

    final prefix = _referencedDatabasePrefix(view.layout);
    final ref = await ViewBackendService.createDatabaseLinkedView(
      parentViewId: view.id,
      name: "$prefix ${view.name}",
      layoutType: view.layout,
      databaseId: databaseId,
    ).then((value) => value.toNullable());

    if (ref == null) {
      throw FlowyError(
        msg:
            "The `ViewBackendService` failed to create a database reference view",
      );
    }

    return transaction
      ..insertNode(
        path,
        Node(
          type: _convertPageType(view),
          attributes: {
            DatabaseBlockKeys.parentID: view.id,
            DatabaseBlockKeys.viewID: ref.id,
          },
        ),
      );
  }

  String _referencedDatabasePrefix(ViewLayoutPB layout) {
    switch (layout) {
      case ViewLayoutPB.Grid:
        return LocaleKeys.grid_referencedGridPrefix.tr();
      case ViewLayoutPB.Board:
        return LocaleKeys.board_referencedBoardPrefix.tr();
      case ViewLayoutPB.Calendar:
        return LocaleKeys.calendar_referencedCalendarPrefix.tr();
      case ViewLayoutPB.Gallery:
        return LocaleKeys.databaseGallery_referencedGalleryPrefix.tr();
      default:
        throw UnimplementedError();
    }
  }

  String _convertPageType(ViewPB viewPB) {
    switch (viewPB.layout) {
      case ViewLayoutPB.Grid:
        return DatabaseBlockKeys.gridType;
      case ViewLayoutPB.Board:
        return DatabaseBlockKeys.boardType;
      case ViewLayoutPB.Calendar:
        return DatabaseBlockKeys.calendarType;
      case ViewLayoutPB.Gallery:
        return DatabaseBlockKeys.galleryType;
      default:
        throw Exception('Unknown layout type');
    }
  }
}
