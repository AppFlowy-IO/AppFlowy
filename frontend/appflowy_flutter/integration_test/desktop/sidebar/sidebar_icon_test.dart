import 'package:appflowy/plugins/base/emoji/emoji_picker.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/emoji_picker_button.dart';
import 'package:appflowy/shared/icon_emoji_picker/flowy_icon_emoji_picker.dart';
import 'package:appflowy/shared/icon_emoji_picker/recent_icons.dart';
import 'package:appflowy/workspace/presentation/widgets/view_title_bar.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flowy_infra_ui/style_widget/text_field.dart';
import 'package:flowy_svg/flowy_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

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

  testWidgets('Update page custom image icon in title bar', (tester) async {
    await tester.initializeAppFlowy();
    await tester.tapAnonymousSignInButton();

    /// prepare local image
    final iconData = await tester.prepareImageIcon();

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

  testWidgets('Update page custom svg icon in title bar', (tester) async {
    await tester.initializeAppFlowy();
    await tester.tapAnonymousSignInButton();

    /// prepare local image
    final iconData = await tester.prepareSvgIcon();

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

  testWidgets('Update page custom svg icon in title bar by pasting a link',
      (tester) async {
    await tester.initializeAppFlowy();
    await tester.tapAnonymousSignInButton();

    /// prepare local image
    const testIconLink =
        'https://beta.appflowy.cloud/api/file_storage/008e6f23-516b-4d8d-b1fe-2b75c51eee26/v1/blob/6bdf8dff%2D0e54%2D4d35%2D9981%2Dcde68bef1141/BGpLnRtb3AGBNgSJsceu70j83zevYKrMLzqsTIJcBeI=.svg';

    /// create document, board, grid and calendar views
    for (final value in ViewLayoutPB.values) {
      if (value == ViewLayoutPB.Chat) {
        continue;
      }

      await tester.createNewPageWithNameUnderParent(
        name: value.name,
        parentName: gettingStarted,
        layout: value,
      );

      /// update its icon
      await tester.updatePageIconInTitleBarByPasteALink(
        name: value.name,
        layout: value,
        iconLink: testIconLink,
      );

      /// check if there is a svg in page
      final pageName = tester.findPageName(
        value.name,
        layout: value,
      );
      final imageInPage = find.descendant(
        of: pageName,
        matching: find.byType(SvgPicture),
      );
      expect(imageInPage, findsOneWidget);

      /// check if there is a svg in title
      final imageInTitle = find.descendant(
        of: find.byType(ViewTitleBar),
        matching: find.byWidgetPredicate((w) {
          if (w is! SvgPicture) return false;
          final loader = w.bytesLoader;
          if (loader is! SvgFileLoader) return false;
          return loader.file.path.endsWith('.svg');
        }),
      );
      expect(imageInTitle, findsOneWidget);
    }
  });
}
