import 'dart:convert';

import 'package:flowy_editor/document/node.dart';
import 'package:flowy_editor/document/state_tree.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('create state tree', () async {
    final String response = await rootBundle.loadString('assets/document.json');
    final data = Map<String, Object>.from(json.decode(response));
    final stateTree = StateTree.fromJson(data);
    expect(stateTree.root.type, 'root');
    expect(stateTree.root.toJson(), data['document']);
  });

  test('search node in state tree', () async {
    final String response = await rootBundle.loadString('assets/document.json');
    final data = Map<String, Object>.from(json.decode(response));
    final stateTree = StateTree.fromJson(data);
    final checkBoxNode = stateTree.root.childAtPath([1, 0]);
    expect(checkBoxNode != null, true);
    final textType = checkBoxNode!.attributes['text-type'];
    expect(textType != null, true);
  });

  test('insert node in state tree', () async {
    final String response = await rootBundle.loadString('assets/document.json');
    final data = Map<String, Object>.from(json.decode(response));
    final stateTree = StateTree.fromJson(data);
    final insertNode = Node.fromJson({
      'type': 'text',
    });
    bool result = stateTree.insert([1, 1], insertNode);
    expect(result, true);
    expect(identical(insertNode, stateTree.nodeAtPath([1, 1])), true);
  });

  test('delete node in state tree', () async {
    final String response = await rootBundle.loadString('assets/document.json');
    final data = Map<String, Object>.from(json.decode(response));
    final stateTree = StateTree.fromJson(data);
    final deletedNode = stateTree.delete([1, 0]);
    expect(deletedNode != null, true);
    expect(deletedNode!.attributes['text-type'], 'check-box');
  });

  test('update node in state tree', () async {
    final String response = await rootBundle.loadString('assets/document.json');
    final data = Map<String, Object>.from(json.decode(response));
    final stateTree = StateTree.fromJson(data);
    final attributes = stateTree.update([1, 0], {'text-type': 'heading1'});
    expect(attributes != null, true);
    expect(attributes!['text-type'], 'check-box');
    final updatedNode = stateTree.nodeAtPath([1, 0]);
    expect(updatedNode != null, true);
    expect(updatedNode!.attributes['text-type'], 'heading1');
  });
}
