import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appflowy_editor/src/extensions/path_extensions.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('path_extensions.dart', () {
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
      expect(pathEquals(p1, p2), true);
    });
  });
}
