import 'package:appflowy/mobile/presentation/search/mobile_search_cell.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Test for searching text with split query', () {
    int checkLength(String query, List<String> contents) {
      int i = 0;
      for (final content in contents) {
        if (content.toLowerCase() == query.toLowerCase()) {
          i++;
        }
      }
      return i;
    }

    test('split with space', () {
      final content = 'Hello HELLO hello HeLLo';
      final query = 'Hello';
      final contents = content
          .splitIncludeSeparator(query)
          .where((e) => e.isNotEmpty)
          .toList();
      assert(contents.join() == content);

      assert(checkLength(query, contents) == 4);
    });

    test('split without space', () {
      final content = 'HelloHELLOhelloHeLLo';
      final query = 'Hello';
      final contents = content
          .splitIncludeSeparator(query)
          .where((e) => e.isNotEmpty)
          .toList();
      assert(contents.join() == content);
      assert(checkLength(query, contents) == 4);
    });

    test('split without space and with error content', () {
      final content = 'HellHELLOhelloeLLo';
      final query = 'Hello';
      final contents = content
          .splitIncludeSeparator(query)
          .where((e) => e.isNotEmpty)
          .toList();
      assert(contents.join() == content);
      assert(checkLength(query, contents) == 2);
    });

    test('split with space and with error content', () {
      final content = 'Hell HELLOhello eLLo';
      final query = 'Hello';
      final contents = content
          .splitIncludeSeparator(query)
          .where((e) => e.isNotEmpty)
          .toList();
      assert(contents.join() == content);
      assert(checkLength(query, contents) == 2);
    });

    test('split without longer query', () {
      final content = 'Hello';
      final query = 'HelloHelloHelloHello';
      final contents = content
          .splitIncludeSeparator(query)
          .where((e) => e.isNotEmpty)
          .toList();
      assert(contents.join() == content);
      assert(checkLength(query, contents) == 0);
    });
  });
}
