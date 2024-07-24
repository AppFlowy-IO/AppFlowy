import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/multi_image_block_component/multi_image_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/multi_image_block_component/multi_image_placeholder.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/multi_image_layouts.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/upload_image_menu/upload_image_menu.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/presentation/widgets/image_viewer/interactive_image_viewer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../shared/mock/mock_file_picker.dart';
import '../../shared/util.dart';

void main() {
  setUp(() {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('multi image block in document', () {
    testWidgets('insert two images from local file and use interactive viewer',
        (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // create a new document
      await tester.createNewPageWithNameUnderParent(
        name: 'multi image block test',
      );

      // tap the first line of the document
      await tester.editor.tapLineOfEditorAt(0);
      await tester.editor.showSlashMenu();
      await tester.editor.tapSlashMenuItemWithName('Photo gallery');
      expect(find.byType(MultiImageBlockComponent), findsOneWidget);
      expect(find.byType(MultiImagePlaceholder), findsOneWidget);

      await tester.tap(find.byType(MultiImagePlaceholder));
      await tester.pumpAndSettle();

      expect(find.byType(UploadImageMenu), findsOneWidget);

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
      await tester.tapButtonWithName(
        LocaleKeys.document_imageBlock_upload_placeholder.tr(),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ImageBrowserLayout), findsOneWidget);
      final node = tester.editor.getCurrentEditorState().getNodeAtPath([0])!;
      expect(node.type, MultiImageBlockKeys.type);

      final data = MultiImageData.fromJson(
        node.attributes[MultiImageBlockKeys.images],
      );

      expect(data.images.length, 2);

      // Start using the interactive viewer to view the image(s)
      final imageFinder = find
          .byWidgetPredicate(
            (w) =>
                w is Image &&
                w.image is FileImage &&
                (w.image as FileImage).file.path.endsWith('.jpeg'),
          )
          .first;
      await tester.tap(imageFinder);
      await tester.pump(kDoubleTapMinTime);
      await tester.tap(imageFinder);
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveImageViewer), findsOneWidget);

      // remove the temp files
      await Future.wait([firstFile.delete(), secondFile.delete()]);
    });
  });
}
