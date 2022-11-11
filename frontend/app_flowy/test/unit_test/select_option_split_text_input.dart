import 'package:app_flowy/plugins/grid/presentation/widgets/cell/select_option_cell/text_field.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const textSeparators = [','];

  group('split input unit test', () {
    test('empty input', () {
      List result = splitInput(' ', textSeparators);
      expect(result[0], []);
      expect(result[1], '');

      result = splitInput(', , , ', textSeparators);
      expect(result[0], []);
      expect(result[1], '');
    });

    test('simple input', () {
      List result = splitInput('exampleTag', textSeparators);
      expect(result[0], []);
      expect(result[1], 'exampleTag');

      result = splitInput('tag with longer name', textSeparators);
      expect(result[0], []);
      expect(result[1], 'tag with longer name');

      result = splitInput('trailing space ', textSeparators);
      expect(result[0], []);
      expect(result[1], 'trailing space ');
    });

    test('input with commas', () {
      List result = splitInput('a, b, c', textSeparators);
      expect(result[0], ['a', 'b']);
      expect(result[1], 'c');

      result = splitInput('a, b, c, ', textSeparators);
      expect(result[0], ['a', 'b', 'c']);
      expect(result[1], '');

      result = splitInput(',tag 1 ,2nd tag, third tag ', textSeparators);
      expect(result[0], ['tag 1', '2nd tag']);
      expect(result[1], 'third tag ');
    });
  });
}
