import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'package:appflowy/plugins/document/presentation/editor_plugins/base/link_to_page_widget.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';
import 'package:flowy_infra/uuid.dart';

import '../util/mock/mock_file_picker.dart';
import '../util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('document template test', () {
    testWidgets('export a template with referenced grid', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await insertReferenceDatabase(tester, ViewLayoutPB.Grid);
      await tester.openPage("template");

      await tester.editor.hoverOnCoverToolbar();
      await tester.tapButtonWithName("Convert to JSON");

      final tempDir = await getApplicationDocumentsDirectory();
      debugPrint("$tempDir");

      expect(await Directory("${tempDir.path}/template").exists(), isTrue);

      expect(
        await File("${tempDir.path}/template/template.json").exists(),
        isTrue,
      );

      expect(
        await File("${tempDir.path}/template/db1.csv").exists(),
        isTrue,
      );
    });

    testWidgets('import a template', (tester) async {
      final context = await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.editor.tapLineOfEditorAt(0);

      const zipFileName = 'template.zip';
      final data = await rootBundle.load('assets/test/workspaces/$zipFileName');

      final bytes = Uint8List.view(data.buffer);
      final path = p.join(context.applicationDataDirectory, zipFileName);
      File(path).writeAsBytesSync(bytes);

      // mock get files
      await mockPickFilePaths(paths: [path]);

      // tap template button
      await tester.tapAddViewButton();
      await tester.tapButtonWithName("Template");

      await tester.expandPage(gettingStarted);

      await tester.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 2));

      // expect to see the template files
      tester.expectToSeePageName("doc1", parentName: gettingStarted);
      tester.expectToSeePageName("doc2", parentName: gettingStarted);

      // expect to see the db files 
      tester.expectToSeeText("db1");
      tester.expectToSeeText("db2");

    });
  });
}

/// Insert a referenced database of [layout] into the document
Future<void> insertReferenceDatabase(
  WidgetTester tester,
  ViewLayoutPB layout,
) async {
  // create a new grid
  final id = uuid();
  final name = '${layout.name}_$id';
  await tester.createNewPageWithName(
    name: name,
    layout: layout,
  );

  // create a new document
  await tester.createNewPageWithName(
    name: 'template',
    layout: ViewLayoutPB.Document,
  );
  // tap the first line of the document
  await tester.editor.tapLineOfEditorAt(0);
  // insert a referenced view
  await tester.editor.showSlashMenu();
  await tester.editor.tapSlashMenuItemWithName(
    layout.referencedMenuName,
  );

  final linkToPageMenu = find.byType(LinkToPageMenu);
  expect(linkToPageMenu, findsOneWidget);
  final referencedDatabase = find.descendant(
    of: linkToPageMenu,
    matching: find.findTextInFlowyText(name),
  );
  expect(referencedDatabase, findsOneWidget);
  await tester.tapButton(referencedDatabase);
}
