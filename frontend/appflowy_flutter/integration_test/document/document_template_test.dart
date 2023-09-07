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

      final tempDir = await getApplicationDocumentsDirectory();

      // delete template directory if exists before
      if (await Directory("${tempDir.path}/template").exists()) {
        await Directory("${tempDir.path}/template").delete(recursive: true);
      }

      await tester.tapShareButton();
      await tester.tapTemplateButton();

      expect(await Directory("${tempDir.path}/template").exists(), isTrue);

      // get all files in template folder
      final files = await Directory("${tempDir.path}/template").list().toList();

      // expect if config.json exists in template folder
      expect(files.where((e) => e.path.endsWith("config.json")).length, 1);
      // expect to have 4 json files (including config.json)
      expect(files.where((e) => e.path.endsWith(".json")).length, 4);
      // check for 1 .csv file
      expect(files.where((e) => e.path.endsWith(".csv")).length, 1);
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
      // the template was added successfully

      await tester.pumpAndSettle();
    });
  });
}
