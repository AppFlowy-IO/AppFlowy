import 'package:appflowy/shared/icon_emoji_picker/flowy_icon_emoji_picker.dart';
import 'package:appflowy/shared/icon_emoji_picker/icon_picker.dart';
import 'package:appflowy/shared/icon_emoji_picker/recent_icons.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/space_icon_popup.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/base.dart';
import '../../shared/common_operations.dart';
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

  Future<EmojiIconData> loadIcon() async {
    await loadIconGroups();
    final groups = kIconGroups!;
    final firstGroup = groups.first;
    final firstIcon = firstGroup.icons.first;
    return EmojiIconData.icon(
      IconsData(
        firstGroup.name,
        firstIcon.content,
        firstIcon.name,
        builtInSpaceColors.first,
      ),
    );
  }

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

  testWidgets('Update page icon in sidebar', (tester) async {
    await tester.initializeAppFlowy();
    await tester.tapAnonymousSignInButton();
    final iconData = await loadIcon();

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
    final iconData = await loadIcon();

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
