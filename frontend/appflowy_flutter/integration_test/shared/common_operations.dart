import 'dart:io';

import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/emoji_picker_button.dart';
import 'package:appflowy/plugins/document/presentation/share/share_button.dart';
import 'package:appflowy/shared/feature_flags.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/presentation/screens/screens.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/widgets.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/sidebar_new_page_button.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/sidebar_workspace.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/_sidebar_workspace_menu.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/draggable_view_item.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_action_type.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_add_button.dart';
import 'package:appflowy/workspace/presentation/home/menu/view/view_more_action_button.dart';
import 'package:appflowy/workspace/presentation/notifications/widgets/flowy_tab.dart';
import 'package:appflowy/workspace/presentation/notifications/widgets/notification_button.dart';
import 'package:appflowy/workspace/presentation/notifications/widgets/notification_tab_bar.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_language_view.dart';
import 'package:appflowy/workspace/presentation/widgets/view_title_bar.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/buttons/primary_button.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'emoji.dart';
import 'util.dart';

extension CommonOperations on WidgetTester {
  /// Tap the GetStart button on the launch page.
  Future<void> tapGoButton() async {
    // local version
    final goButton = find.byType(GoButton);
    if (goButton.evaluate().isNotEmpty) {
      await tapButton(goButton);
    } else {
      // cloud version
      final anonymousButton = find.byType(SignInAnonymousButton);
      await tapButton(anonymousButton);
    }

    if (Platform.isWindows) {
      await pumpAndSettle(const Duration(milliseconds: 200));
    }
  }

  /// Tap the + button on the home page.
  Future<void> tapAddViewButton({
    String name = gettingStarted,
  }) async {
    await hoverOnPageName(
      name,
      onHover: () async {
        final addButton = find.byType(ViewAddButton);
        await tapButton(addButton);
      },
    );
  }

  /// Tap the 'New Page' Button on the sidebar.
  Future<void> tapNewPageButton() async {
    final newPageButton = find.byType(SidebarNewPageButton);
    await tapButton(newPageButton);
  }

  /// Tap the create document button.
  ///
  /// Must call [tapAddViewButton] first.
  Future<void> tapCreateDocumentButton() async {
    await tapButtonWithName(LocaleKeys.document_menuName.tr());
  }

  /// Tap the create grid button.
  ///
  /// Must call [tapAddViewButton] first.
  Future<void> tapCreateGridButton() async {
    await tapButtonWithName(LocaleKeys.grid_menuName.tr());
  }

  /// Tap the create grid button.
  ///
  /// Must call [tapAddViewButton] first.
  Future<void> tapCreateCalendarButton() async {
    await tapButtonWithName(LocaleKeys.calendar_menuName.tr());
  }

  /// Tap the import button.
  ///
  /// Must call [tapAddViewButton] first.
  Future<void> tapImportButton() async {
    await tapButtonWithName(LocaleKeys.moreAction_import.tr());
  }

  /// Tap the import from text & markdown button.
  ///
  /// Must call [tapImportButton] first.
  Future<void> tapTextAndMarkdownButton() async {
    await tapButtonWithName(LocaleKeys.importPanel_textAndMarkdown.tr());
  }

  /// Tap the LanguageSelectorOnWelcomePage widget on the launch page.
  Future<void> tapLanguageSelectorOnWelcomePage() async {
    final languageSelector = find.byType(LanguageSelectorOnWelcomePage);
    await tapButton(languageSelector);
  }

  /// Tap languageItem on LanguageItemsListView.
  ///
  /// [scrollDelta] is the distance to scroll the ListView.
  /// Default value is 100
  ///
  /// If it is positive -> scroll down.
  ///
  /// If it is negative -> scroll up.
  Future<void> tapLanguageItem({
    required String languageCode,
    String? countryCode,
    double? scrollDelta,
  }) async {
    final languageItemsListView = find.descendant(
      of: find.byType(ListView),
      matching: find.byType(Scrollable),
    );

    final languageItem = find.byWidgetPredicate(
      (widget) =>
          widget is LanguageItem &&
          widget.locale.languageCode == languageCode &&
          widget.locale.countryCode == countryCode,
    );

    // scroll the ListView until zHCNLanguageItem shows on the screen.
    await scrollUntilVisible(
      languageItem,
      scrollDelta ?? 100,
      scrollable: languageItemsListView,
      // maxHeight of LanguageItemsListView
      maxScrolls: 400,
    );

    try {
      await tapButton(languageItem);
    } on FlutterError catch (e) {
      Log.warn('tapLanguageItem error: $e');
    }
  }

