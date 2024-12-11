import 'package:appflowy_editor/appflowy_editor.dart';

class DocumentValidator {
  const DocumentValidator({
    required this.editorState,
    required this.rules,
  });

  final EditorState editorState;
  final List<DocumentRule> rules;

  Future<bool> validate(Transaction transaction) async {
    // deep copy the document
    final root = this.editorState.document.root.copyWith();
    final dummyDocument = Document(root: root);
    if (dummyDocument.isEmpty) {
      return true;
    }

    final editorState = EditorState(document: dummyDocument);
    await editorState.apply(transaction);

    final iterator = NodeIterator(
      document: editorState.document,
      startNode: editorState.document.root,
    );

    for (final rule in rules) {
      while (iterator.moveNext()) {
        if (!rule.validate(iterator.current)) {
          return false;
        }
      }
    }

    return true;
  }

  Future<bool> applyTransactionInDummyDocument(Transaction transaction) async {
    // deep copy the document
    final root = this.editorState.document.root.copyWith();
    final dummyDocument = Document(root: root);
    if (dummyDocument.isEmpty) {
      return true;
    }

    final editorState = EditorState(document: dummyDocument);
    await editorState.apply(transaction);

    final iterator = NodeIterator(
      document: editorState.document,
      startNode: editorState.document.root,
    );

    for (final rule in rules) {
      while (iterator.moveNext()) {
        if (!rule.validate(iterator.current)) {
          return false;
        }
      }
    }

    return true;
  }
}

class DocumentRule {
  const DocumentRule({
    required this.type,
  });

  final String type;

  bool validate(Node node) {
    return true;
  }
}
