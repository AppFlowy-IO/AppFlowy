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

      // expect to see a readme page
      tester.expectToSeePageName(readme);

      await tester.tapAddButton();
      await tester.tapImportButton();

      final testFileNames = ['test1.md', 'test2.md'];
      for (final fileName in testFileNames) {
        final str = await rootBundle.loadString(
          'assets/test/workspaces/markdowns/$fileName',
        );
        File(p.join(context.applicationDataDirectory.path, fileName))
            .writeAsStringSync(str);
      }
      // mock get files
      await mockPickFilePaths(
        testFileNames,
        name: p.basename(context.applicationDataDirectory.path),
        customPath: context.applicationDataDirectory.path,
      );

      await tester.tapTextAndMarkdownButton();

      tester.expectToSeePageName('test1');
      tester.expectToSeePageName('test2');
    });
  });
}
