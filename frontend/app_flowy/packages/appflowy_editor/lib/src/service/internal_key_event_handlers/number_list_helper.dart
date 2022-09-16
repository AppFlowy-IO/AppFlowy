import 'package:appflowy_editor/src/document/selection.dart';
import 'package:appflowy_editor/src/editor_state.dart';
import 'package:appflowy_editor/src/document/built_in_attribute_keys.dart';
import 'package:appflowy_editor/src/operation/transaction_builder.dart';
import 'package:appflowy_editor/src/document/attributes.dart';

void makeFollowingNodesIncremental(
    EditorState editorState, List<int> insertPath, Selection afterSelection,
    {int? beginNum}) {
  final insertNode = editorState.document.nodeAtPath(insertPath);
  if (insertNode == null) {
    return;
  }
  beginNum ??= insertNode.attributes[BuiltInAttributeKey.number] as int;

  int numPtr = beginNum + 1;
  var ptr = insertNode.next;

  final builder = TransactionBuilder(editorState);

  while (ptr != null) {
    if (ptr.subtype != BuiltInAttributeKey.numberList) {
      break;
    }
    final currentNum = ptr.attributes[BuiltInAttributeKey.number] as int;
    if (currentNum != numPtr) {
      Attributes updateAttributes = {};
      updateAttributes[BuiltInAttributeKey.number] = numPtr;
      builder.updateNode(ptr, updateAttributes);
    }

    ptr = ptr.next;
    numPtr++;
  }

  builder.afterSelection = afterSelection;
  builder.commit();
}
