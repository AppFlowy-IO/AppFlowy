import 'dart:convert';

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
    expect(stateTree.root.children.last.type, 'video');

    final checkBoxNode = stateTree.root.childAtPath([1, 0]);
    expect(checkBoxNode != null, true);
    final textType = checkBoxNode!.attributes['text-type'];
    expect(textType != null, true);
  });
}
