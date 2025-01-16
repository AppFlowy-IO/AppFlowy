import 'dart:io';

import 'package:appflowy/plugins/base/emoji/emoji_picker.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/emoji_picker_button.dart';
import 'package:appflowy/shared/icon_emoji_picker/flowy_icon_emoji_picker.dart';
import 'package:appflowy/shared/icon_emoji_picker/recent_icons.dart';
import 'package:appflowy/workspace/presentation/widgets/view_title_bar.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flowy_infra_ui/style_widget/text_field.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../shared/base.dart';
import '../../shared/common_operations.dart';
import '../../shared/emoji.dart';
import '../../shared/expectation.dart';

void main() {
  final emoji = EmojiIconData.emoji('😁');

  setUpAll(() {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    RecentIcons.enable = false;
  });

  tearDownAll(() {
    RecentIcons.enable = true;
  });

  testWidgets('Update page emoji in sidebar', (tester) async {
    await tester.initializeAppFlowy();
    await tester.tapAnonymousSignInButton();

    // create document, board, grid and calendar views
    for (final value in ViewLayoutPB.values) {
      if (value == ViewLayoutPB.Chat) {
        continue;
      }
      await tester.createNewPageWithNameUnderParent(
        name: value.name,
        parentName: gettingStarted,
        layout: value,
      );

      // update its emoji
      await tester.updatePageIconInSidebarByName(
        name: value.name,
        parentName: gettingStarted,
        layout: value,
        icon: emoji,
      );

      tester.expectViewHasIcon(
        value.name,
        value,
        emoji,
      );
    }
  });

  testWidgets('Update page emoji in title bar', (tester) async {
    await tester.initializeAppFlowy();
    await tester.tapAnonymousSignInButton();

    // create document, board, grid and calendar views
    for (final value in ViewLayoutPB.values) {
      if (value == ViewLayoutPB.Chat) {
        continue;
      }

      await tester.createNewPageWithNameUnderParent(
        name: value.name,
        parentName: gettingStarted,
        layout: value,
      );

      // update its emoji
      await tester.updatePageIconInTitleBarByName(
        name: value.name,
        layout: value,
        icon: emoji,
      );

      tester.expectViewHasIcon(
        value.name,
        value,
        emoji,
      );

      tester.expectViewTitleHasIcon(
        value.name,
        value,
        emoji,
      );
    }
  });

  testWidgets('Emoji Search Bar Get Focus', (tester) async {
    await tester.initializeAppFlowy();
    await tester.tapAnonymousSignInButton();

    // create document, board, grid and calendar views
    for (final value in ViewLayoutPB.values) {
      if (value == ViewLayoutPB.Chat) {
        continue;
      }

      await tester.createNewPageWithNameUnderParent(
        name: value.name,
        parentName: gettingStarted,
        layout: value,
      );

      await tester.openPage(
        value.name,
        layout: value,
      );
      final title = find.descendant(
        of: find.byType(ViewTitleBar),
        matching: find.text(value.name),
      );
      await tester.tapButton(title);
      await tester.tapButton(find.byType(EmojiPickerButton));

      final emojiPicker = find.byType(FlowyEmojiPicker);
      expect(emojiPicker, findsOneWidget);
      final textField = find.descendant(
        of: emojiPicker,
        matching: find.byType(FlowyTextField),
      );
      expect(textField, findsOneWidget);
      final textFieldWidget =
          textField.evaluate().first.widget as FlowyTextField;
      assert(textFieldWidget.focusNode!.hasFocus);
      await tester.tapEmoji(emoji.emoji);
      await tester.pumpAndSettle();
      tester.expectViewHasIcon(
        value.name,
        value,
        emoji,
      );
    }
  });

  testWidgets('Update page icon in sidebar', (tester) async {
    await tester.initializeAppFlowy();
    await tester.tapAnonymousSignInButton();
    final iconData = await tester.loadIcon();

    // create document, board, grid and calendar views
    for (final value in ViewLayoutPB.values) {
      if (value == ViewLayoutPB.Chat) {
        continue;
      }
      await tester.createNewPageWithNameUnderParent(
        name: value.name,
        parentName: gettingStarted,
        layout: value,
      );

      // update its icon
      await tester.updatePageIconInSidebarByName(
        name: value.name,
        parentName: gettingStarted,
        layout: value,
        icon: iconData,
      );

      tester.expectViewHasIcon(
        value.name,
        value,
        iconData,
      );
    }
  });

  testWidgets('Update page icon in title bar', (tester) async {
    await tester.initializeAppFlowy();
    await tester.tapAnonymousSignInButton();
    final iconData = await tester.loadIcon();

    // create document, board, grid and calendar views
    for (final value in ViewLayoutPB.values) {
      if (value == ViewLayoutPB.Chat) {
        continue;
      }

      await tester.createNewPageWithNameUnderParent(
        name: value.name,
        parentName: gettingStarted,
        layout: value,
      );

      // update its icon
      await tester.updatePageIconInTitleBarByName(
        name: value.name,
        layout: value,
        icon: iconData,
      );

      tester.expectViewHasIcon(
        value.name,
        value,
        iconData,
      );

      tester.expectViewTitleHasIcon(
        value.name,
        value,
        iconData,
      );
    }
  });

  testWidgets('Update page custom icon in title bar', (tester) async {
    await tester.initializeAppFlowy();
    await tester.tapAnonymousSignInButton();

    /// prepare local image
    final imagePath = await rootBundle.load('assets/test/images/sample.jpeg');
    final tempDirectory = await getTemporaryDirectory();
    final localImagePath = p.join(tempDirectory.path, 'sample.jpeg');
    final imageFile = File(localImagePath)
      ..writeAsBytesSync(imagePath.buffer.asUint8List());
    final iconData = EmojiIconData.custom(imageFile.path);

    // create document, board, grid and calendar views
    for (final value in ViewLayoutPB.values) {
      if (value == ViewLayoutPB.Chat) {
        continue;
      }

      await tester.createNewPageWithNameUnderParent(
        name: value.name,
        parentName: gettingStarted,
        layout: value,
      );

      // update its icon
      await tester.updatePageIconInTitleBarByName(
        name: value.name,
        layout: value,
        icon: iconData,
      );

      tester.expectViewHasIcon(
        value.name,
        value,
        iconData,
      );

      tester.expectViewTitleHasIcon(
        value.name,
        value,
        iconData,
      );
    }
  });
}
