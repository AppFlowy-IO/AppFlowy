import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/media_cell_editor.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/shared_widget.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../shared/database_test_op.dart';
import '../../shared/mock/mock_file_picker.dart';
import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('media type option in database', () {
    testWidgets('add media field and add files two times', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);

      // Invoke the field editor
      await tester.tapGridFieldWithName('Type');
      await tester.tapEditFieldButton();

      // Change to media type
      await tester.tapSwitchFieldTypeButton();
      await tester.selectFieldType(FieldType.Media);
      await tester.dismissFieldEditor();

      // Open media cell editor
      await tester.tapCellInGrid(rowIndex: 0, fieldType: FieldType.Media);
      await tester.findMediaCellEditor(findsOneWidget);

      // Prepare files for upload from local
      final firstImage =
          await rootBundle.load('assets/test/images/sample.jpeg');
      final secondImage =
          await rootBundle.load('assets/test/images/sample.gif');
      final tempDirectory = await getTemporaryDirectory();

      final firstImagePath = p.join(tempDirectory.path, 'sample.jpeg');
      final firstFile = File(firstImagePath)
        ..writeAsBytesSync(firstImage.buffer.asUint8List());

      final secondImagePath = p.join(tempDirectory.path, 'sample.gif');
      final secondFile = File(secondImagePath)
        ..writeAsBytesSync(secondImage.buffer.asUint8List());

      mockPickFilePaths(paths: [firstImagePath]);
      await getIt<KeyValueStorage>().set(KVKeys.kCloudType, '0');

      // Click on add file button in the Media Cell Editor
      await tester.tap(find.text(LocaleKeys.grid_media_addFileOrImage.tr()));
      await tester.pumpAndSettle();

      // Tap on the upload interaction
      await tester.tapFileUploadHint();

      // Expect one file
      expect(find.byType(RenderMedia), findsOneWidget);

      // Mock second file
      mockPickFilePaths(paths: [secondImagePath]);

      // Click on add file button in the Media Cell Editor
      await tester.tap(find.text(LocaleKeys.grid_media_addFileOrImage.tr()));
      await tester.pumpAndSettle();

      // Tap on the upload interaction
      await tester.tapFileUploadHint();
      await tester.pumpAndSettle();

      // Expect two files
      expect(find.byType(RenderMedia), findsNWidgets(2));

      // Remove the temp files
      await Future.wait([firstFile.delete(), secondFile.delete()]);
    });

    testWidgets('add two files at once', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);

      // Invoke the field editor
      await tester.tapGridFieldWithName('Type');
      await tester.tapEditFieldButton();

      // Change to media type
      await tester.tapSwitchFieldTypeButton();
      await tester.selectFieldType(FieldType.Media);
      await tester.dismissFieldEditor();

      // Open media cell editor
      await tester.tapCellInGrid(rowIndex: 0, fieldType: FieldType.Media);
      await tester.findMediaCellEditor(findsOneWidget);

      // Prepare files for upload from local
      final firstImage =
          await rootBundle.load('assets/test/images/sample.jpeg');
      final secondImage =
          await rootBundle.load('assets/test/images/sample.gif');
      final tempDirectory = await getTemporaryDirectory();

      final firstImagePath = p.join(tempDirectory.path, 'sample.jpeg');
      final firstFile = File(firstImagePath)
        ..writeAsBytesSync(firstImage.buffer.asUint8List());

      final secondImagePath = p.join(tempDirectory.path, 'sample.gif');
      final secondFile = File(secondImagePath)
        ..writeAsBytesSync(secondImage.buffer.asUint8List());

      mockPickFilePaths(paths: [firstImagePath, secondImagePath]);
      await getIt<KeyValueStorage>().set(KVKeys.kCloudType, '0');

      // Click on add file button in the Media Cell Editor
      await tester.tap(find.text(LocaleKeys.grid_media_addFileOrImage.tr()));
      await tester.pumpAndSettle();

      // Tap on the upload interaction
      await tester.tapFileUploadHint();

      // Expect two files
      expect(find.byType(RenderMedia), findsNWidgets(2));

      // Remove the temp files
      await Future.wait([firstFile.delete(), secondFile.delete()]);
    });

    testWidgets('delete files', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);

      // Invoke the field editor
      await tester.tapGridFieldWithName('Type');
      await tester.tapEditFieldButton();

      // Change to media type
      await tester.tapSwitchFieldTypeButton();
      await tester.selectFieldType(FieldType.Media);
      await tester.dismissFieldEditor();

      // Open media cell editor
      await tester.tapCellInGrid(rowIndex: 0, fieldType: FieldType.Media);
      await tester.findMediaCellEditor(findsOneWidget);

      // Prepare files for upload from local
      final firstImage =
          await rootBundle.load('assets/test/images/sample.jpeg');
      final secondImage =
          await rootBundle.load('assets/test/images/sample.gif');
      final tempDirectory = await getTemporaryDirectory();

      final firstImagePath = p.join(tempDirectory.path, 'sample.jpeg');
      final firstFile = File(firstImagePath)
        ..writeAsBytesSync(firstImage.buffer.asUint8List());

      final secondImagePath = p.join(tempDirectory.path, 'sample.gif');
      final secondFile = File(secondImagePath)
        ..writeAsBytesSync(secondImage.buffer.asUint8List());

      mockPickFilePaths(paths: [firstImagePath, secondImagePath]);
      await getIt<KeyValueStorage>().set(KVKeys.kCloudType, '0');

      // Click on add file button in the Media Cell Editor
      await tester.tap(find.text(LocaleKeys.grid_media_addFileOrImage.tr()));
      await tester.pumpAndSettle();

      // Tap on the upload interaction
      await tester.tapFileUploadHint();

      // Expect two files
      expect(find.byType(RenderMedia), findsNWidgets(2));

      // Tap on the three dots menu for the first RenderMedia
      final mediaMenuFinder = find.descendant(
        of: find.byType(RenderMedia),
        matching: find.byFlowySvg(FlowySvgs.three_dots_s),
      );

      await tester.tap(mediaMenuFinder.first);
      await tester.pumpAndSettle();

      // Tap on the delete button
      await tester.tap(find.text(LocaleKeys.grid_media_delete.tr()));
      await tester.pumpAndSettle();

      // Tap on Delete button in the confirmation dialog
      await tester.tap(
        find.descendant(
          of: find.byType(SpaceCancelOrConfirmButton),
          matching: find.text(LocaleKeys.grid_media_delete.tr()),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Expect one file
      expect(find.byType(RenderMedia), findsOneWidget);

      // Remove the temp files
      await Future.wait([firstFile.delete(), secondFile.delete()]);
    });

    testWidgets('hide file names', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);

      // Invoke the field editor
      await tester.tapGridFieldWithName('Type');
      await tester.tapEditFieldButton();

      // Change to media type
      await tester.tapSwitchFieldTypeButton();
      await tester.selectFieldType(FieldType.Media);
      await tester.dismissFieldEditor();

      // Open media cell editor
      await tester.tapCellInGrid(rowIndex: 0, fieldType: FieldType.Media);
      await tester.findMediaCellEditor(findsOneWidget);

      // Prepare files for upload from local
      final firstImage =
          await rootBundle.load('assets/test/images/sample.jpeg');
      final secondImage =
          await rootBundle.load('assets/test/images/sample.gif');
      final tempDirectory = await getTemporaryDirectory();

      final firstImagePath = p.join(tempDirectory.path, 'sample.jpeg');
      final firstFile = File(firstImagePath)
        ..writeAsBytesSync(firstImage.buffer.asUint8List());

      final secondImagePath = p.join(tempDirectory.path, 'sample.gif');
      final secondFile = File(secondImagePath)
        ..writeAsBytesSync(secondImage.buffer.asUint8List());

      mockPickFilePaths(paths: [firstImagePath, secondImagePath]);
      await getIt<KeyValueStorage>().set(KVKeys.kCloudType, '0');

      // Click on add file button in the Media Cell Editor
      await tester.tap(find.text(LocaleKeys.grid_media_addFileOrImage.tr()));
      await tester.pumpAndSettle();

      // Tap on the upload interaction
      await tester.tapFileUploadHint();

      // Expect two files
      expect(find.byType(RenderMedia), findsNWidgets(2));

      await tester.dismissCellEditor();
      await tester.pumpAndSettle();

      // Open first row in row detail view then toggle hide file names
      await tester.openFirstRowDetailPage();
      await tester.pumpAndSettle();

      // Expect file names to be shown
      expect(find.text('sample.jpeg'), findsOneWidget);
      expect(find.text('sample.gif'), findsOneWidget);

      await tester.tapGridFieldWithNameInRowDetailPage('Type');
      await tester.pumpAndSettle();

      // Toggle hide file names
      await tester.tap(find.byType(Toggle));
      await tester.pumpAndSettle();

      await tester.dismissRowDetailPage();
      await tester.pumpAndSettle();

      // Expect file names to be hidden
      expect(find.text('sample.jpeg'), findsNothing);
      expect(find.text('sample.gif'), findsNothing);

      // Remove the temp files
      await Future.wait([firstFile.delete(), secondFile.delete()]);
    });
  });
}

extension _TapFileUploadHint on WidgetTester {
  Future<void> tapFileUploadHint() async {
    final finder = find.byWidgetPredicate(
      (w) =>
          w is RichText &&
          w.text.toPlainText().contains(
                LocaleKeys.document_plugins_file_fileUploadHint.tr(),
              ),
    );
    await tap(finder);
    await pumpAndSettle(const Duration(seconds: 2));
  }
}
