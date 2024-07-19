import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/custom_image_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/embed_image_url_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/image_placeholder.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/resizeable_image.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/unsplash_image_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/upload_image_menu.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_editor/appflowy_editor.dart'
    hide UploadImageMenu, ResizableImage;
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:run_with_network_images/run_with_network_images.dart';

import '../../shared/mock/mock_file_picker.dart';
import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  TestWidgetsFlutterBinding.ensureInitialized();

  group('image block in document', () {
    testWidgets('insert an image from local file', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // create a new document
      await tester.createNewPageWithNameUnderParent(
        name: LocaleKeys.document_plugins_image_addAnImageDesktop.tr(),
      );

      // tap the first line of the document
      await tester.editor.tapLineOfEditorAt(0);
      await tester.editor.showSlashMenu();
      await tester.editor.tapSlashMenuItemWithName('Image');
      expect(find.byType(CustomImageBlockComponent), findsOneWidget);
      expect(find.byType(ImagePlaceholder), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ImagePlaceholder),
          matching: find.byType(AppFlowyPopover),
        ),
        findsOneWidget,
      );
      expect(find.byType(UploadImageMenu), findsOneWidget);

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
    });

    testWidgets('insert an image from network', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // create a new document
      await tester.createNewPageWithNameUnderParent(
        name: LocaleKeys.document_plugins_image_addAnImageDesktop.tr(),
      );

      // tap the first line of the document
      await tester.editor.tapLineOfEditorAt(0);
      await tester.editor.showSlashMenu();
      await tester.editor.tapSlashMenuItemWithName('Image');
      expect(find.byType(CustomImageBlockComponent), findsOneWidget);
      expect(find.byType(ImagePlaceholder), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ImagePlaceholder),
          matching: find.byType(AppFlowyPopover),
        ),
        findsOneWidget,
      );
      expect(find.byType(UploadImageMenu), findsOneWidget);

      await tester.tapButtonWithName(
        LocaleKeys.document_imageBlock_embedLink_label.tr(),
      );
      const url =
          'https://images.unsplash.com/photo-1469474968028-56623f02e42e?ixlib=rb-4.0.3&q=85&fm=jpg&crop=entropy&cs=srgb&dl=david-marcu-78A265wPiO4-unsplash.jpg&w=640';
      await tester.enterText(
        find.descendant(
          of: find.byType(EmbedImageUrlWidget),
          matching: find.byType(TextField),
        ),
        url,
      );
      await tester.tapButton(
        find.descendant(
          of: find.byType(EmbedImageUrlWidget),
          matching: find.text(
            LocaleKeys.document_imageBlock_embedLink_label.tr(),
            findRichText: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ResizableImage), findsOneWidget);
      final node = tester.editor.getCurrentEditorState().getNodeAtPath([0])!;
      expect(node.type, ImageBlockKeys.type);
      expect(node.attributes[ImageBlockKeys.url], url);
    });

    testWidgets('insert an image from unsplash', (tester) async {
      await runWithNetworkImages(() async {
        await tester.initializeAppFlowy();
        await tester.tapAnonymousSignInButton();

        // create a new document
        await tester.createNewPageWithNameUnderParent(
          name: LocaleKeys.document_plugins_image_addAnImageDesktop.tr(),
        );

        // tap the first line of the document
        await tester.editor.tapLineOfEditorAt(0);
        await tester.editor.showSlashMenu();
        await tester.editor.tapSlashMenuItemWithName('Image');
        expect(find.byType(CustomImageBlockComponent), findsOneWidget);
        expect(find.byType(ImagePlaceholder), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(ImagePlaceholder),
            matching: find.byType(AppFlowyPopover),
          ),
          findsOneWidget,
        );
        expect(find.byType(UploadImageMenu), findsOneWidget);

        await tester.tapButtonWithName(
          'Unsplash',
        );
        expect(find.byType(UnsplashImageWidget), findsOneWidget);
      });
    });
  });
}
