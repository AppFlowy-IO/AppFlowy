import 'package:appflowy/plugins/database/widgets/cell_editor/select_option_text_field.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const textSeparators = [','];

  group('split input unit test', () {
    test('empty input', () {
      var (submitted, remainder) = splitInput(' ', textSeparators);
      expect(submitted, []);
      expect(remainder, '');

      (submitted, remainder) = splitInput(', , , ', textSeparators);
      expect(submitted, []);
      expect(remainder, '');
    });

    test('simple input', () {
      var (submitted, remainder) = splitInput('exampleTag', textSeparators);
      expect(submitted, []);
      expect(remainder, 'exampleTag');

      (submitted, remainder) =
          splitInput('tag with longer name', textSeparators);
      expect(submitted, []);
      expect(remainder, 'tag with longer name');

      (submitted, remainder) = splitInput('trailing space ', textSeparators);
      expect(submitted, []);
      expect(remainder, 'trailing space ');
    });

    test('input with commas', () {
      var (submitted, remainder) = splitInput('a, b, c', textSeparators);
      expect(submitted, ['a', 'b']);
      expect(remainder, 'c');

      (submitted, remainder) = splitInput('a, b, c, ', textSeparators);
      expect(submitted, ['a', 'b', 'c']);
      expect(remainder, '');

      (submitted, remainder) =
          splitInput(',tag 1 ,2nd tag, third tag ', textSeparators);
      expect(submitted, ['tag 1', '2nd tag']);
      expect(remainder, 'third tag ');
    });
  });
}
