import 'package:appflowy_editor/src/core/document/path.dart';
import 'package:appflowy_editor/src/core/location/position.dart';
import 'package:appflowy_editor/src/core/location/selection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('create state tree', () async {
    // final String response = await rootBundle.loadString('assets/document.json');
    // final data = Map<String, Object>.from(json.decode(response));
    // final document = Document.fromJson(data);
    // expect(document.root.type, 'root');
    // expect(document.root.toJson(), data['document']);
  });

  test('search node by Path in state tree', () async {
    // final String response = await rootBundle.loadString('assets/document.json');
    // final data = Map<String, Object>.from(json.decode(response));
    // final document = Document.fromJson(data);
    // final checkBoxNode = document.root.childAtPath([1, 0]);
    // expect(checkBoxNode != null, true);
    // final textType = checkBoxNode!.attributes['text-type'];
    // expect(textType != null, true);
  });

  test('search node by Self in state tree', () async {
    // final String response = await rootBundle.loadString('assets/document.json');
    // final data = Map<String, Object>.from(json.decode(response));
    // final document = Document.fromJson(data);
    // final checkBoxNode = document.root.childAtPath([1, 0]);
    // expect(checkBoxNode != null, true);
    // final textType = checkBoxNode!.attributes['text-type'];
    // expect(textType != null, true);
    // final path = checkBoxNode.path;
    // expect(pathEquals(path, [1, 0]), true);
  });

  test('insert node in state tree', () async {
    // final String response = await rootBundle.loadString('assets/document.json');
    // final data = Map<String, Object>.from(json.decode(response));
    // final document = Document.fromJson(data);
    // final insertNode = Node.fromJson({
    //   'type': 'text',
    // });
    // bool result = document.insert([1, 1], [insertNode]);
    // expect(result, true);
    // expect(identical(insertNode, document.nodeAtPath([1, 1])), true);
  });

  test('delete node in state tree', () async {
    // final String response = await rootBundle.loadString('assets/document.json');
    // final data = Map<String, Object>.from(json.decode(response));
    // final document = Document.fromJson(data);
    // document.delete([1, 1], 1);
    // final node = document.nodeAtPath([1, 1]);
    // expect(node != null, true);
    // expect(node!.attributes['tag'], '**');
  });

  test('update node in state tree', () async {
    // final String response = await rootBundle.loadString('assets/document.json');
    // final data = Map<String, Object>.from(json.decode(response));
    // final document = Document.fromJson(data);
    // final test = document.update([1, 1], {'text-type': 'heading1'});
    // expect(test, true);
    // final updatedNode = document.nodeAtPath([1, 1]);
    // expect(updatedNode != null, true);
    // expect(updatedNode!.attributes['text-type'], 'heading1');
  });

  test('test path utils 1', () {
    final path1 = <int>[1];
    final path2 = <int>[1];
    expect(path1.equals(path2), true);

    expect(Object.hashAll(path1), Object.hashAll(path2));
  });

  test('test path utils 2', () {
    final path1 = <int>[1];
    final path2 = <int>[2];
    expect(path1.equals(path2), false);

    expect(Object.hashAll(path1) != Object.hashAll(path2), true);
  });

  test('test position comparator', () {
    final pos1 = Position(path: [1], offset: 0);
    final pos2 = Position(path: [1], offset: 0);
    expect(pos1 == pos2, true);
    expect(pos1.hashCode == pos2.hashCode, true);
  });

  test('test position comparator with offset', () {
    final pos1 = Position(path: [1, 1, 1, 1, 1], offset: 100);
    final pos2 = Position(path: [1, 1, 1, 1, 1], offset: 100);
    expect(pos1, pos2);
    expect(pos1.hashCode, pos2.hashCode);
  });

  test('test position comparator false', () {
    final pos1 = Position(path: [1, 1, 1, 1, 1], offset: 100);
    final pos2 = Position(path: [1, 1, 2, 1, 1], offset: 100);
    expect(pos1 == pos2, false);
    expect(pos1.hashCode == pos2.hashCode, false);
  });

  test('test position comparator with offset false', () {
    final pos1 = Position(path: [1, 1, 1, 1, 1], offset: 100);
    final pos2 = Position(path: [1, 1, 1, 1, 1], offset: 101);
    expect(pos1 == pos2, false);
    expect(pos1.hashCode == pos2.hashCode, false);
  });

  test('test selection comparator', () {
    final pos = Position(path: [0], offset: 0);
    final sel = Selection.collapsed(pos);
    expect(sel.start, sel.end);
    expect(sel.isCollapsed, true);
  });

  test('test selection collapse', () {
    final start = Position(path: [0], offset: 0);
    final end = Position(path: [0], offset: 10);
    final sel = Selection(start: start, end: end);

    final collapsedSelAtStart = sel.collapse(atStart: true);
    expect(collapsedSelAtStart.start, start);
    expect(collapsedSelAtStart.end, start);

    final collapsedSelAtEnd = sel.collapse();
    expect(collapsedSelAtEnd.start, end);
    expect(collapsedSelAtEnd.end, end);
  });
}
