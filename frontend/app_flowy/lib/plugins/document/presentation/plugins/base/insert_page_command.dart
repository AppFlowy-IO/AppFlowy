import 'package:app_flowy/plugins/document/presentation/plugins/board/board_node_widget.dart';
import 'package:app_flowy/plugins/document/presentation/plugins/grid/grid_node_widget.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/app.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

const String kAppID = 'app_id';
const String kViewID = 'view_id';

extension InsertPage on EditorState {
  void insertPage(AppPB appPB, ViewPB viewPB) {
    final selection = service.selectionService.currentSelection.value;
    final textNodes =
        service.selectionService.currentSelectedNodes.whereType<TextNode>();
    if (selection == null || textNodes.isEmpty) {
      return;
    }
    final transaction = this.transaction;
    transaction.insertNode(
      selection.end.path,
      Node(
        type: _convertPageType(viewPB),
        attributes: {
          kAppID: appPB.id,
          kViewID: viewPB.id,
        },
      ),
    );
    apply(transaction);
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
