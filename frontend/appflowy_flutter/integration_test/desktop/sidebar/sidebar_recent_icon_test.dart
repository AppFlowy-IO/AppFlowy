import 'package:appflowy/plugins/document/presentation/editor_plugins/base/emoji_picker_button.dart';
import 'package:appflowy/shared/icon_emoji_picker/flowy_icon_emoji_picker.dart';
import 'package:appflowy/shared/icon_emoji_picker/icon.dart';
import 'package:appflowy/shared/icon_emoji_picker/icon_picker.dart';
import 'package:appflowy/shared/icon_emoji_picker/recent_icons.dart';
import 'package:appflowy/shared/icon_emoji_picker/tab.dart';
import 'package:appflowy/workspace/presentation/widgets/view_title_bar.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/base.dart';
import '../../shared/common_operations.dart';
import '../../shared/expectation.dart';

void main() {
  testWidgets('Skip the empty group name icon in recent icons', (tester) async {
    await tester.initializeAppFlowy();
    await tester.tapAnonymousSignInButton();

    /// clear local data
    RecentIcons.clear();
    await loadIconGroups();
    final groups = kIconGroups!;
    final List<RecentIcon> localIcons = [];
    for (final e in groups) {
      localIcons.addAll(e.icons.map((e) => RecentIcon(e, e.name)).toList());
    }
    await RecentIcons.putIcon(RecentIcon(localIcons.first.icon, ''));
    await tester.openPage(gettingStarted);
    final title = find.descendant(
      of: find.byType(ViewTitleBar),
      matching: find.text(gettingStarted),
    );
    await tester.tapButton(title);

    /// tap emoji picker button
    await tester.tapButton(find.byType(EmojiPickerButton));
    expect(find.byType(FlowyIconEmojiPicker), findsOneWidget);

    /// tap icon tab
    final pickTab = find.byType(PickerTab);
    final iconTab = find.descendant(
      of: pickTab,
      matching: find.text(PickerTabType.icon.tr),
    );
    await tester.tapButton(iconTab);

    expect(find.byType(FlowyIconPicker), findsOneWidget);

    /// no recent icons
    final recentText = find.descendant(
      of: find.byType(FlowyIconPicker),
      matching: find.text('Recent'),
    );
    expect(recentText, findsNothing);
  });
}
