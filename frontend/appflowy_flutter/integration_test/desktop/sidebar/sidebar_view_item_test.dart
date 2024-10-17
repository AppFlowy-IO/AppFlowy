import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/base/emoji/emoji_picker.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/emoji.dart';
import '../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Sidebar view item tests', () {
    testWidgets('Access view item context menu by right click', (tester) async {
      await tester.initializeAppFlowy();
      await tester.tapAnonymousSignInButton();

      // Right click on the view item and change icon
      await tester.tap(find.byType(ViewItem), buttons: kSecondaryButton);
      await tester.pumpAndSettle();

      // Change icon
      final changeIconButton =
          find.text(LocaleKeys.document_plugins_cover_changeIcon.tr());

      await tester.tapButton(changeIconButton);
      await tester.pumpUntilFound(find.byType(FlowyEmojiPicker));

      const emoji = '😁';
      await tester.tapEmoji(emoji);
      await tester.pumpAndSettle();

      tester.expectViewHasIcon(gettingStarted, ViewLayoutPB.Document, emoji);
    });
  });
}
