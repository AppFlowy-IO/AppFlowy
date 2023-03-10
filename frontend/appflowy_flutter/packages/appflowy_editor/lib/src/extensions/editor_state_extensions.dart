import 'package:appflowy_editor/appflowy_editor.dart';

extension EditorStateExtensions on EditorState {
  List<TextNode> get selectedTextNodes =>
      service.selectionService.currentSelectedNodes
          .whereType<TextNode>()
          .toList(growable: false);
}
