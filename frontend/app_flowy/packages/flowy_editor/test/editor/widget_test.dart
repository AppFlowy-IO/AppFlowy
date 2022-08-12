import 'dart:convert';
import 'dart:io';

import 'package:flowy_editor/flowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../infra/test_raw_key_event.dart';

void main() async {
  final file = File('test_assets/example.json');
  final json = jsonDecode(await file.readAsString());
  print(json);

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('init FlowyEditor ', (tester) async {
    final editorState = EditorState(
      document: StateTree.fromJson(json),
    );
    final flowyEditor = FlowyEditor(editorState: editorState);
    await tester.pumpWidget(MaterialApp(
      home: flowyEditor,
    ));
    editorState.service.selectionService
        .updateSelection(Selection.collapsed(Position(path: [0], offset: 1)));
    await tester.pumpAndSettle();
    final key = const TestRawKeyEventData(
      logicalKey: LogicalKeyboardKey.enter,
      physicalKey: PhysicalKeyboardKey.enter,
    ).toKeyEvent;
    editorState.service.keyboardService!.onKey(key);
    await tester.pumpAndSettle();
    expect(editorState.document.root.children.length, 2);
  });
}
