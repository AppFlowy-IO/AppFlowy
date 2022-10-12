import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() async {
  group('operation.dart', () {
    test('test insert operation', () {
      final node = Node(type: 'example');
      final op = InsertOperation([0], [node]);
      final json = op.toJson();
      expect(json, {
        'op': 'insert',
        'path': [0],
        'nodes': [
          {
            'type': 'example',
          }
        ]
      });
      expect(InsertOperation.fromJson(json), op);
      expect(op.invert().invert(), op);
      expect(op.copyWith(), op);
    });

    test('test update operation', () {
      final op = UpdateOperation([0], {'a': 1}, {'a': 0});
      final json = op.toJson();
      expect(json, {
        'op': 'update',
        'path': [0],
        'attributes': {'a': 1},
        'oldAttributes': {'a': 0}
      });
      expect(UpdateOperation.fromJson(json), op);
      expect(op.invert().invert(), op);
      expect(op.copyWith(), op);
    });

    test('test delete operation', () {
      final node = Node(type: 'example');
      final op = DeleteOperation([0], [node]);
      final json = op.toJson();
      expect(json, {
        'op': 'delete',
        'path': [0],
        'nodes': [
          {
            'type': 'example',
          }
        ]
      });
      expect(DeleteOperation.fromJson(json), op);
      expect(op.invert().invert(), op);
      expect(op.copyWith(), op);
    });

    test('test update text operation', () {
      final app = Delta()..insert('App');
      final appflowy = Delta()
        ..retain(3)
        ..insert('Flowy');
      final op = UpdateTextOperation([0], app, appflowy.invert(app));
      final json = op.toJson();
      expect(json, {
        'op': 'update_text',
        'path': [0],
        'delta': [
          {'insert': 'App'}
        ],
        'inverted': [
          {'retain': 3},
          {'delete': 5}
        ]
      });
      expect(UpdateTextOperation.fromJson(json), op);
      expect(op.invert().invert(), op);
      expect(op.copyWith(), op);
    });
  });
}
