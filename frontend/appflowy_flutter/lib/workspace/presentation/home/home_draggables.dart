import 'package:appflowy/workspace/application/panes/panes.dart';
import 'package:appflowy/workspace/application/tabs/tabs.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';

enum CrossDraggableType { view, tab, pane, none }

class TabNode {
  final Tabs tabs;
  final PageManager pageManager;

  TabNode(this.tabs, this.pageManager);
}

class CrossDraggablesEntity {
  late final dynamic draggable;
  late final CrossDraggableType crossDraggableType;

  CrossDraggablesEntity({
    required dynamic draggable,
  }) {
    if (draggable is ViewPB) {
      this.draggable = draggable;
      crossDraggableType = CrossDraggableType.view;
    } else if (draggable is PaneNode) {
      this.draggable = draggable;
      crossDraggableType = CrossDraggableType.pane;
    } else if (draggable is TabNode) {
      this.draggable = draggable;
      crossDraggableType = CrossDraggableType.tab;
    } else {
      this.draggable = null;
      crossDraggableType = CrossDraggableType.none;
    }
  }
}

// abstract class CrossDraggablesEntity {}

// class DraggableViewEntity extends CrossDraggablesEntity {
//   ViewPB view;
//   DraggableViewEntity({required this.view});
// }

// class DraggablePaneEntity extends CrossDraggablesEntity {
//   PaneNode paneNode;
//   DraggablePaneEntity({required this.paneNode});
// }

// class DraggableTabEntity extends CrossDraggablesEntity {
//   final PageManager pageManager;
//   final Tabs tabs;

//   DraggableTabEntity(this.tabs, this.pageManager);
// }
