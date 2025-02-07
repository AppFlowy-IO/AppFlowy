import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/mobile/presentation/base/view_page/app_bar_buttons.dart';
import 'package:appflowy/mobile/presentation/presentation.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/header/emoji_icon_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/page_style/_page_style_icon.dart';
import 'package:appflowy/shared/icon_emoji_picker/flowy_icon_emoji_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/emoji.dart';
import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('document title:', () {
    testWidgets('update page custom image icon in title bar', (tester) async {
      await tester.launchInAnonymousMode();

      /// prepare local image
      final iconData = await tester.prepareImageIcon();

      /// create an empty page
      await tester
          .tapButton(find.byKey(BottomNavigationBarItemType.add.valueKey));

      /// show Page style page
      await tester.tapButton(find.byType(MobileViewPageLayoutButton));
      final pageStyleIcon = find.byType(PageStyleIcon);
      final iconInPageStyleIcon = find.descendant(
        of: pageStyleIcon,
        matching: find.byType(RawEmojiIconWidget),
      );
      expect(iconInPageStyleIcon, findsNothing);

      /// show icon picker
      await tester.tapButton(pageStyleIcon);

      /// upload custom icon
      await tester.pickImage(iconData);

      /// check result
      final documentPage = find.byType(MobileDocumentScreen);
      final rawEmojiIconFinder = find
          .descendant(
            of: documentPage,
            matching: find.byType(RawEmojiIconWidget),
          )
          .last;
      final rawEmojiIconWidget =
          rawEmojiIconFinder.evaluate().first.widget as RawEmojiIconWidget;
      final iconDataInWidget = rawEmojiIconWidget.emoji;
      expect(iconDataInWidget.type, FlowyIconType.custom);
      final imageFinder =
          find.descendant(of: rawEmojiIconFinder, matching: find.byType(Image));
      expect(imageFinder, findsOneWidget);
    });

    testWidgets('update page custom svg icon in title bar', (tester) async {
      await tester.launchInAnonymousMode();

      /// prepare local image
      final iconData = await tester.prepareSvgIcon();

      /// create an empty page
      await tester
          .tapButton(find.byKey(BottomNavigationBarItemType.add.valueKey));

      /// show Page style page
      await tester.tapButton(find.byType(MobileViewPageLayoutButton));
      final pageStyleIcon = find.byType(PageStyleIcon);
      final iconInPageStyleIcon = find.descendant(
        of: pageStyleIcon,
        matching: find.byType(RawEmojiIconWidget),
      );
      expect(iconInPageStyleIcon, findsNothing);

      /// show icon picker
      await tester.tapButton(pageStyleIcon);

      /// upload custom icon
      await tester.pickImage(iconData);

      /// check result
      final documentPage = find.byType(MobileDocumentScreen);
      final rawEmojiIconFinder = find
          .descendant(
            of: documentPage,
            matching: find.byType(RawEmojiIconWidget),
          )
          .last;
      final rawEmojiIconWidget =
          rawEmojiIconFinder.evaluate().first.widget as RawEmojiIconWidget;
      final iconDataInWidget = rawEmojiIconWidget.emoji;
      expect(iconDataInWidget.type, FlowyIconType.custom);
      final svgFinder = find.descendant(
        of: rawEmojiIconFinder,
        matching: find.byType(SvgPicture),
      );
      expect(svgFinder, findsOneWidget);
    });
  });
}
