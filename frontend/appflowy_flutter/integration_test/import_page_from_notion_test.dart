import 'dart:io';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'util/mock/mock_file_picker.dart';
import 'util/util.dart';
import 'package:path/path.dart' as p;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  group('import file from notion', () {
    testWidgets('import markdown zip from notion', (tester) async {
      const pageName = 'AppFlowy Test';
      final context = await tester.initializeAppFlowy();
      await tester.tapGoButton();

      // expect to see a readme page
      tester.expectToSeePageName(readme);

      await tester.tapAddButton();
      await tester.tapImportButton();

      final paths = <String>[];
      final ByteData data = await rootBundle
          .load('assets/test/workspaces/import_page_from_notion_test.zip');
      final path = p.join(
        context.applicationDataDirectory,
        'import_page_from_notion_test.zip',
      );
      paths.add(path);
      final file = File(path);
      await file.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      // mock get files

      expect(find.widgetWithText(Card, 'From Markdown Zip'), findsNothing);
      await tester.tapButtonWithName('Import from Notion Markdown Zip');
      expect(find.widgetWithText(Card, 'From Markdown Zip'), findsOneWidget);
      await tester.tapButtonWithName('From Markdown Zip');
      expect(find.text('Import Notion From Markdown Zip'), findsOneWidget);
      await mockPickFilePaths(
        paths: paths,
      );
      await tester.tapButtonWithName('Upload zip file');
      tester.expectToSeePageName(pageName);
      await tester.openPage(pageName);
      //the above one openPage command closes the import panel
      await tester.openPage(pageName);
      expect(
        tester.editor.getCurrentEditorState().getNodeAtPath([0])!.type,
        HeadingBlockKeys.type,
      );
      expect(
        tester.editor.getCurrentEditorState().getNodeAtPath([2])!.type,
        ImageBlockKeys.type,
      );
      expect(
        tester.editor.getCurrentEditorState().getNodeAtPath([3])!.type,
        ImageBlockKeys.type,
      );
      expect(
        tester.editor.getCurrentEditorState().getNodeAtPath([4])!.type,
        DividerBlockKeys.type,
      );
      expect(
        tester.editor.getCurrentEditorState().getNodeAtPath([5])!.type,
        BulletedListBlockKeys.type,
      );
      expect(
        tester.editor.getCurrentEditorState().getNodeAtPath([7])!.type,
        NumberedListBlockKeys.type,
      );
      //the below line get the href from the text
      final hrefFromText = tester.editor
          .getCurrentEditorState()
          .getNodeAtPath([9])!
          .attributes
          .values
          .elementAt(0)[0]['attributes']['href'];
      expect(
        hrefFromText,
        'https://appflowy.gitbook.io/docs/essential-documentation/readme',
      );
    });
  });
}
