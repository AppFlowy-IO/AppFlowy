import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/database_view_service.dart';
import 'package:appflowy/plugins/document/presentation/plugins/board/board_node_widget.dart';
import 'package:appflowy/plugins/document/presentation/plugins/grid/grid_node_widget.dart';
import 'package:appflowy/workspace/application/app/app_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/app.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';

const String kAppID = 'app_id';
const String kViewID = 'view_id';

extension InsertPage on EditorState {
  Future<void> insertPage(AppPB appPB, ViewPB viewPB) async {
    final selection = service.selectionService.currentSelection.value;
    final textNodes =
        service.selectionService.currentSelectedNodes.whereType<TextNode>();
    if (selection == null || textNodes.isEmpty) {
      return;
    }

    // get the database that the view is associated with
    final database =
        await DatabaseViewBackendService(viewId: viewPB.id).openGrid().then(
              (value) => value.getLeftOrNull(),
            );

    if (database == null) {
      throw StateError(
          'The database associated with ${viewPB.id} could not be found while attempting to create a referenced ${viewPB.layout.name}.');
    }

    final prefix = referencedBoardPrefix(viewPB.layout);

    final ref = await AppBackendService().createView(
      appId: appPB.id,
      name: "$prefix ${viewPB.name}",
      desc: appPB.desc,
      layoutType: viewPB.layout,
      ext: {
        'database_id': database.id,
      },
    ).then(
      (value) => value.getLeftOrNull(),
    );

    // TODO(a-wallen): Show error dialog here.
    if (ref == null) {
      return;
    }

    final transaction = this.transaction;
    transaction.insertNode(
      selection.end.path,
      Node(
        type: _convertPageType(viewPB),
        attributes: {
          kAppID: appPB.id,
          kViewID: ref.id,
        },
      ),
    );
    apply(transaction);
  }

  String referencedBoardPrefix(ViewLayoutTypePB layout) {
    switch (layout) {
      case ViewLayoutTypePB.Grid:
        return LocaleKeys.grid_referencedGridPrefix.tr();
      case ViewLayoutTypePB.Board:
        return LocaleKeys.board_referencedBoardPrefix.tr();
      default:
        throw UnimplementedError();
    }
  }

  String _convertPageType(ViewPB viewPB) {
    switch (viewPB.layout) {
      case ViewLayoutTypePB.Grid:
        return kGridType;
      case ViewLayoutTypePB.Board:
        return kBoardType;
      default:
        throw Exception('Unknown layout type');
    }
  }
}
