import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/home/space/manage_space_widget.dart';
import 'package:appflowy/mobile/presentation/home/space/mobile_space_menu.dart';
import 'package:appflowy/mobile/presentation/home/space/widgets.dart';
import 'package:appflowy/shared/icon_emoji_picker/icon_picker.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/space_icon_popup.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('space operations:', () {
    testWidgets('create a new space', (tester) async {
      await tester.initializeAppFlowy(
        cloudType: AuthenticatorType.appflowyCloudSelfHost,
      );
      await tester.tapGoogleLoginInButton();
      await tester.expectToSeeHomePageWithGetStartedPage();

      // create a new space
      // click the space menu
      final spaceMenu = find.byType(MobileSpaceMenu);
      await tester.tapButton(spaceMenu);

      // click the create a new space button
      final createNewSpaceButton = find.text(
        LocaleKeys.space_createNewSpace.tr(),
      );
      await tester.pumpUntilFound(createNewSpaceButton);
      await tester.tapButton(createNewSpaceButton);

      // input the new space name
      final inputField = find.descendant(
        of: find.byType(ManageSpaceWidget),
        matching: find.byType(TextField),
      );
      const newSpaceName = 'AppFlowy';
      await tester.enterText(inputField, newSpaceName);
      await tester.pumpAndSettle();

      // change the space permission to private
      final permissionOption = find.byType(ManageSpacePermissionOption);
      await tester.tapButton(permissionOption);
      await tester.pumpAndSettle();

      final privateOption = find.text(LocaleKeys.space_privatePermission.tr());
      await tester.tapButton(privateOption);
      await tester.pumpAndSettle();

      // change the space icon color
      final color = builtInSpaceColors[1];
      final iconOption = find.descendant(
        of: find.byType(ManageSpaceIconOption),
        matching: find.byWidgetPredicate(
          (w) => w is SpaceColorItem && w.color == color,
        ),
      );
      await tester.tapButton(iconOption);
      await tester.pumpAndSettle();

      // change the space icon
      final icon = kIconGroups![0].icons[1];
      final iconItem = find.descendant(
        of: find.byType(ManageSpaceIconOption),
        matching: find.byWidgetPredicate(
          (w) => w is SpaceIconItem && w.icon == icon,
        ),
      );
      await tester.tapButton(iconItem);
      await tester.pumpAndSettle();

      // click the done button
      final doneButton = find.text(LocaleKeys.button_done.tr());
      await tester.tapButton(doneButton);
      await tester.pumpAndSettle();

      // wait 100ms for the space to be created
      await tester.wait(100);

      // verify the space is created
      await tester.tapButton(spaceMenu);
      final spaceItems = find.byType(MobileSpaceMenuItem);
      // expect to see 3 space items, 2 are built-in, 1 is the new space
      expect(spaceItems, findsNWidgets(3));
      // convert the space item to a widget
      final spaceWidget =
          tester.widgetList<MobileSpaceMenuItem>(spaceItems).last;
      final space = spaceWidget.space;
      expect(space.name, newSpaceName);
      expect(space.spacePermission, SpacePermission.private);
      expect(space.spaceIcon, icon.iconPath);
      expect(space.spaceIconColor, color);
    });
  });
}
