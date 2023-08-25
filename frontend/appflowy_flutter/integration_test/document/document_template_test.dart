import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';

import '../util/mock/mock_file_picker.dart';
import '../util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('document template test', () {
    testWidgets('export a template tree', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      await tester.createNewPageWithName(
        name: 'parentDoc',
        layout: ViewLayoutPB.Document,
      );

      await tester.editor.tapLineOfEditorAt(0);
      await tester.ime.insertText("# Parent Doc");

      await tester.createNewPageWithName(
        name: "childDoc",
        parentName: "parentDoc",
        layout: ViewLayoutPB.Document,
      );
      await tester.editor.tapLineOfEditorAt(0);
      await tester.ime.insertText("# Child Doc");

      await tester.createNewPageWithName(
        name: "childGrid",
        parentName: "parentDoc",
        layout: ViewLayoutPB.Grid,
      );

      await tester.openPage(gettingStarted);

      await tester.editor.hoverOnCoverToolbar();
      await tester.tapButtonWithName("Convert to JSON");

      final tempDir = await getApplicationDocumentsDirectory();

      expect(await Directory("${tempDir.path}/template").exists(), isTrue);

      expect(
        await File("${tempDir.path}/template/config.json").exists(),
        isTrue,
      );
      expect(
        await File("${tempDir.path}/template/parentDoc.json").exists(),
        isTrue,
      );
      expect(
        await File("${tempDir.path}/template/childDoc.json").exists(),
        isTrue,
      );
      expect(
        await File("${tempDir.path}/template/childGrid.csv").exists(),
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

      // Expand all pages
      final List<String> toExpand = [
        "TestTemplate",
        "Level1_1",
        "Level1_2",
        "Level2_1",
      ];

      for (final e in toExpand) {
        await tester.expandPage(e);
      }

      await tester.pumpAndSettle();

      tester.expectToSeePageName("TestTemplate", parentName: gettingStarted);

      tester.expectToSeePageName("Level1_1", parentName: "TestTemplate");
      tester.expectToSeePageName("Level2_1", parentName: "Level1_1");
      tester.expectToSeePageName("Level3_1", parentName: "Level2_1");

      tester.expectToSeePageName("Level1_2", parentName: "TestTemplate");
      tester.expectToSeePageName("Level2_2", parentName: "Level1_2");
      tester.expectToSeeText("Level2_Grid");
    });
  });
}
