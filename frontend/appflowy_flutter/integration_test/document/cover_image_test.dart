import 'package:appflowy/plugins/document/presentation/editor_plugins/header/document_header_node_widget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../util/emoji.dart';
import '../util/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('cover image', () {
    testWidgets('document cover tests', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      tester.expectToSeeNoDocumentCover();

      // Hover over cover toolbar to show 'Add Cover' and 'Add Icon' buttons
      await tester.editor.hoverOnCoverToolbar();
      tester.expectToSeePluginAddCoverAndIconButton();

      // Insert a document cover
      await tester.editor.tapOnAddCover();
      tester.expectToSeeDocumentCover(CoverType.asset);

      // Hover over the cover to show the 'Change Cover' and delete buttons
      await tester.editor.hoverOnCover();
      tester.expectChangeCoverAndDeleteButton();

      // Change cover to a solid color background
      await tester.editor.tapOnChangeCover();
      await tester.editor.switchSolidColorBackground();
      await tester.editor.dismissCoverPicker();
      tester.expectToSeeDocumentCover(CoverType.color);

      // Change cover to a network image
      const imageUrl =
          "https://raw.githubusercontent.com/AppFlowy-IO/AppFlowy/main/frontend/appflowy_flutter/assets/images/appflowy_launch_splash.jpg";
      await tester.editor.hoverOnCover();
      await tester.editor.tapOnChangeCover();
      await tester.editor.addNetworkImageCover(imageUrl);
      await tester.editor.switchNetworkImageCover(imageUrl);
      await tester.editor.dismissCoverPicker();
      tester.expectToSeeDocumentCover(CoverType.file);

      // Remove the cover
      await tester.editor.hoverOnCover();
      await tester.editor.tapOnRemoveCover();
      tester.expectToSeeNoDocumentCover();
    });

    testWidgets('document icon tests', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      tester.expectToSeeDocumentIcon(null);

      // Hover over cover toolbar to show the 'Add Cover' and 'Add Icon' buttons
      await tester.editor.hoverOnCoverToolbar();
      tester.expectToSeePluginAddCoverAndIconButton();

      // Insert a document icon
      await tester.editor.tapAddIconButton();
      await tester.switchToEmojiList();
      await tester.tapEmoji('😀');
      tester.expectToSeeDocumentIcon('😀');

      // Remove the document icon from the cover toolbar
      await tester.editor.hoverOnCoverToolbar();
      await tester.editor.tapRemoveIconButton();
      tester.expectToSeeDocumentIcon(null);

      // Add the icon back for further testing
      await tester.editor.hoverOnCoverToolbar();
      await tester.editor.tapAddIconButton();
      await tester.switchToEmojiList();
      await tester.tapEmoji('😀');
      tester.expectToSeeDocumentIcon('😀');

      // Change the document icon
      await tester.editor.tapOnIconWidget();
      await tester.switchToEmojiList();
      await tester.tapEmoji('😅');
      tester.expectToSeeDocumentIcon('😅');

      // Remove the document icon from the icon picker
      await tester.editor.tapOnIconWidget();
      await tester.editor.tapRemoveIconButton(isInPicker: true);
      tester.expectToSeeDocumentIcon(null);
    });

    testWidgets('icon and cover at the same time', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapGoButton();

      tester.expectToSeeDocumentIcon(null);
      tester.expectToSeeNoDocumentCover();

      // Hover over cover toolbar to show the 'Add Cover' and 'Add Icon' buttons
      await tester.editor.hoverOnCoverToolbar();
      tester.expectToSeePluginAddCoverAndIconButton();

      // Insert a document icon
      await tester.editor.tapAddIconButton();
      await tester.switchToEmojiList();
      await tester.tapEmoji('😀');

      // Insert a document cover
      await tester.editor.tapOnAddCover();

      // Expect to see the icon and cover at the same time
      tester.expectToSeeDocumentIcon('😀');
      tester.expectToSeeDocumentCover(CoverType.asset);

      // Hover over the cover toolbar and see that neither icons are shown
      await tester.editor.hoverOnCoverToolbar();
      tester.expectToSeeEmptyDocumentHeaderToolbar();
    });
  });
}
