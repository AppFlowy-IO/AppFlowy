import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() async {
  group('attributes.dart', () {
    test('composeAttributes', () {
      final base = {
        'a': 1,
        'b': 2,
      };
      final other = {
        'b': 3,
        'c': 4,
        'd': null,
      };
      expect(composeAttributes(base, other, keepNull: false), {
        'a': 1,
        'b': 3,
        'c': 4,
      });
      expect(composeAttributes(base, other, keepNull: true), {
        'a': 1,
        'b': 3,
        'c': 4,
        'd': null,
      });
      expect(composeAttributes(null, other, keepNull: false), {
        'b': 3,
        'c': 4,
      });
      expect(composeAttributes(base, null, keepNull: false), {
        'a': 1,
        'b': 2,
      });
    });

    test('invertAttributes', () {
      final base = {
        'a': 1,
        'b': 2,
      };
      final other = {
        'b': 3,
        'c': 4,
        'd': null,
      };
      expect(invertAttributes(base, other), {
        'a': 1,
        'b': 2,
        'c': null,
      });
      expect(invertAttributes(other, base), {
        'a': null,
        'b': 3,
        'c': 4,
      });
      expect(invertAttributes(null, base), {
        'a': null,
        'b': null,
      });
      expect(invertAttributes(other, null), {
        'b': 3,
        'c': 4,
      });
    });
    test(
      "hasAttributes",
      () {
        final base = {
          'a': 1,
          'b': 2,
        };
        final other = {
          'c': 3,
          'd': 4,
        };

        var x = hashAttributes(base);
        var y = hashAttributes(base);
        // x & y should have same hash code
        expect(x == y, true);

        y = hashAttributes(other);

        // x & y should have different hash code
        expect(x == y, false);
      },
    );
  });
}
