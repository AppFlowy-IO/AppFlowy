import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() async {
  group('position.dart', () {
    test('test position equality', () {
      final positionA = Position(path: [0, 1, 2], offset: 3);
      final positionB = Position(path: [0, 1, 2], offset: 3);
      expect(positionA, positionB);

      final positionC = positionA.copyWith(offset: 4);
      final positionD = positionB.copyWith(path: [1, 2, 3]);
      expect(positionC.offset, 4);
      expect(positionD.path, [1, 2, 3]);

      expect(positionA.toJson(), {
        'path': [0, 1, 2],
        'offset': 3,
      });
      expect(positionC.toJson(), {
        'path': [0, 1, 2],
        'offset': 4,
      });
    });
  });
}
