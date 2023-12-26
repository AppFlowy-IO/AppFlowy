import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:easy_localization/easy_localization.dart';
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
  group("Template Layout Tests", () {
    testWidgets("expect template option at document share", (tester) async {
      await _initTest(tester);
      await tester.tapShareButton();
      expect(find.text(LocaleKeys.template_title.tr()), findsOneWidget);
    });
    testWidgets("expect template option at add dropdown", (tester) async {
      await _initTest(tester);
      await tester.tapAddViewButton();
      expect(find.text(LocaleKeys.template_title.tr()), findsOneWidget);
    });
    testWidgets("expect to see the template dialog", (tester) async {
      await _initTest(tester);

      await tester.tapAddViewButton();
      await tester.tapButtonWithName(LocaleKeys.template_title.tr());
      await tester.pumpAndSettle();

      expect(find.byType(TemplateDialog), findsOneWidget);
    });
  });

  group('Template Functionality Tests', () {
    testWidgets(
      "expect template.zip in documents folder when exported",
      (tester) async {
        await _initTest(tester);
        await tester.tapShareButton();
        await tester.tapButtonWithName(LocaleKeys.template_title.tr());

        final docPath = await getApplicationDocumentsDirectory();

        // expect to see the template.zip in documents folder
        final file = File(p.join(docPath.path, 'template.zip'));
        expect(await file.exists(), true);

        // expect to find the config.json in "/template" folder
        final configFile = File(p.join(docPath.path, "template/config.json"));
        expect(await configFile.exists(), true);
      },
    );

    testWidgets(
        "expect .csv file in template folder when a document with grid is exported",
        (tester) async {
      await _initTest(tester);
      await tester.tapAddViewButton();
      await tester.tapCreateGridButton();
      await tester.pumpAndSettle();

      await tester.openPage(gettingStarted);

      await tester.tapShareButton();
      await tester.tapButtonWithName(LocaleKeys.template_title.tr());

      final docPath = await getApplicationDocumentsDirectory();

      // expect to see the template.zip in documents folder
      final file = File(p.join(docPath.path, 'template.zip'));
      expect(await file.exists(), true);

      // expect to find the config.json in "/template" folder
      final configFile = File(p.join(docPath.path, "template/config.json"));
      expect(await configFile.exists(), true);

      // expect to find one.csv file in "/template" folder
      final files = await Directory("${docPath.path}/template").list().toList();
      expect(files.where((e) => e.path.endsWith(".csv")).length, 1);
    });

    testWidgets("expect document in editor after import", (tester) async {
      final context = await _initTest(tester);
      await tester.tapAddViewButton();
      await tester.tapButtonWithName(LocaleKeys.template_title.tr());
      await tester.pumpAndSettle();

      const zipFileName = 'template_doc.zip';
      final data = await rootBundle.load('assets/test/workspaces/$zipFileName');

      final bytes = Uint8List.view(data.buffer);
      final path = p.join(context.applicationDataDirectory, zipFileName);
      File(path).writeAsBytesSync(bytes);

      await mockPickFilePaths(paths: [path]);

      expect(find.byType(TemplateDialog), findsOneWidget);
      await tester.tapButtonWithName("Pick from system");
      await tester.pumpAndSettle();

      await tester.expandPage(gettingStarted);

      final gettingStartedView = tester
          .widget<SingleInnerViewItem>(tester.findPageName(gettingStarted))
          .view;

      expect(gettingStartedView.childViews.length, 1);
      expect(gettingStartedView.childViews[0].layout, ViewLayoutPB.Document);
      expect(gettingStartedView.childViews[0].childViews.length, 0);
    });

    testWidgets("expect database in editor after import", (tester) async {
      final context = await _initTest(tester);
      await tester.tapAddViewButton();
      await tester.tapButtonWithName(LocaleKeys.template_title.tr());
      await tester.pumpAndSettle();

      const zipFileName = 'template_grid.zip';
      final data = await rootBundle.load('assets/test/workspaces/$zipFileName');

      final bytes = Uint8List.view(data.buffer);
      final path = p.join(context.applicationDataDirectory, zipFileName);
      File(path).writeAsBytesSync(bytes);

      await mockPickFilePaths(paths: [path]);

      expect(find.byType(TemplateDialog), findsOneWidget);
      await tester.tapButtonWithName("Pick from system");
      await tester.pumpAndSettle();

      await tester.expandPage(gettingStarted);

      final gettingStartedView = tester
          .widget<SingleInnerViewItem>(tester.findPageName(gettingStarted))
          .view;

      expect(gettingStartedView.childViews.length, 1);
      expect(gettingStartedView.childViews[0].layout, ViewLayoutPB.Document);
      await tester.expandPage(gettingStartedView.childViews[0].name);

      final res = await ViewBackendService.getChildViews(
        viewId: gettingStartedView.childViews[0].id,
      );

      final childViews = res.fold((l) => l, (r) => null);

      assert(childViews != null);
      expect(childViews!.length, 1);
      expect(childViews[0].layout, ViewLayoutPB.Grid);
    });
  });
}

Future<FlowyTestContext> _initTest(WidgetTester tester) async {
  final context = await tester.initializeAppFlowy();
  await tester.tapGoButton();
  await tester.pumpAndSettle();

  tester.expectToSeePageName(gettingStarted);

  await tester.openPage(gettingStarted);
  await tester.editor.tapLineOfEditorAt(0);
  await tester.pumpAndSettle();
  return context;
}
