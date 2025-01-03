import 'dart:convert';

import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/shared/icon_emoji_picker/flowy_icon_emoji_picker.dart';
import 'package:appflowy/shared/icon_emoji_picker/icon_picker.dart';
import 'package:appflowy/shared/icon_emoji_picker/recent_icons.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/sidebar_space_header.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/space_action_type.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/space_more_popup.dart';
import 'package:flowy_svg/flowy_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../../shared/emoji.dart';
import '../../../shared/util.dart';

void main() {
  setUpAll(() {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    RecentIcons.enable = false;
  });

  tearDownAll(() {
    RecentIcons.enable = true;
  });

  testWidgets('Change slide bar space icon', (tester) async {
    await tester.initializeAppFlowy(
      cloudType: AuthenticatorType.appflowyCloudSelfHost,
    );
    await tester.tapGoogleLoginInButton();
    await tester.expectToSeeHomePageWithGetStartedPage();
    final emojiIconData = await tester.loadIcon();
    final firstIcon = IconsData.fromJson(jsonDecode(emojiIconData.emoji));

    await tester.hoverOnWidget(
      find.byType(SidebarSpaceHeader),
      onHover: () async {
        final moreOption = find.byType(SpaceMorePopup);
        await tester.tapButton(moreOption);
        expect(find.byType(FlowyIconEmojiPicker), findsNothing);
        await tester.tapSvgButton(SpaceMoreActionType.changeIcon.leftIconSvg);
        expect(find.byType(FlowyIconEmojiPicker), findsOneWidget);
      },
    );

    final icons = find.byWidgetPredicate(
      (w) => w is FlowySvg && w.svgString == firstIcon.iconContent,
    );
    expect(icons, findsOneWidget);
    await tester.tapIcon(EmojiIconData.icon(firstIcon));

    final spaceHeader = find.byType(SidebarSpaceHeader);
    final spaceIcon = find.descendant(
      of: spaceHeader,
      matching: find.byWidgetPredicate(
        (w) => w is FlowySvg && w.svgString == firstIcon.iconContent,
      ),
    );
    expect(spaceIcon, findsOneWidget);
  });
}
