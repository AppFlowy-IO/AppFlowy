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
    const location = 'import_files';

    setUp(() async {
      await TestFolder.cleanTestLocation(location);
      await TestFolder.setTestLocation(location);
    });

    tearDown(() async {
      await TestFolder.cleanTestLocation(location);
    });

    tearDownAll(() async {
      await TestFolder.cleanTestLocation(null);
    });

    testWidgets('import multiple markdown files', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      // expect to see a readme page
      tester.expectToSeePageName(readme);

      await tester.tapAddButton();
      await tester.tapImportButton();

      final testFileNames = ['test1.md', 'test2.md'];
      final fileLocation = await tester.currentFileLocation();
      for (final fileName in testFileNames) {
        final str = await rootBundle.loadString(
          p.join(
            'assets/test/workspaces/markdowns',
            fileName,
          ),
        );
        File(p.join(fileLocation, fileName)).writeAsStringSync(str);
      }
      // mock get files
      await mockPickFilePaths(testFileNames, name: location);

      await tester.tapTextAndMarkdownButton();

      tester.expectToSeePageName('test1');
      tester.expectToSeePageName('test2');
    });
  });
}
