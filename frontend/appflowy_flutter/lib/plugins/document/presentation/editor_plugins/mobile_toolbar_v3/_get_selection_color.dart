import 'package:appflowy_editor/appflowy_editor.dart';

extension SelectionColor on EditorState {
  String? getSelectionColor(String key) {
    final selection = this.selection;
    if (selection == null) {
      return null;
    }
    String? color = toggledStyle[key];
    if (color == null) {
      if (selection.isCollapsed && selection.startIndex != 0) {
        color = getDeltaAttributeValueInSelection<String>(
          key,
          selection.copyWith(
            start: selection.start.copyWith(
              offset: selection.startIndex - 1,
            ),
          ),
        );
      } else {
        color = getDeltaAttributeValueInSelection<String>(
          key,
        );
      }
    }
    return color;
  }
}
