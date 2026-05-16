import 'dart:convert';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/base/icon/icon_widget.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/emoji_picker_button.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/callout/callout_block_component.dart';
import 'package:appflowy/shared/icon_emoji_picker/icon_picker.dart';
import 'package:appflowy/shared/icon_emoji_picker/recent_icons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/emoji.dart';
import '../../shared/util.dart';

void main() {
  setUpAll(() {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    RecentIcons.enable = false;
  });

  tearDownAll(() {
    RecentIcons.enable = true;
  });

  testWidgets('callout with emoji icon picker', (tester) async {
    await tester.initializeAppFlowy();
    await tester.tapAnonymousSignInButton();
    final emojiIconData = await tester.loadIcon();

    /// create a new document
    await tester.createNewPageWithNameUnderParent();

    /// tap the first line of the document
    await tester.editor.tapLineOfEditorAt(0);

    /// create callout
    await tester.editor.showSlashMenu();
    await tester.pumpAndSettle();
    await tester.editor.tapSlashMenuItemWithName(
      LocaleKeys.document_slashMenu_name_callout.tr(),
    );

    /// select an icon
    final emojiPickerButton = find.descendant(
      of: find.byType(CalloutBlockComponentWidget),
      matching: find.byType(EmojiPickerButton),
    );
    await tester.tapButton(emojiPickerButton);
    await tester.tapIcon(emojiIconData);

    /// verification results
    final iconData = IconsData.fromJson(jsonDecode(emojiIconData.emoji));
    final iconWidget = find
        .descendant(
          of: emojiPickerButton,
          matching: find.byType(IconWidget),
        )
        .evaluate()
        .first
        .widget as IconWidget;
    final iconWidgetData = iconWidget.iconsData;
    expect(iconWidgetData.svgString, iconData.svgString);
    expect(iconWidgetData.iconName, iconData.iconName);
    expect(iconWidgetData.groupName, iconData.groupName);
  });
}
