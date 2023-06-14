import 'dart:ui';

import 'package:appflowy/generated/locale_keys.g.dart';

import 'package:appflowy/plugins/document/presentation/share/share_button.dart';
import 'package:appflowy/user/presentation/skip_log_in_screen.dart';
import 'package:appflowy/workspace/presentation/home/menu/app/header/add_button.dart';
import 'package:appflowy/workspace/presentation/home/menu/app/section/item.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/buttons/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'util.dart';

extension CommonOperations on WidgetTester {
  /// Get current file location of AppFlowy.
  Future<String> currentFileLocation() async {
    return TestFolder.currentLocation();
  }

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

  /// Hover on the widget.
  Future<void> hoverOnWidget(
    Finder finder, {
    Offset? offset,
  }) async {
    try {
      final gesture = await createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await pump();
      await gesture.moveTo(offset ?? getCenter(finder));
      await pumpAndSettle();
    } catch (_) {}
  }

  /// Hover on the page name.
  Future<void> hoverOnPageName(String name) async {
    await hoverOnWidget(findPageName(name));
  }

  /// Tap the ... button beside the page name.
  ///
  /// Must call [hoverOnPageName] first.
  Future<void> tapPageOptionButton() async {
    final optionButton = find.byType(ViewDisclosureButton);
    await tapButton(optionButton);
  }

  /// Tap the delete page button.
  ///
  /// Must call [tapPageOptionButton] first.
  Future<void> tapDeletePageButton() async {
    await tapPageOptionButton();
    await tapButtonWithName(ViewDisclosureAction.delete.name);
  }

  /// Tap the rename page button.
  ///
  /// Must call [tapPageOptionButton] first.
  Future<void> tapRenamePageButton() async {
    await tapPageOptionButton();
    await tapButtonWithName(ViewDisclosureAction.rename.name);
  }

  /// Rename the page.
  ///
  /// Must call [tapPageOptionButton] first.
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

  /// Hover on cover plugin button above the document
  Future<void> hoverOnCoverPluginAddButton() async {
    final editor = find.byWidgetPredicate(
      (widget) => widget is AppFlowyEditor,
    );
    await hoverOnWidget(
      editor,
      offset: getTopLeft(editor).translate(20, 20),
    );
  }
}

extension on String {
  Iterable<LogicalKeyboardKey> get logicalKeys {
    return codeUnits.map((codeUnit) => LogicalKeyboardKey(codeUnit));
  }
}
