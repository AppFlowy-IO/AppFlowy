import 'dart:io';

import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/resizeable_image.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pbenum.dart';
import 'package:appflowy_editor/appflowy_editor.dart'
    hide UploadImageMenu, ResizableImage;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../shared/constants.dart';
import '../../../shared/database_test_op.dart';
import '../../../shared/mock/mock_file_picker.dart';
import '../../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // copy link to block
  group('database image:', () {
    testWidgets('insert image', (tester) async {
      await tester.initializeAppFlowy(
        cloudType: AuthenticatorType.appflowyCloudSelfHost,
      );
      await tester.tapGoogleLoginInButton();
      await tester.expectToSeeHomePageWithGetStartedPage();

      // open the first row detail page and upload an image
      await tester.createNewPageInSpace(
        spaceName: Constants.generalSpaceName,
        layout: ViewLayoutPB.Grid,
        pageName: 'database image',
      );
      await tester.openFirstRowDetailPage();

      // insert an image block
      {
        await tester.editor.tapLineOfEditorAt(0);
        await tester.editor.showSlashMenu();
        await tester.editor.tapSlashMenuItemWithName(
          LocaleKeys.document_slashMenu_name_image.tr(),
        );
      }

      // upload an image
      {
        final image = await rootBundle.load('assets/test/images/sample.jpeg');
        final tempDirectory = await getTemporaryDirectory();
        final imagePath = p.join(tempDirectory.path, 'sample.jpeg');
        final file = File(imagePath)
          ..writeAsBytesSync(image.buffer.asUint8List());

        mockPickFilePaths(
          paths: [imagePath],
        );

        await getIt<KeyValueStorage>().set(KVKeys.kCloudType, '0');
        await tester.tapButtonWithName(
          LocaleKeys.document_imageBlock_upload_placeholder.tr(),
        );
        await tester.pumpAndSettle();
        expect(find.byType(ResizableImage), findsOneWidget);
        final node = tester.editor.getCurrentEditorState().getNodeAtPath([0])!;
        expect(node.type, ImageBlockKeys.type);
        expect(node.attributes[ImageBlockKeys.url], isNotEmpty);

        // remove the temp file
        file.deleteSync();
      }
    });
  });
}
