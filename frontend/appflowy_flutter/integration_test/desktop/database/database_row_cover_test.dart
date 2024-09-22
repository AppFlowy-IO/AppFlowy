import 'dart:io';

import 'package:flutter/services.dart';

import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/widgets/card/card.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/media_cell_editor.dart';
import 'package:appflowy/plugins/database/widgets/row/row_banner.dart';
import 'package:appflowy/shared/af_image.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pbenum.dart';
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

  group('database row cover', () {
    testWidgets('add image to media field and check if cover is set (grid)',
        (tester) async {
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

      // Prepare file for upload from local
      final image = await rootBundle.load('assets/test/images/sample.jpeg');
      final tempDirectory = await getTemporaryDirectory();

      final imagePath = p.join(tempDirectory.path, 'sample.jpeg');
      final file = File(imagePath)
        ..writeAsBytesSync(image.buffer.asUint8List());

      mockPickFilePaths(paths: [imagePath]);
      await getIt<KeyValueStorage>().set(KVKeys.kCloudType, '0');

      // Open media cell editor
      await tester.tapCellInGrid(rowIndex: 0, fieldType: FieldType.Media);
      await tester.findMediaCellEditor(findsOneWidget);

      // Click on add file button in the Media Cell Editor
      await tester.tap(find.text(LocaleKeys.grid_media_addFileOrImage.tr()));
      await tester.pumpAndSettle();

      // Tap on the upload interaction
      await tester.tapButtonWithName(
        LocaleKeys.document_plugins_file_fileUploadHint.tr(),
      );

      // Expect one file
      expect(find.byType(RenderMedia), findsOneWidget);

      // Close cell editor
      await tester.dismissCellEditor();

      // Open first row in row detail view
      await tester.openFirstRowDetailPage();
      await tester.pumpAndSettle();

      // Expect a cover to be shown
      expect(find.byType(BannerCover), findsOneWidget);

      // Remove the temp file
      await Future.wait([file.delete()]);
    });

    testWidgets('upload and remove cover from Row Detail Card', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Grid);

      // Open first row in row detail view
      await tester.openFirstRowDetailPage();
      await tester.pumpAndSettle();

      // Expect no cover (BannerCover is always in the Widget tree - thus check AFImage)
      expect(find.byType(AFImage), findsNothing);

      // Hover on RowBanner to show Add Cover button
      await tester.hoverRowBanner();

      // Click on Add Cover button
      await tester.tapAddCoverButton();

      // Prepare image for upload from local
      final image = await rootBundle.load('assets/test/images/sample.jpeg');
      final tempDirectory = await getTemporaryDirectory();
      final imagePath = p.join(tempDirectory.path, 'sample.jpeg');
      final file = File(imagePath)
        ..writeAsBytesSync(image.buffer.asUint8List());

      mockPickFilePaths(paths: [imagePath]);
      await getIt<KeyValueStorage>().set(KVKeys.kCloudType, '0');

      // Tap on the upload image button
      await tester.tapButtonWithName(
        LocaleKeys.document_imageBlock_upload_placeholder.tr(),
      );
      await tester.pumpAndSettle();

      // Expect a cover to be shown
      expect(find.byType(AFImage), findsOneWidget);

      // Tap on the delete cover button
      await tester.tapButtonWithName(
        LocaleKeys.document_plugins_cover_removeCover.tr(),
      );
      await tester.pumpAndSettle();

      // Expect no cover to be shown
      expect(find.byType(AFImage), findsNothing);

      // Remove the temp file
      await Future.wait([file.delete()]);
    });

    testWidgets('upload cover and check in Board', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      await tester.createNewPageWithNameUnderParent(layout: ViewLayoutPB.Board);

      // Open "Card 1"
      await tester.tap(find.text('Card 1'));
      await tester.pumpAndSettle();

      // Expect no cover (BannerCover is always in the Widget tree - thus check AFImage)
      expect(find.byType(AFImage), findsNothing);

      // Hover on RowBanner to show Add Cover button
      await tester.hoverRowBanner();

      // Click on Add Cover button
      await tester.tapAddCoverButton();

      // Prepare image for upload from local
      final image = await rootBundle.load('assets/test/images/sample.jpeg');
      final tempDirectory = await getTemporaryDirectory();
      final imagePath = p.join(tempDirectory.path, 'sample.jpeg');
      final file = File(imagePath)
        ..writeAsBytesSync(image.buffer.asUint8List());

      mockPickFilePaths(paths: [imagePath]);
      await getIt<KeyValueStorage>().set(KVKeys.kCloudType, '0');

      // Tap on the upload image button
      await tester.tapButtonWithName(
        LocaleKeys.document_imageBlock_upload_placeholder.tr(),
      );
      await tester.pumpAndSettle();

      // Dismiss Row Detail Page
      await tester.dismissRowDetailPage();

      // Expect a cover to be shown in CardCover
      expect(
        find.descendant(
          of: find.byType(CardCover),
          matching: find.byType(AFImage),
        ),
        findsOneWidget,
      );

      // Remove the temp file
      await Future.wait([file.delete()]);
    });
  });
}
