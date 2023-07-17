import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'util/mock/mock_file_picker.dart';
import 'util/util.dart';
import 'package:path/path.dart' as p;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('import files', () {
    testWidgets('import page from notion', (tester) async {
      final context = await tester.initializeAppFlowy();
      await tester.tapGoButton();

      // expect to see a readme page
      tester.expectToSeePageName(readme);

      await tester.tapAddButton();
      await tester.tapImportButton();

      // final testFileNames = ['test1.md', 'test2.md'];
      final paths = <String>[];
      final ByteData data = await rootBundle
          .load('assets/test/workspaces/import_page_from_notion_test.zip');
      final path = p.join(
          context.applicationDataDirectory, 'import_page_from_notion_test.zip',);
      paths.add(path);
      final file = File(path);
      await file.writeAsBytes(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),);
      // mock get files
      
      expect(find.widgetWithText(Card, 'Page'), findsNothing);
      await tester.tapButtonWithName('Import from Notion');
      expect(find.widgetWithText(Card, 'Page'), findsOneWidget);
      await tester.tapButtonWithName('Page');
      expect(find.text('Import Notion Page'), findsOneWidget);
      await mockPickFilePaths(
        paths: paths,
      );
      await tester.tapButtonWithName('Upload zip file');
      tester.expectToSeePageName('AppFlowy Test');

    });
  });
}
