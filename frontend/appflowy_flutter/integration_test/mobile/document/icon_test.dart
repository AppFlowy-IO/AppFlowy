import 'dart:io';

import 'package:appflowy/mobile/presentation/base/view_page/app_bar_buttons.dart';
import 'package:appflowy/mobile/presentation/presentation.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/header/emoji_icon_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/page_style/_page_style_icon.dart';
import 'package:appflowy/shared/icon_emoji_picker/flowy_icon_emoji_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../shared/emoji.dart';
import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('document title:', () {
    testWidgets('update page custom icon in title bar', (tester) async {
      await tester.launchInAnonymousMode();

      /// prepare local image
      final imagePath = await rootBundle.load('assets/test/images/sample.jpeg');
      final tempDirectory = await getTemporaryDirectory();
      final localImagePath = p.join(tempDirectory.path, 'sample.jpeg');
      final imageFile = File(localImagePath)
        ..writeAsBytesSync(imagePath.buffer.asUint8List());
      final iconData = EmojiIconData.custom(imageFile.path);

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
      final rawEmojiIconWidget = find
          .descendant(
            of: documentPage,
            matching: find.byType(RawEmojiIconWidget),
          )
          .evaluate()
          .first
          .widget as RawEmojiIconWidget;
      final iconDataInWidget = rawEmojiIconWidget.emoji;
      expect(iconDataInWidget.type, FlowyIconType.custom);
    });
  });
}
