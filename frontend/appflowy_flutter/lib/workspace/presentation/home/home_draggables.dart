import 'package:appflowy/workspace/application/panes/panes.dart';
import 'package:appflowy/workspace/application/tabs/tabs_controller.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';

enum CrossDraggableType { view, tab, pane, none }

class TabNode {
  const TabNode(this.tabs, this.pageManager);

  final TabsController tabs;
  final PageManager pageManager;
}

class CrossDraggablesEntity {
  late final dynamic draggable;
  late final CrossDraggableType crossDraggableType;

  CrossDraggablesEntity({required dynamic draggable}) {
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
