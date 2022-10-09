import 'dart:collection';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() async {
  group('node.dart', () {
    test('test node copyWith', () {
      final node = Node(
        type: 'example',
        children: LinkedList(),
        attributes: {
          'example': 'example',
        },
      );
      expect(node.toJson(), {
        'type': 'example',
        'attributes': {
          'example': 'example',
        },
      });
      expect(
        node.copyWith().toJson(),
        node.toJson(),
      );

      final nodeWithChildren = Node(
        type: 'example',
        children: LinkedList()..add(node),
        attributes: {
          'example': 'example',
        },
      );
      expect(nodeWithChildren.toJson(), {
        'type': 'example',
        'attributes': {
          'example': 'example',
        },
        'children': [
          {
            'type': 'example',
            'attributes': {
              'example': 'example',
            },
          },
        ],
      });
      expect(
        nodeWithChildren.copyWith().toJson(),
        nodeWithChildren.toJson(),
      );
    });

    test('test textNode copyWith', () {
      final textNode = TextNode(
        children: LinkedList(),
        attributes: {
          'example': 'example',
        },
        delta: Delta()..insert('AppFlowy'),
      );
      expect(textNode.toJson(), {
        'type': 'text',
        'attributes': {
          'example': 'example',
        },
        'delta': [
          {'insert': 'AppFlowy'},
        ],
      });
      expect(
        textNode.copyWith().toJson(),
        textNode.toJson(),
      );

      final textNodeWithChildren = TextNode(
        children: LinkedList()..add(textNode),
        attributes: {
          'example': 'example',
        },
        delta: Delta()..insert('AppFlowy'),
      );
      expect(textNodeWithChildren.toJson(), {
        'type': 'text',
        'attributes': {
          'example': 'example',
        },
        'delta': [
          {'insert': 'AppFlowy'},
        ],
        'children': [
          {
            'type': 'text',
            'attributes': {
              'example': 'example',
            },
            'delta': [
              {'insert': 'AppFlowy'},
            ],
          },
        ],
      });
      expect(
        textNodeWithChildren.copyWith().toJson(),
        textNodeWithChildren.toJson(),
      );
    });

    test('test node path', () {
      Node previous = Node(
        type: 'example',
        attributes: {},
        children: LinkedList(),
      );
      const len = 10;
      for (var i = 0; i < len; i++) {
        final node = Node(
          type: 'example_$i',
          attributes: {},
          children: LinkedList(),
        );
        previous.children.add(node..parent = previous);
        previous = node;
      }
      expect(previous.path, List.filled(len, 0));
    });

    test('test copy with', () {
      final child = Node(
        type: 'child',
        attributes: {},
        children: LinkedList(),
      );
      final base = Node(
        type: 'base',
        attributes: {},
        children: LinkedList()..add(child),
      );
      final node = base.copyWith(
        type: 'node',
      );
      expect(identical(node.attributes, base.attributes), false);
      expect(identical(node.children, base.children), false);
      expect(identical(node.children.first, base.children.first), false);
    });

    test('test insert', () {
      final base = Node(
        type: 'base',
      );

      // insert at the front
      final childA = Node(
        type: 'child',
      );
      base.insert(childA, index: -1);
      expect(
        identical(base.childAtIndex(0), childA),
        true,
      );

      // insert at the last
      final childB = Node(
        type: 'child',
      );
      base.insert(childB, index: 1000);
      expect(
        identical(base.childAtIndex(base.children.length - 1), childB),
        true,
      );

      // insert at the last
      final childC = Node(
        type: 'child',
      );
      base.insert(childC);
      expect(
        identical(base.childAtIndex(base.children.length - 1), childC),
        true,
      );
    });

    test('test fromJson', () {
      final node = Node.fromJson({
        'type': 'example',
        'attributes': {
          'example': 'example',
        },
        'children': [
          {
            'type': 'example',
            'attributes': {
              'example': 'example',
            },
          },
        ],
      });
      expect(node.type, 'example');
      expect(node.attributes, {'example': 'example'});
      expect(node.children.length, 1);
      expect(node.children.first.type, 'example');
      expect(node.children.first.attributes, {'example': 'example'});
    });

    test('test toPlainText', () {
      final textNode = TextNode.empty()..delta = (Delta()..insert('AppFlowy'));
      expect(textNode.toPlainText(), 'AppFlowy');
    });
  });
}