  /// Hover on the widget.
  Future<void> hoverOnWidget(
    Finder finder, {
    Offset? offset,
    Future<void> Function()? onHover,
    bool removePointer = true,
  }) async {
    try {
      final gesture = await createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: offset ?? getCenter(finder));
      await pumpAndSettle();
      await onHover?.call();
      await gesture.removePointer();
    } catch (err) {
      Log.error('hoverOnWidget error: $err');
    }
  }

  /// Hover on the page name.
  Future<void> hoverOnPageName(
    String name, {
    ViewLayoutPB layout = ViewLayoutPB.Document,
    Future<void> Function()? onHover,
    bool useLast = true,
  }) async {
    final pageNames = findPageName(name, layout: layout);
    if (useLast) {
      await hoverOnWidget(
        pageNames.last,
        onHover: onHover,
      );
    } else {
      await hoverOnWidget(
        pageNames.first,
        onHover: onHover,
      );
    }
  }

  /// open the page with given name.
  Future<void> openPage(
    String name, {
    ViewLayoutPB layout = ViewLayoutPB.Document,
  }) async {
    final finder = findPageName(name, layout: layout);
    expect(finder, findsOneWidget);
    await tapButton(finder);
  }

  /// Tap the ... button beside the page name.
  ///
  /// Must call [hoverOnPageName] first.
  Future<void> tapPageOptionButton() async {
    final optionButton = find.byType(ViewMoreActionButton);
    await tapButton(optionButton);
  }

  /// Tap the delete page button.
  Future<void> tapDeletePageButton() async {
    await tapPageOptionButton();
    await tapButtonWithName(ViewMoreActionType.delete.name);
  }

  /// Tap the rename page button.
  Future<void> tapRenamePageButton() async {
    await tapPageOptionButton();
    await tapButtonWithName(ViewMoreActionType.rename.name);
  }

  /// Tap the favorite page button
  Future<void> tapFavoritePageButton() async {
    await tapPageOptionButton();
    await tapButtonWithName(ViewMoreActionType.favorite.name);
  }

  /// Tap the unfavorite page button
  Future<void> tapUnfavoritePageButton() async {
    await tapPageOptionButton();
    await tapButtonWithName(ViewMoreActionType.unFavorite.name);
  }

  /// Tap the Open in a new tab button
  Future<void> tapOpenInTabButton() async {
    await tapPageOptionButton();
    await tapButtonWithName(ViewMoreActionType.openInNewTab.name);
  }

  /// Rename the page.
  Future<void> renamePage(String name) async {
    await tapRenamePageButton();
    await enterText(find.byType(TextFormField), name);
    await tapOKButton();
  }

  Future<void> tapOKButton() async {
    final okButton = find.byWidgetPredicate(
      (widget) =>
          widget is PrimaryTextButton &&
          widget.label == LocaleKeys.button_ok.tr(),
    );
    await tapButton(okButton);
  }

  /// Tap the restore button.
  ///
  /// the restore button will show after the current page is deleted.
  Future<void> tapRestoreButton() async {
    final restoreButton = find.textContaining(
      LocaleKeys.deletePagePrompt_restore.tr(),
    );
    await tapButton(restoreButton);
  }

  /// Tap the delete permanently button.
  ///
  /// the restore button will show after the current page is deleted.
  Future<void> tapDeletePermanentlyButton() async {
    final restoreButton = find.textContaining(
      LocaleKeys.deletePagePrompt_deletePermanent.tr(),
    );
    await tapButton(restoreButton);
  }

  /// Tap the share button above the document page.
  Future<void> tapShareButton() async {
    final shareButton = find.byWidgetPredicate(
      (widget) => widget is DocumentShareButton,
    );
    await tapButton(shareButton);
  }

  /// Tap the export markdown button
  ///
  /// Must call [tapShareButton] first.
  Future<void> tapMarkdownButton() async {
    final markdownButton = find.textContaining(
      LocaleKeys.shareAction_markdown.tr(),
    );
    await tapButton(markdownButton);
  }

  Future<void> createNewPageWithNameUnderParent({
    String? name,
    ViewLayoutPB layout = ViewLayoutPB.Document,
    String? parentName,
    bool openAfterCreated = true,
  }) async {
    // create a new page
    await tapAddViewButton(name: parentName ?? gettingStarted);
    await tapButtonWithName(layout.menuName);
    final settingsOrFailure = await getIt<KeyValueStorage>().getWithFormat(
      KVKeys.showRenameDialogWhenCreatingNewFile,
      (value) => bool.parse(value),
    );
    final showRenameDialog = settingsOrFailure ?? false;
    if (showRenameDialog) {
      await tapOKButton();
    }
    await pumpAndSettle();

    // hover on it and change it's name
    if (name != null) {
      await hoverOnPageName(
        LocaleKeys.menuAppHeader_defaultNewPageName.tr(),
        layout: layout,
        onHover: () async {
          await renamePage(name);
          await pumpAndSettle();
        },
      );
      await pumpAndSettle();
    }

    // open the page after created
    if (openAfterCreated) {
      await openPage(
        // if the name is null, use the default name
        name ?? LocaleKeys.menuAppHeader_defaultNewPageName.tr(),
        layout: layout,
      );
      await pumpAndSettle();
    }
  }

  Future<void> createNewPage({
    ViewLayoutPB layout = ViewLayoutPB.Document,
    bool openAfterCreated = true,
  }) async {
    await tapButton(find.byType(SidebarNewPageButton));
  }

  Future<void> simulateKeyEvent(
    LogicalKeyboardKey key, {
    bool isControlPressed = false,
    bool isShiftPressed = false,
    bool isAltPressed = false,
    bool isMetaPressed = false,
  }) async {
    if (isControlPressed) {
      await simulateKeyDownEvent(LogicalKeyboardKey.control);
    }
    if (isShiftPressed) {
      await simulateKeyDownEvent(LogicalKeyboardKey.shift);
    }
    if (isAltPressed) {
      await simulateKeyDownEvent(LogicalKeyboardKey.alt);
    }
    if (isMetaPressed) {
      await simulateKeyDownEvent(LogicalKeyboardKey.meta);
    }
    await simulateKeyDownEvent(key);
    await simulateKeyUpEvent(key);
    if (isControlPressed) {
      await simulateKeyUpEvent(LogicalKeyboardKey.control);
    }
    if (isShiftPressed) {
      await simulateKeyUpEvent(LogicalKeyboardKey.shift);
    }
    if (isAltPressed) {
      await simulateKeyUpEvent(LogicalKeyboardKey.alt);
    }
    if (isMetaPressed) {
      await simulateKeyUpEvent(LogicalKeyboardKey.meta);
    }
    await pumpAndSettle();
  }

  Future<void> openAppInNewTab(String name, ViewLayoutPB layout) async {
    await hoverOnPageName(
      name,
      onHover: () async {
        await tapOpenInTabButton();
        await pumpAndSettle();
      },
    );
    await pumpAndSettle();
  }

  Future<void> favoriteViewByName(
    String name, {
    ViewLayoutPB layout = ViewLayoutPB.Document,
  }) async {
    await hoverOnPageName(
      name,
      layout: layout,
      onHover: () async {
        await tapFavoritePageButton();
        await pumpAndSettle();
      },
    );
  }

  Future<void> unfavoriteViewByName(
    String name, {
    ViewLayoutPB layout = ViewLayoutPB.Document,
  }) async {
    await hoverOnPageName(
      name,
      layout: layout,
      onHover: () async {
        await tapUnfavoritePageButton();
        await pumpAndSettle();
      },
    );
  }

  Future<void> movePageToOtherPage({
    required String name,
    required String parentName,
    required ViewLayoutPB layout,
    required ViewLayoutPB parentLayout,
    DraggableHoverPosition position = DraggableHoverPosition.center,
  }) async {
    final from = findPageName(name, layout: layout);
    final to = findPageName(parentName, layout: parentLayout);
    final gesture = await startGesture(getCenter(from));
    Offset offset = Offset.zero;
    switch (position) {
      case DraggableHoverPosition.center:
        offset = getCenter(to);
        break;
      case DraggableHoverPosition.top:
        offset = getTopLeft(to);
        break;
      case DraggableHoverPosition.bottom:
        offset = getBottomLeft(to);
        break;
      default:
    }
    await gesture.moveTo(offset, timeStamp: const Duration(milliseconds: 400));
    await gesture.up();
    await pumpAndSettle();
  }

  // tap the button with [FlowySvgData]
  Future<void> tapButtonWithFlowySvgData(FlowySvgData svg) async {
    final button = find.byWidgetPredicate(
      (widget) => widget is FlowySvg && widget.svg.path == svg.path,
    );
    await tapButton(button);
  }

  // update the page icon in the sidebar
  Future<void> updatePageIconInSidebarByName({
    required String name,
    required String parentName,
    required ViewLayoutPB layout,
    required String icon,
  }) async {
    final iconButton = find.descendant(
      of: findPageName(
        name,
        layout: layout,
        parentName: parentName,
      ),
      matching:
          find.byTooltip(LocaleKeys.document_plugins_cover_changeIcon.tr()),
    );
    await tapButton(iconButton);
    await tapEmoji(icon);
    await pumpAndSettle();
  }

  // update the page icon in the sidebar
  Future<void> updatePageIconInTitleBarByName({
    required String name,
    required ViewLayoutPB layout,
    required String icon,
  }) async {
    await openPage(
      name,
      layout: layout,
    );
    final title = find.descendant(
      of: find.byType(ViewTitleBar),
      matching: find.text(name),
    );
    await tapButton(title);
    await tapButton(find.byType(EmojiPickerButton));
    await tapEmoji(icon);
    await pumpAndSettle();
  }

  Future<void> openNotificationHub({
    int tabIndex = 0,
  }) async {
    final finder = find.descendant(
      of: find.byType(NotificationButton),
      matching: find.byWidgetPredicate(
        (widget) => widget is FlowySvg && widget.svg == FlowySvgs.clock_alarm_s,
      ),
    );

    await tap(finder);
    await pumpAndSettle();

    if (tabIndex == 1) {
      final tabFinder = find.descendant(
        of: find.byType(NotificationTabBar),
        matching: find.byType(FlowyTabItem).at(1),
      );

      await tap(tabFinder);
      await pumpAndSettle();
    }
  }

  Future<void> openCollaborativeWorkspaceMenu() async {
    if (!FeatureFlag.collaborativeWorkspace.isOn) {
      throw UnsupportedError('Collaborative workspace is not enabled');
    }

    final workspace = find.byType(SidebarWorkspace);
    expect(workspace, findsOneWidget);
    // click it
    await tapButton(workspace, milliseconds: 2000);
  }

  Future<void> closeCollaborativeWorkspaceMenu() async {
    if (!FeatureFlag.collaborativeWorkspace.isOn) {
      throw UnsupportedError('Collaborative workspace is not enabled');
    }

    await tapAt(Offset.zero);
    await pumpAndSettle();
  }

  Future<void> createCollaborativeWorkspace(String name) async {
    if (!FeatureFlag.collaborativeWorkspace.isOn) {
      throw UnsupportedError('Collaborative workspace is not enabled');
    }
    await openCollaborativeWorkspaceMenu();
    // expect to see the workspace list, and there should be only one workspace
    final workspacesMenu = find.byType(WorkspacesMenu);
    expect(workspacesMenu, findsOneWidget);

    // click the create button
    final createButton = find.byKey(createWorkspaceButtonKey);
    expect(createButton, findsOneWidget);
    await tapButton(createButton);

    // see the create workspace dialog
    final createWorkspaceDialog = find.byType(CreateWorkspaceDialog);
    expect(createWorkspaceDialog, findsOneWidget);

    // input the workspace name
    await enterText(find.byType(TextField), name);

    await tapButtonWithName(LocaleKeys.button_ok.tr());
  }
}

extension ViewLayoutPBTest on ViewLayoutPB {
  String get menuName {
    switch (this) {
      case ViewLayoutPB.Grid:
        return LocaleKeys.grid_menuName.tr();
      case ViewLayoutPB.Board:
        return LocaleKeys.board_menuName.tr();
      case ViewLayoutPB.Document:
        return LocaleKeys.document_menuName.tr();
      case ViewLayoutPB.Calendar:
        return LocaleKeys.calendar_menuName.tr();
      default:
        throw UnsupportedError('Unsupported layout: $this');
    }
  }

  String get referencedMenuName {
    switch (this) {
      case ViewLayoutPB.Grid:
        return LocaleKeys.document_plugins_referencedGrid.tr();
      case ViewLayoutPB.Board:
        return LocaleKeys.document_plugins_referencedBoard.tr();
      case ViewLayoutPB.Calendar:
        return LocaleKeys.document_plugins_referencedCalendar.tr();
      default:
        throw UnsupportedError('Unsupported layout: $this');
    }
  }
}
