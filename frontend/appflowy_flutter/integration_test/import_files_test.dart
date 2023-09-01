import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'util/mock/mock_file_picker.dart';
import 'util/util.dart';
import 'package:path/path.dart' as p;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('import files', () {
    testWidgets('import multiple markdown files', (tester) async {
      final context = await tester.initializeAppFlowy();
      await tester.tapGoButton();

      // expect to see a getting started page
      tester.expectToSeePageName(gettingStarted);

      await tester.tapAddViewButton();
      await tester.tapImportButton();

      final testFileNames = ['test1.md', 'test2.md'];
      final paths = <String>[];
      for (final fileName in testFileNames) {
        final str = await rootBundle.loadString(
          'assets/test/workspaces/markdowns/$fileName',
        );
        final path = p.join(context.applicationDataDirectory, fileName);
        paths.add(path);
        File(path).writeAsStringSync(str);
      }
      // mock get files
      await mockPickFilePaths(
        paths: testFileNames
            .map((e) => p.join(context.applicationDataDirectory, e))
            .toList(),
      );

      await tester.tapTextAndMarkdownButton();

      tester.expectToSeePageName('test1');
      tester.expectToSeePageName('test2');
    });
  });
}
