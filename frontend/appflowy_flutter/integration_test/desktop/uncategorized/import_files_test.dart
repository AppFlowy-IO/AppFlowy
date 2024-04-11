import 'dart:io';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;

import '../../shared/mock/mock_file_picker.dart';
import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('import files', () {
    testWidgets('import multiple markdown files', (tester) async {
      final context = await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

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
      mockPickFilePaths(
        paths: testFileNames
            .map((e) => p.join(context.applicationDataDirectory, e))
            .toList(),
      );

      await tester.tapTextAndMarkdownButton();

      tester.expectToSeePageName('test1');
      tester.expectToSeePageName('test2');
    });

    testWidgets('import markdown file with table', (tester) async {
      final context = await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // expect to see a getting started page
      tester.expectToSeePageName(gettingStarted);

      await tester.tapAddViewButton();
      await tester.tapImportButton();

      const testFileName = 'markdown_with_table.md';
      final paths = <String>[];
      final str = await rootBundle.loadString(
        'assets/test/workspaces/markdowns/$testFileName',
      );
      final path = p.join(context.applicationDataDirectory, testFileName);
      paths.add(path);
      File(path).writeAsStringSync(str);
      // mock get files
      mockPickFilePaths(
        paths: paths,
      );

      await tester.tapTextAndMarkdownButton();

      tester.expectToSeePageName('markdown_with_table');

      // expect to see all content of markdown file along with table
      await tester.openPage('markdown_with_table');

      final importedPageEditorState = tester.editor.getCurrentEditorState();
      expect(
        importedPageEditorState.getNodeAtPath([0])!.type,
        HeadingBlockKeys.type,
      );
      expect(
        importedPageEditorState.getNodeAtPath([2])!.type,
        HeadingBlockKeys.type,
      );
      expect(
        importedPageEditorState.getNodeAtPath([4])!.type,
        TableBlockKeys.type,
      );
    });
  });
}
