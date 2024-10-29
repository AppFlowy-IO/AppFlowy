import 'dart:io';

import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/multi_image_block_component/image_render.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/multi_image_block_component/layouts/image_browser_layout.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/multi_image_block_component/multi_image_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/multi_image_block_component/multi_image_placeholder.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/upload_image_menu/upload_image_menu.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/upload_image_menu/widgets/embed_image_url_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/shared/appflowy_network_image.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/presentation/widgets/image_viewer/interactive_image_toolbar.dart';
import 'package:appflowy/workspace/presentation/widgets/image_viewer/interactive_image_viewer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    testWidgets('insert images from local and use interactive viewer',
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
      await tester.editor.tapSlashMenuItemWithName(
        LocaleKeys.document_slashMenu_name_photoGallery.tr(),
      );
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

      final ivFinder = find.byType(InteractiveImageViewer);
      expect(ivFinder, findsOneWidget);

      // go to next image
      await tester.tap(find.byFlowySvg(FlowySvgs.arrow_right_s));
      await tester.pumpAndSettle();

      // Expect image to end with .gif
      final gifImageFinder = find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is FileImage &&
            (w.image as FileImage).file.path.endsWith('.gif'),
      );

      gifImageFinder.evaluate();
      expect(gifImageFinder.found.length, 2);

      // go to previous image
      await tester.tap(find.byFlowySvg(FlowySvgs.arrow_left_s));
      await tester.pumpAndSettle();

      gifImageFinder.evaluate();
      expect(gifImageFinder.found.length, 1);

      // remove the temp files
      await Future.wait([firstFile.delete(), secondFile.delete()]);
    });

    testWidgets('insert and delete images from network', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // create a new document
      await tester.createNewPageWithNameUnderParent(
        name: 'multi image block test',
      );

      // tap the first line of the document
      await tester.editor.tapLineOfEditorAt(0);
      await tester.editor.showSlashMenu();
      await tester.editor.tapSlashMenuItemWithName(
        LocaleKeys.document_slashMenu_name_photoGallery.tr(),
        offset: 100,
      );
      expect(find.byType(MultiImageBlockComponent), findsOneWidget);
      expect(find.byType(MultiImagePlaceholder), findsOneWidget);

      await tester.tap(find.byType(MultiImagePlaceholder));
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

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

      expect(find.byType(ImageBrowserLayout), findsOneWidget);
      final node = tester.editor.getCurrentEditorState().getNodeAtPath([0])!;
      expect(node.type, MultiImageBlockKeys.type);

      final data = MultiImageData.fromJson(
        node.attributes[MultiImageBlockKeys.images],
      );

      expect(data.images.length, 1);

      final imageFinder = find
          .byWidgetPredicate(
            (w) => w is FlowyNetworkImage && w.url == url,
          )
          .first;

      // Insert two images from network
      for (int i = 0; i < 2; i++) {
        // Hover on the image to show the image toolbar
        await tester.hoverOnWidget(
          imageFinder,
          onHover: () async {
            // Click on the add
            final addFinder = find.descendant(
              of: find.byType(MultiImageMenu),
              matching: find.byFlowySvg(FlowySvgs.add_s),
            );

            expect(addFinder, findsOneWidget);
            await tester.tap(addFinder);
            await tester.pumpAndSettle();

            await tester.tapButtonWithName(
              LocaleKeys.document_imageBlock_embedLink_label.tr(),
            );

            await tester.enterText(
              find.descendant(
                of: find.byType(EmbedImageUrlWidget),
                matching: find.byType(TextField),
              ),
              url,
            );
            await tester.pumpAndSettle();

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
          },
        );
      }

      await tester.pumpAndSettle();

      // There should be 4 images visible now, where 2 are thumbnails
      expect(find.byType(ThumbnailItem), findsNWidgets(3));

      // And all three use ImageRender
      expect(find.byType(ImageRender), findsNWidgets(4));

      // Hover on and delete the first thumbnail image
      await tester.hoverOnWidget(find.byType(ThumbnailItem).first);

      final deleteFinder = find
          .descendant(
            of: find.byType(ThumbnailItem),
            matching: find.byFlowySvg(FlowySvgs.delete_s),
          )
          .first;

      expect(deleteFinder, findsOneWidget);
      await tester.tap(deleteFinder);
      await tester.pumpAndSettle();

      expect(find.byType(ImageRender), findsNWidgets(3));

      // Delete one from interactive viewer
      await tester.tap(imageFinder);
      await tester.pump(kDoubleTapMinTime);
      await tester.tap(imageFinder);
      await tester.pumpAndSettle();

      final ivFinder = find.byType(InteractiveImageViewer);
      expect(ivFinder, findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(InteractiveImageToolbar),
          matching: find.byFlowySvg(FlowySvgs.delete_s),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveImageViewer), findsNothing);

      // There should be 1 image and the thumbnail for said image still visible
      expect(find.byType(ImageRender), findsNWidgets(2));
    });
  });
}
