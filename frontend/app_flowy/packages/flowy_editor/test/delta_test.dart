import 'package:flutter_test/flutter_test.dart';
import 'package:flowy_editor/document/text_delta.dart';

void main() {
  group('compose', () {
    test('test delta', () {
      final delta = Delta(<TextOperation>[
        TextInsert('Gandalf', {
          'bold': true,
        }),
        TextInsert(' the '),
        TextInsert('Grey', {
          'color': '#ccc',
        })
      ]);

      final death = Delta().retain(12).insert("White", {
        'color': '#fff',
      }).delete(4);

      final restores = delta.compose(death);
      expect(restores.operations, <TextOperation>[
        TextInsert('Gandalf', {'bold': true}),
        TextInsert(' the '),
        TextInsert('White', {'color': '#fff'}),
      ]);
    });
    test('compose()', () {
      final a = Delta().insert('A');
      final b = Delta().insert('B');
      final expected = Delta().insert('B').insert('A');
      expect(a.compose(b), expected);
    });
    test('insert + retain', () {
      final a = Delta().insert('A');
      final b = Delta().retain(1, {
        'bold': true,
        'color': 'red',
      });
      final expected = Delta().insert('A', {
        'bold': true,
        'color': 'red',
      });
      expect(a.compose(b), expected);
    });
    test('insert + delete', () {
      final a = Delta().insert('A');
      final b = Delta().delete(1);
      final expected = Delta();
      expect(a.compose(b), expected);
    });
    test('delete + insert', () {
      final a = Delta().delete(1);
      final b = Delta().insert('B');
      final expected = Delta().insert('B').delete(1);
      expect(a.compose(b), expected);
    });
    test('delete + retain', () {
      final a = Delta().delete(1);
      final b = Delta().retain(1, {
        'bold': true,
        'color': 'red',
      });
      final expected = Delta().delete(1).retain(1, {
        'bold': true,
        'color': 'red',
      });
      expect(a.compose(b), expected);
    });
    test('delete + delete', () {
      final a = Delta().delete(1);
      final b = Delta().delete(1);
      final expected = Delta().delete(2);
      expect(a.compose(b), expected);
    });
    test('retain + insert', () {
      final a = Delta().retain(1, {'color': 'blue'});
      final b = Delta().insert('B');
      final expected = Delta().insert('B').retain(1, {
        'color': 'blue',
      });
      expect(a.compose(b), expected);
    });
    test('retain + retain', () {
      final a = Delta().retain(1, {
        'color': 'blue',
      });
      final b = Delta().retain(1, {
        'bold': true,
        'color': 'red',
      });
      final expected = Delta().retain(1, {
        'bold': true,
        'color': 'red',
      });
      expect(a.compose(b), expected);
    });
    test('retain + delete', () {
      final a = Delta().retain(1, {
        'color': 'blue',
      });
      final b = Delta().delete(1);
      final expected = Delta().delete(1);
      expect(a.compose(b), expected);
    });
    test('insert in middle of text', () {
      final a = Delta().insert('Hello');
      final b = Delta().retain(3).insert('X');
      final expected = Delta().insert('HelXlo');
      expect(a.compose(b), expected);
    });
    test('insert and delete ordering', () {
      final a = Delta().insert('Hello');
      final b = Delta().insert('Hello');
      final insertFirst = Delta().retain(3).insert('X').delete(1);
      final deleteFirst = Delta().retain(3).delete(1).insert('X');
      final expected = Delta().insert('HelXo');
      expect(a.compose(insertFirst), expected);
      expect(b.compose(deleteFirst), expected);
    });
    test('delete entire text', () {
      final a = Delta().retain(4).insert('Hello');
      final b = Delta().delete(9);
      final expected = Delta().delete(4);
      expect(a.compose(b), expected);
    });
    test('retain more than length of text', () {
      final a = Delta().insert('Hello');
      final b = Delta().retain(10);
      final expected = Delta().insert('Hello');
      expect(a.compose(b), expected);
    });
    test('retain start optimization', () {
      final a = Delta()
          .insert('A', {'bold': true})
          .insert('B')
          .insert('C', {'bold': true})
          .delete(1);
      final b = Delta().retain(3).insert('D');
      final expected = Delta()
          .insert('A', {'bold': true})
          .insert('B')
          .insert('C', {'bold': true})
          .insert('D')
          .delete(1);
      expect(a.compose(b), expected);
    });
    test('retain end optimization', () {
      final a = Delta()
          .insert('A', {'bold': true})
          .insert('B')
          .insert('C', {'bold': true});
      final b = Delta().delete(1);
      final expected = Delta().insert('B').insert('C', {'bold': true});
      expect(a.compose(b), expected);
    });
    test('retain end optimization join', () {
      final a = Delta()
          .insert('A', {'bold': true})
          .insert('B')
          .insert('C', {'bold': true})
          .insert('D')
          .insert('E', {'bold': true})
          .insert('F');
      final b = Delta().retain(1).delete(1);
      final expected = Delta()
          .insert('AC', {'bold': true})
          .insert('D')
          .insert('E', {'bold': true})
          .insert('F');
      expect(a.compose(b), expected);
    });
  });
  group('invert', () {
    test('insert', () {
      final delta = Delta().retain(2).insert('A');
      final base = Delta().insert('12346');
      final expected = Delta().retain(2).delete(1);
      final inverted = delta.invert(base);
      expect(expected, inverted);
      expect(base.compose(delta).compose(inverted), base);
    });
    test('delete', () {
      final delta = Delta().retain(2).delete(3);
      final base = Delta().insert('123456');
      final expected = Delta().retain(2).insert('345');
      final inverted = delta.invert(base);
      expect(expected, inverted);
      expect(base.compose(delta).compose(inverted), base);
    });
    // test('retain', () {
    //   final delta = Delta().retain(2).retain(3, {'bold': true});
    //   final base = Delta().insert('123456');
    //   final expected = Delta().retain(2).retain(3, {'bold': null});
    //   final inverted = delta.invert(base);
    //   expect(expected, inverted);
    //   expect(base.compose(delta).compose(inverted), base);
    // });
  });
  group('json', () {
    test('toJson()', () {
      final delta = Delta().retain(2).insert('A').delete(3);
      expect(delta.toJson(), [
        {'retain': 2},
        {'insert': 'A'},
        {'delete': 3}
      ]);
    });
    test('attributes', () {
      final delta =
          Delta().retain(2, {'bold': true}).insert('A', {'italic': true});
      expect(delta.toJson(), [
        {
          'retain': 2,
          'attributes': {'bold': true},
        },
        {
          'insert': 'A',
          'attributes': {'italic': true},
        },
      ]);
    });
    test('fromJson()', () {
      final delta = Delta.fromJson([
        {'retain': 2},
        {'insert': 'A'},
        {'delete': 3},
      ]);
      final expected = Delta().retain(2).insert('A').delete(3);
      expect(delta, expected);
    });
  });
}
