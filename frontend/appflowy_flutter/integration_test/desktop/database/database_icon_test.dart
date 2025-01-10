import 'dart:convert';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/tab_bar/desktop/tab_bar_add_button.dart';
import 'package:appflowy/plugins/database/tab_bar/desktop/tab_bar_header.dart';
import 'package:appflowy/plugins/database/widgets/database_layout_ext.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/header/emoji_icon_widget.dart';
import 'package:appflowy/shared/icon_emoji_picker/icon_picker.dart';
import 'package:appflowy/shared/icon_emoji_picker/recent_icons.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/shared/sidebar_folder.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_item.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/setting_entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
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

  testWidgets('change icon', (tester) async {
    await tester.initializeAppFlowy();
    await tester.tapAnonymousSignInButton();
    final iconData = await tester.loadIcon();

    const pageName = 'Database';
    await tester.createNewPageWithNameUnderParent(
      layout: ViewLayoutPB.Grid,
      name: pageName,
    );

    /// create board
    final addButton = find.byType(AddDatabaseViewButton);
    await tester.tapButton(addButton);
    await tester.tapButton(
      find.text(
        '${LocaleKeys.grid_createView.tr()} ${DatabaseLayoutPB.Board.layoutName}',
        findRichText: true,
      ),
    );

    /// create calendar
    await tester.tapButton(addButton);
    await tester.tapButton(
      find.text(
        '${LocaleKeys.grid_createView.tr()} ${DatabaseLayoutPB.Calendar.layoutName}',
        findRichText: true,
      ),
    );

    final databaseTabBarItem = find.byType(DatabaseTabBarItem);
    expect(databaseTabBarItem, findsNWidgets(3));
    final gridItem = databaseTabBarItem.first,
        boardItem = databaseTabBarItem.at(1),
        calendarItem = databaseTabBarItem.last;

    /// change the icon of grid
    /// the first tapping is to select specific item
    /// the second tapping is to show the menu
    await tester.tapButton(gridItem);
    await tester.tapButton(gridItem);

    /// change icon
    await tester
        .tapButton(find.text(LocaleKeys.disclosureAction_changeIcon.tr()));
    await tester.tapIcon(iconData, enableColor: false);
    final gridIcon = find.descendant(
      of: gridItem,
      matching: find.byType(RawEmojiIconWidget),
    );
    final gridIconWidget =
        gridIcon.evaluate().first.widget as RawEmojiIconWidget;
    final iconsData = IconsData.fromJson(jsonDecode(iconData.emoji));
    final gridIconsData =
        IconsData.fromJson(jsonDecode(gridIconWidget.emoji.emoji));
    expect(gridIconsData.iconName, iconsData.iconName);

    /// change the icon of board
    await tester.tapButton(boardItem);
    await tester.tapButton(boardItem);
    await tester
        .tapButton(find.text(LocaleKeys.disclosureAction_changeIcon.tr()));
    await tester.tapIcon(iconData, enableColor: false);
    final boardIcon = find.descendant(
      of: boardItem,
      matching: find.byType(RawEmojiIconWidget),
    );
    final boardIconWidget =
        boardIcon.evaluate().first.widget as RawEmojiIconWidget;
    final boardIconsData =
        IconsData.fromJson(jsonDecode(boardIconWidget.emoji.emoji));
    expect(boardIconsData.iconName, iconsData.iconName);

    /// change the icon of calendar
    await tester.tapButton(calendarItem);
    await tester.tapButton(calendarItem);
    await tester
        .tapButton(find.text(LocaleKeys.disclosureAction_changeIcon.tr()));
    await tester.tapIcon(iconData, enableColor: false);
    final calendarIcon = find.descendant(
      of: calendarItem,
      matching: find.byType(RawEmojiIconWidget),
    );
    final calendarIconWidget =
        calendarIcon.evaluate().first.widget as RawEmojiIconWidget;
    final calendarIconsData =
        IconsData.fromJson(jsonDecode(calendarIconWidget.emoji.emoji));
    expect(calendarIconsData.iconName, iconsData.iconName);
  });

  testWidgets('change database icon from sidebar', (tester) async {
    await tester.initializeAppFlowy();
    await tester.tapAnonymousSignInButton();
    final iconData = await tester.loadIcon();
    final icon = IconsData.fromJson(jsonDecode(iconData.emoji)), emoji = '😄';

    const pageName = 'Database';
    await tester.createNewPageWithNameUnderParent(
      layout: ViewLayoutPB.Grid,
      name: pageName,
    );
    final viewItem = find.descendant(
      of: find.byType(SidebarFolder),
      matching: find.byWidgetPredicate(
        (w) => w is ViewItem && w.view.name == pageName,
      ),
    );

    /// change icon to emoji
    await tester.tapButton(
      find.descendant(
        of: viewItem,
        matching: find.byType(FlowySvg),
      ),
    );
    await tester.tapEmoji(emoji);
    final iconWidget = find.descendant(
      of: viewItem,
      matching: find.byType(RawEmojiIconWidget),
    );
    expect(
      (iconWidget.evaluate().first.widget as RawEmojiIconWidget).emoji.emoji,
      emoji,
    );

    /// the icon will not be displayed in database item
    Finder databaseIcon = find.descendant(
      of: find.byType(DatabaseTabBarItem),
      matching: find.byType(FlowySvg),
    );
    expect(
      (databaseIcon.evaluate().first.widget as FlowySvg).svg,
      FlowySvgs.icon_grid_s,
    );

    /// change emoji to icon
    await tester.tapButton(iconWidget);
    await tester.tapIcon(iconData);
    expect(
      (iconWidget.evaluate().first.widget as RawEmojiIconWidget).emoji.emoji,
      iconData.emoji,
    );

    databaseIcon = find.descendant(
      of: find.byType(DatabaseTabBarItem),
      matching: find.byType(RawEmojiIconWidget),
    );
    final databaseIconWidget =
        databaseIcon.evaluate().first.widget as RawEmojiIconWidget;
    final databaseIconsData =
        IconsData.fromJson(jsonDecode(databaseIconWidget.emoji.emoji));
    expect(icon.iconContent, databaseIconsData.iconContent);
    expect(icon.color, isNotEmpty);
    expect(icon.color, databaseIconsData.color);

    /// the icon in database item should not show the color
    expect(databaseIconWidget.enableColor, false);
  });
}
