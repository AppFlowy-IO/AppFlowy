import 'dart:collection';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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

  StateTree get document => _editorState.document;
  int get documentLength => _editorState.document.root.children.length;
  Selection? get documentSelection =>
      _editorState.service.selectionService.currentSelection.value;

  Future<EditorWidgetTester> startTesting({
    Locale locale = const Locale('en'),
  }) async {
    final app = MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        AppFlowyEditorLocalizations.delegate,
      ],
      supportedLocales: AppFlowyEditorLocalizations.delegate.supportedLocales,
      locale: locale,
      home: Scaffold(
        body: AppFlowyEditor(
          editorState: _editorState,
          editorStyle: EditorStyle.defaultStyle(),
        ),
      ),
    );
    await tester.pumpWidget(app);
    await tester.pump();
    return this;
  }

  void initialize() {
    _editorState = _createEmptyDocument();
  }

  void insert<T extends Node>(T node) {
    _editorState.document.root.insert(node);
  }

  void insertEmptyTextNode() {
    insert(TextNode.empty());
  }

  void insertTextNode(String? text, {Attributes? attributes, Delta? delta}) {
    insert(
      TextNode(
        delta: delta ?? Delta(operations: [TextInsert(text ?? 'Test')]),
        attributes: attributes,
      ),
    );
  }

  void insertImageNode(String src, {String? align}) {
    insert(
      Node(
        type: 'image',
        children: LinkedList(),
        attributes: {
          'image_src': src,
          'align': align ?? 'center',
        },
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
    await tester.pump(const Duration(milliseconds: 200));

    expect(_editorState.service.selectionService.currentSelection.value,
        selection);
  }

  Future<void> insertText(TextNode textNode, String text, int offset,
      {Selection? selection}) async {
    await apply([
      TextEditingDeltaInsertion(
        oldText: textNode.toPlainText(),
        textInserted: text,
        insertionOffset: offset,
        selection: selection != null
            ? TextSelection(
                baseOffset: selection.start.offset,
                extentOffset: selection.end.offset)
            : TextSelection.collapsed(offset: offset),
        composing: TextRange.empty,
      )
    ]);
  }

  Future<void> apply(List<TextEditingDelta> deltas) async {
    _editorState.service.inputService?.apply(deltas);
    await tester.pumpAndSettle();
  }

  Future<void> pressLogicKey(
    LogicalKeyboardKey key, {
    bool isControlPressed = false,
    bool isShiftPressed = false,
    bool isAltPressed = false,
    bool isMetaPressed = false,
  }) async {
    if (!isControlPressed &&
        !isShiftPressed &&
        !isAltPressed &&
        !isMetaPressed) {
      await tester.sendKeyDownEvent(key);
    } else {
      final testRawKeyEventData = TestRawKeyEventData(
        logicalKey: key,
        isControlPressed: isControlPressed,
        isShiftPressed: isShiftPressed,
        isAltPressed: isAltPressed,
        isMetaPressed: isMetaPressed,
      ).toKeyEvent;
      _editorState.service.keyboardService!.onKey(testRawKeyEventData);
    }
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

extension TestString on String {
  String safeSubString([int start = 0, int? end]) {
    end ??= length - 1;
    end = end.clamp(start, length - 1);
    final sRunes = runes;
    return String.fromCharCodes(sRunes, start, end);
  }
}

extension TestEditorExtension on WidgetTester {
  EditorWidgetTester get editor =>
      EditorWidgetTester(tester: this)..initialize();
  EditorState get editorState => editor.editorState;
}
