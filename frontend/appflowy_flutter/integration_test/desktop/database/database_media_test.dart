import 'dart:io';

import 'package:flutter/services.dart';

import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/media_cell_editor.dart';
import 'package:appflowy/startup/startup.dart';
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
    testWidgets('add media field and add files', (tester) async {
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

      // Tap on the upload interaction
      await tester.tapButtonWithName(
        LocaleKeys.document_plugins_file_fileUploadHint.tr(),
      );
      await tester.pumpAndSettle();

      // Expect one file
      expect(find.byType(RenderMedia), findsOneWidget);

      // Mock second file
      mockPickFilePaths(paths: [secondImagePath]);

      // Click on add file button in the Media Cell Editor
      await tester.tap(find.text(LocaleKeys.grid_media_addFileOrImage.tr()));

      // Tap on the upload interaction
      await tester.tapButtonWithName(
        LocaleKeys.document_plugins_file_fileUploadHint.tr(),
      );
      await tester.pumpAndSettle();

      // Expect two files
      expect(find.byType(RenderMedia), findsNWidgets(2));

      // Remove the temp files
      await Future.wait([firstFile.delete(), secondFile.delete()]);
    });
  });
}
