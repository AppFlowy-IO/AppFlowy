import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/home/space/manage_space_widget.dart';
import 'package:appflowy/mobile/presentation/home/space/mobile_space_header.dart';
import 'package:appflowy/mobile/presentation/home/space/mobile_space_menu.dart';
import 'package:appflowy/mobile/presentation/home/space/space_menu_bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/home/space/widgets.dart';
import 'package:appflowy/mobile/presentation/home/workspaces/create_workspace_menu.dart';
import 'package:appflowy/shared/icon_emoji_picker/icon_picker.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/experimental/bloc/space/space_bloc.dart';
import 'package:appflowy/workspace/application/view/folder_view_ext.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/space_icon_popup.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../../shared/util.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('space operations:', () {
    Future<void> openSpaceMenu(WidgetTester tester) async {
      final spaceHeader = find.byType(MobileSpaceHeader);
      await tester.tapButton(spaceHeader);
      await tester.pumpUntilFound(find.byType(MobileSpaceMenu));
    }

    Future<void> openSpaceMenuMoreOptions(
      WidgetTester tester,
      FolderViewPB space,
    ) async {
      final spaceMenuItemTrailing = find.byWidgetPredicate(
        (w) => w is SpaceMenuItemTrailing && w.space.viewId == space.viewId,
      );
      final moreOptions = find.descendant(
        of: spaceMenuItemTrailing,
        matching: find.byWidgetPredicate(
          (w) =>
              w is FlowySvg &&
              w.svg.path == FlowySvgs.workspace_three_dots_s.path,
        ),
      );
      await tester.tapButton(moreOptions);
      await tester.pumpUntilFound(find.byType(SpaceMenuMoreOptions));
    }

    // combine the tests together to reduce the CI time
    testWidgets('''
1. create a new space
2. update the space name
3. update the space permission
4. update the space icon
5. delete the space
''', (tester) async {
      await tester.initializeAppFlowy(
        cloudType: AuthenticatorType.appflowyCloudSelfHost,
      );
      await tester.tapGoogleLoginInButton();
      await tester.expectToSeeHomePageWithGetStartedPage();

      // 1. create a new space
      // click the space menu
      await openSpaceMenu(tester);

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
      final doneButton = find.descendant(
        of: find.byWidgetPredicate(
          (w) =>
              w is BottomSheetHeader &&
              w.title == LocaleKeys.space_createSpace.tr(),
        ),
        matching: find.text(LocaleKeys.button_done.tr()),
      );
      await tester.tapButton(doneButton);
      await tester.pumpAndSettle();

      // wait 100ms for the space to be created
      await tester.wait(100);

      // verify the space is created
      await openSpaceMenu(tester);
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

      // open the SpaceMenuMoreOptions menu
      await openSpaceMenuMoreOptions(tester, space);

      // 2. rename the space name
      final renameOption = find.text(LocaleKeys.button_rename.tr());
      await tester.tapButton(renameOption);
      await tester.pumpUntilFound(find.byType(EditWorkspaceNameBottomSheet));

      // input the new space name
      final renameInputField = find.descendant(
        of: find.byType(EditWorkspaceNameBottomSheet),
        matching: find.byType(TextField),
      );
      const renameSpaceName = 'HelloWorld';
      await tester.enterText(renameInputField, renameSpaceName);
      await tester.pumpAndSettle();
      await tester.tapButton(find.text(LocaleKeys.button_confirm.tr()));

      // click the done button
      await tester.pumpAndSettle();

      final renameSuccess = find.text(
        LocaleKeys.space_success_renameSpace.tr(),
      );
      await tester.pumpUntilNotFound(renameSuccess);

      // check the space name is updated
      await openSpaceMenu(tester);
      final renameSpaceItem = find.descendant(
        of: find.byType(MobileSpaceMenuItem),
        matching: find.text(renameSpaceName),
      );
      expect(renameSpaceItem, findsOneWidget);

      // 3. manage the space
      await openSpaceMenuMoreOptions(tester, space);

      final manageOption = find.text(LocaleKeys.space_manage.tr());
      await tester.tapButton(manageOption);
      await tester.pumpUntilFound(find.byType(ManageSpaceWidget));

      // 3.1 rename the space
      final textField = find.descendant(
        of: find.byType(ManageSpaceWidget),
        matching: find.byType(TextField),
      );
      await tester.enterText(textField, 'AppFlowy');
      await tester.pumpAndSettle();

      // 3.2 change the permission
      final permissionOption2 = find.byType(ManageSpacePermissionOption);
      await tester.tapButton(permissionOption2);
      await tester.pumpAndSettle();

      final publicOption = find.text(LocaleKeys.space_publicPermission.tr());
      await tester.tapButton(publicOption);
      await tester.pumpAndSettle();

      // 3.3 change the icon
      // change the space icon color
      final color2 = builtInSpaceColors[2];
      final iconOption2 = find.descendant(
        of: find.byType(ManageSpaceIconOption),
        matching: find.byWidgetPredicate(
          (w) => w is SpaceColorItem && w.color == color2,
        ),
      );
      await tester.tapButton(iconOption2);
      await tester.pumpAndSettle();

      // change the space icon
      final icon2 = kIconGroups![0].icons[2];
      final iconItem2 = find.descendant(
        of: find.byType(ManageSpaceIconOption),
        matching: find.byWidgetPredicate(
          (w) => w is SpaceIconItem && w.icon == icon2,
        ),
      );
      await tester.tapButton(iconItem2);
      await tester.pumpAndSettle();

      // click the done button
      final doneButton2 = find.descendant(
        of: find.byWidgetPredicate(
          (w) =>
              w is BottomSheetHeader &&
              w.title == LocaleKeys.space_manageSpace.tr(),
        ),
        matching: find.text(LocaleKeys.button_done.tr()),
      );
      await tester.tapButton(doneButton2);
      await tester.pumpAndSettle();

      // check the space is updated
      final spaceItems2 = find.byType(MobileSpaceMenuItem);
      final spaceWidget2 =
          tester.widgetList<MobileSpaceMenuItem>(spaceItems2).last;
      final space2 = spaceWidget2.space;
      expect(space2.name, 'AppFlowy');
      expect(space2.spacePermission, SpacePermission.public);
      expect(space2.spaceIcon, icon2.iconPath);
      expect(space2.spaceIconColor, color2);
      final manageSuccess = find.text(
        LocaleKeys.space_success_updateSpace.tr(),
      );
      await tester.pumpUntilNotFound(manageSuccess);

      // 4. duplicate the space
      await openSpaceMenuMoreOptions(tester, space);
      final duplicateOption = find.text(LocaleKeys.space_duplicate.tr());
      await tester.tapButton(duplicateOption);
      final duplicateSuccess = find.text(
        LocaleKeys.space_success_duplicateSpace.tr(),
      );
      await tester.pumpUntilNotFound(duplicateSuccess);

      // check the space is duplicated
      await openSpaceMenu(tester);
      final spaceItems3 = find.byType(MobileSpaceMenuItem);
      expect(spaceItems3, findsNWidgets(4));

      // 5. delete the space
      await openSpaceMenuMoreOptions(tester, space);
      final deleteOption = find.text(LocaleKeys.button_delete.tr());
      await tester.tapButton(deleteOption);
      final confirmDeleteButton = find.descendant(
        of: find.byType(CupertinoDialogAction),
        matching: find.text(LocaleKeys.button_delete.tr()),
      );
      await tester.tapButton(confirmDeleteButton);
      final deleteSuccess = find.text(
        LocaleKeys.space_success_deleteSpace.tr(),
      );
      await tester.pumpUntilNotFound(deleteSuccess);

      // check the space is deleted
      final spaceItems4 = find.byType(MobileSpaceMenuItem);
      expect(spaceItems4, findsNWidgets(3));
    });
  });
}
