import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() async {
  group('path.dart', () {
    test('test path equality', () {
      var p1 = [0, 0];
      var p2 = [0];

      expect(p1 > p2, true);
      expect(p1 >= p2, true);
      expect(p1 < p2, false);
      expect(p1 <= p2, false);

      p1 = [1, 1, 2];
      p2 = [1, 1, 3];

      expect(p2 > p1, true);
      expect(p2 >= p1, true);
      expect(p2 < p1, false);
      expect(p2 <= p1, false);

      p1 = [2, 0, 1];
      p2 = [2, 0, 1];

      expect(p2 > p1, false);
      expect(p1 > p2, false);
      expect(p2 >= p1, true);
      expect(p2 <= p1, true);
      expect(p1.equals(p2), true);
    });
    test(
      "test path next, previous and parent getters",
      () {
        var p1 = [0, 0];
        var p2 = [0, 1];

        expect(p1.next.equals(p2), true);
        expect(p1.previous.equals(p2), false);
        expect(p1.parent.equals(p2), false);

        p1 = [0, 1, 0];
        p2 = [0, 1, 1];

        expect(p2.next.equals(p1), false);
        expect(p2.previous.equals(p1), true);
        expect(p2.parent.equals(p1), false);

        p1 = [0, 1, 1];
        p2 = [0, 1, 1];

        expect(p1.next.equals(p2), false);
        expect(p1.previous.equals(p2), false);
        expect(p1.parent.equals(p2), false);

        p1 = [];
        p2 = [];

        expect(p1.next.equals(p2), true);
        expect(p2.previous.equals(p1), true);
        expect(p1.parent.equals(p2), true);

        p1 = [1, 0, 2];
        p2 = [1, 0];

        expect(p1.parent.equals(p2), true);
        expect(p2.parent.equals(p1), false);
      },
    );
  });
}
