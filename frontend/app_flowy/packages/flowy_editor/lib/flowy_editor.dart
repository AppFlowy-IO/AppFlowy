library flowy_editor;

import 'package:flowy_editor/document/state_tree.dart';

class Example {
  StateTree createStateTree(Map<String, Object> json) {
    return StateTree.fromJson(json);
  }
}
