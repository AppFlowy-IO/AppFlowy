import 'dart:ui';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:appflowy_editor/src/extensions/node_extensions.dart';

class MockNode extends Mock implements Node {}

void main() {
  group('NodeExtensions::', () {
    final mockNode = MockNode();

    final selection = Selection(
      start: Position(path: [0, 1]),
      end: Position(path: [1, 0]),
    );

    test('rect - renderBox is null', () {
      when(mockNode.renderBox).thenReturn(null);
      final result = mockNode.rect;
      expect(result, Rect.zero);
    });

    // test('inSelection', () {
    //   when(mockNode.path).thenAnswer((_) => [3, 3]);
    //   final result = mockNode.inSelection(selection);
    //   expect(result, true);
    // });
  });
}
