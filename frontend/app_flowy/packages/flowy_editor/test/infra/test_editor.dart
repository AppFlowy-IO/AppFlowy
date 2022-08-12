import 'dart:collection';

import 'package:flowy_editor/flowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_raw_key_event.dart';

class EditorWidgetTester {
  EditorWidgetTester({
    required this.tester,
  });

  final WidgetTester tester;
  late EditorState _editorState;

  EditorState get editorState => _editorState;
  Node get root => _editorState.document.root;

  int get documentLength => _editorState.document.root.children.length;
  Selection? get documentSelection =>
      _editorState.service.selectionService.currentSelection.value;

  Future<EditorWidgetTester> startTesting() async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlowyEditor(
            editorState: _editorState,
          ),
        ),
      ),
    );
    return this;
  }

  void initialize() {
    _editorState = _createEmptyDocument();
  }

  insert<T extends Node>(T node) {
    _editorState.document.root.insert(node);
  }

  insertEmptyTextNode() {
    insert(TextNode.empty());
  }

  insertTextNode({String? text, Attributes? attributes}) {
    insert(
      TextNode(
        type: 'text',
        delta: Delta(
          [TextInsert(text ?? 'Test')],
        ),
        attributes: attributes,
      ),
    );
  }

  Node? nodeAtPath(Path path) {
    return root.childAtPath(path);
  }

  Future<void> updateSelection(Selection? selection) async {
    if (selection == null) {
      _editorState.service.selectionService.clearSelection();
    } else {
      _editorState.service.selectionService.updateSelection(selection);
    }
    await tester.pumpAndSettle();
  }

  Future<void> pressLogicKey(LogicalKeyboardKey key) async {
    late RawKeyEvent testRawKeyEventData;
    if (key == LogicalKeyboardKey.enter) {
      testRawKeyEventData = const TestRawKeyEventData(
        logicalKey: LogicalKeyboardKey.enter,
        physicalKey: PhysicalKeyboardKey.enter,
      ).toKeyEvent;
    }
    _editorState.service.keyboardService!.onKey(testRawKeyEventData);
    await tester.pumpAndSettle();
  }

  Node _createEmptyEditorRoot() {
    return Node(
      type: 'editor',
      children: LinkedList(),
      attributes: {},
    );
  }

  EditorState _createEmptyDocument() {
    return EditorState(
      document: StateTree(
        root: _createEmptyEditorRoot(),
      ),
    )..disableSealTimer = true;
  }
}

extension TestEditorExtension on WidgetTester {
  EditorWidgetTester get editor => EditorWidgetTester(tester: this);
  EditorState get editorState => editor.editorState;
}
