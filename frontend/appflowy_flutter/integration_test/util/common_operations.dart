import 'dart:ui';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy/generated/locale_keys.g.dart';

import 'package:appflowy/plugins/document/presentation/share/share_button.dart';
import 'package:appflowy/user/presentation/skip_log_in_screen.dart';
import 'package:appflowy/workspace/presentation/home/menu/app/header/add_button.dart';
import 'package:appflowy/workspace/presentation/home/menu/app/section/item.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_language_view.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/buttons/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'util.dart';

extension CommonOperations on WidgetTester {
  /// Tap the GetStart button on the launch page.
  Future<void> tapGoButton() async {
    final goButton = find.byType(GoButton);
    await tapButton(goButton);
  }

  /// Tap the + button on the home page.
  Future<void> tapAddButton() async {
    final addButton = find.byType(AddButton);
    await tapButton(addButton);
  }

  /// Tap the create document button.
  ///
  /// Must call [tapAddButton] first.
  Future<void> tapCreateDocumentButton() async {
    await tapButtonWithName(LocaleKeys.document_menuName.tr());
  }

  /// Tap the create grid button.
  ///
  /// Must call [tapAddButton] first.
  Future<void> tapCreateGridButton() async {
    await tapButtonWithName(LocaleKeys.grid_menuName.tr());
  }

  /// Tap the create grid button.
  ///
  /// Must call [tapAddButton] first.
  Future<void> tapCreateCalendarButton() async {
    await tapButtonWithName(LocaleKeys.calendar_menuName.tr());
  }

  /// Tap the import button.
  ///
  /// Must call [tapAddButton] first.
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
  }) async {
    try {
      final gesture = await createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await pump();
      await gesture.moveTo(offset ?? getCenter(finder));
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
    Future<void> Function()? onHover,
    bool useLast = true,
  }) async {
    if (useLast) {
      await hoverOnWidget(findPageName(name).last, onHover: onHover);
    } else {
      await hoverOnWidget(findPageName(name).first, onHover: onHover);
    }
  }

  /// open the page with given name.
  Future<void> openPage(String name) async {
    final finder = findPageName(name);
    expect(finder, findsOneWidget);
    await tapButton(finder);
  }

  /// Tap the ... button beside the page name.
  ///
  /// Must call [hoverOnPageName] first.
  Future<void> tapPageOptionButton() async {
    final optionButton = find.byType(ViewDisclosureButton);
    await tapButton(optionButton);
  }

  /// Tap the delete page button.
  Future<void> tapDeletePageButton() async {
    await tapPageOptionButton();
    await tapButtonWithName(ViewDisclosureAction.delete.name);
  }

  /// Tap the rename page button.
  Future<void> tapRenamePageButton() async {
    await tapPageOptionButton();
    await tapButtonWithName(ViewDisclosureAction.rename.name);
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
          widget.label == LocaleKeys.button_OK.tr(),
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

  Future<void> createNewPageWithName(
    ViewLayoutPB layout, [
    String? name,
  ]) async {
    // create a new page
    await tapAddButton();
    await tapButtonWithName(layout.menuName);
    await pumpAndSettle();

    // hover on it and change it's name
    if (name != null) {
      await hoverOnPageName(
        LocaleKeys.menuAppHeader_defaultNewPageName.tr(),
        onHover: () async {
          await renamePage(name);
          await pumpAndSettle();
        },
      );
      await pumpAndSettle();
    }
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

  Future<void> openAppInNewTab(String name) async {
    await hoverOnPageName(name);
    await tap(find.byType(ViewDisclosureButton));
    await pumpAndSettle();
    await tap(find.text(LocaleKeys.disclosureAction_openNewTab.tr()));
    await pumpAndSettle();
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
