import 'package:appflowy_editor/appflowy_editor.dart';

extension SelectionColor on EditorState {
  String? getSelectionColor(String key) {
    final selection = this.selection;
    if (selection == null) {
      return null;
    }
    final String? color = toggledStyle[key];
    return color;
  }
}
