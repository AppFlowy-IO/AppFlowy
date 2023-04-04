import 'package:appflowy/plugins/document/presentation/plugins/board/board_node_widget.dart';
import 'package:appflowy/plugins/document/presentation/plugins/grid/grid_node_widget.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

const String kAppID = 'app_id';
const String kViewID = 'view_id';

extension InsertPage on EditorState {
  void insertPage(ViewPB appPB, ViewPB viewPB) {
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
      case ViewLayoutPB.Grid:
        return kGridType;
      case ViewLayoutPB.Board:
        return kBoardType;
      default:
        throw Exception('Unknown layout type');
    }
  }
}
