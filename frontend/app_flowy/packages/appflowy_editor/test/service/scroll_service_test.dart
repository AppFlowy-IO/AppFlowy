import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../infra/test_editor.dart';

void main() async {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('Testing Scroll With Gestures', () {
    testWidgets('Test Gestsure Scroll', (tester) async {
      final editor = tester.editor;
      for (var i = 0; i < 100; i++) {
        editor.insertTextNode('$i');
      }
      editor.insertTextNode('mark');
      for (var i = 100; i < 200; i++) {
        editor.insertTextNode('$i');
      }
      await editor.startTesting();

      final listFinder = find.byType(Scrollable);
      final itemFinder = find.text('mark', findRichText: true);

      await tester.scrollUntilVisible(itemFinder, 500.0,
          scrollable: listFinder);

      expect(itemFinder, findsOneWidget);
    });
  });
}
