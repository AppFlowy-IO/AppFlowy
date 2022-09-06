import 'package:appflowy_editor/src/document/selection.dart';
import 'package:appflowy_editor/src/editor_state.dart';
import 'package:appflowy_editor/src/render/rich_text/rich_text_style.dart';
import 'package:appflowy_editor/src/operation/transaction_builder.dart';
import 'package:appflowy_editor/src/document/attributes.dart';

void makeFollowingNodesIncremental(
    EditorState editorState, List<int> insertPath, Selection afterSelection) {
  final insertNode = editorState.document.nodeAtPath(insertPath);
  if (insertNode == null) {
    return;
  }
  final int beginNum = insertNode.attributes[StyleKey.number] as int;

  int numPtr = beginNum + 1;
  var ptr = insertNode.next;

  final builder = TransactionBuilder(editorState);

  while (ptr != null) {
    if (ptr.subtype != StyleKey.numberList) {
      break;
    }
    final currentNum = ptr.attributes[StyleKey.number] as int;
    if (currentNum != numPtr) {
      Attributes updateAttributes = {};
      updateAttributes[StyleKey.number] = numPtr;
      builder.updateNode(ptr, updateAttributes);
    }

    ptr = ptr.next;
    numPtr++;
  }

  builder.afterSelection = afterSelection;
  builder.commit();
}
