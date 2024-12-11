import 'package:appflowy/shared/patterns/common_patterns.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('url launcher unit test', () {
    test('launch local uri', () async {
      const localUris = [
        'file://path/to/file.txt',
        '/path/to/file.txt',
        'C:\\path\\to\\file.txt',
        '../path/to/file.txt',
      ];
      for (final uri in localUris) {
        final result = localPathRegex.hasMatch(uri);
        expect(result, true);
      }
    });
  });
}
