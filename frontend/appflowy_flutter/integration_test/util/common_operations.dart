import 'dart:ui';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/grid_page.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/footer/grid_footer.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/field_cell.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/field_editor.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/field_type_extension.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/row/row.dart';
import 'package:appflowy/plugins/database_view/widgets/row/accessory/cell_accessory.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/cells.dart';
import 'package:appflowy/plugins/database_view/widgets/row/row_action.dart';
import 'package:appflowy/plugins/database_view/widgets/row/row_banner.dart';
import 'package:appflowy/plugins/database_view/widgets/row/row_detail.dart';
import 'package:appflowy/plugins/document/document_page.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/emoji_picker/emoji_menu_item.dart';
import 'package:appflowy/plugins/document/presentation/share/share_button.dart';
import 'package:appflowy/user/presentation/skip_log_in_screen.dart';
import 'package:appflowy/workspace/presentation/home/menu/app/header/add_button.dart';
import 'package:appflowy/workspace/presentation/home/menu/app/section/item.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pbenum.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
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
    final gesture = await createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await pump();
    await gesture.moveTo(offset ?? getCenter(finder));
    await pumpAndSettle();
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

  Future<void> hoverOnFirstRowOfGrid() async {
    final findRow = find.byType(GridRow);
    expect(findRow, findsWidgets);

    final firstRow = findRow.first;
    await hoverOnWidget(firstRow);
  }

  Future<void> openFirstRowDetailPage() async {
    await hoverOnFirstRowOfGrid();

    final expandButton = find.byType(PrimaryCellAccessory);
    expect(expandButton, findsOneWidget);
    await tapButton(expandButton);
  }

  Future<void> hoverRowBanner() async {
    final banner = find.byType(RowBanner);
    expect(banner, findsOneWidget);

    await startGesture(
      getTopLeft(banner),
      kind: PointerDeviceKind.mouse,
    );

    await pumpAndSettle();
  }

  Future<void> openEmojiPicker() async {
    await tapButton(find.byType(EmojiPickerButton));
    await tapButton(find.byType(EmojiSelectionMenu));
  }

  /// Must call [openEmojiPicker] first
  Future<void> switchToEmojiList() async {
    final icon = find.byIcon(Icons.tag_faces);
    await tapButton(icon);
  }

  Future<void> tapEmoji(String emoji) async {
    final emojiWidget = find.text(emoji);
    await tapButton(emojiWidget);
  }

  Future<void> scrollGridByOffset(Offset offset) async {
    await drag(find.byType(GridPage), offset);
    await pumpAndSettle();
  }

  Future<void> scrollRowDetailByOffset(Offset offset) async {
    await drag(find.byType(RowDetailPage), offset);
    await pumpAndSettle();
  }

  Future<void> scrollToRight(Finder find) async {
    final size = getSize(find);
    await drag(find, Offset(-size.width, 0));
    await pumpAndSettle(const Duration(milliseconds: 500));
  }

  Future<void> tapNewPropertyButton() async {
    await tapButtonWithName(LocaleKeys.grid_field_newProperty.tr());
    await pumpAndSettle();
  }

  Future<void> tapRowDetailPageCreatePropertyButton() async {
    await tapButton(find.byType(CreateRowFieldButton));
  }

  Future<void> tapTypeOptionButton() async {
    await tapButton(find.byType(FieldTypeOptionCell));
  }

  Future<void> selectFieldType(FieldType fieldType) async {
    final fieldTypeButton = find.byWidgetPredicate(
      (widget) => widget is FlowyText && widget.title == fieldType.title(),
    );
    await tapButton(fieldTypeButton);
  }

  /// Each field has its own cell, so we can find the corresponding cell by
  /// the field type after create a new field.
  Future<void> findCellByFieldType(FieldType fieldType) async {
    final finder = finderForFieldType(fieldType);
    expect(finder, findsWidgets);
  }

  Future<void> assertNumberOfFields(int num) async {
    expect(find.byType(GridFieldCell), findsNWidgets(num));
  }

  Future<void> assertNumberOfRows(int num) async {
    expect(find.byType(GridRow), findsNWidgets(num));
  }

  Future<void> assertDocumentExistInRowDetailPage() async {
    expect(find.byType(DocumentPage), findsOneWidget);
  }

  Future<void> findFieldWithName(String name) async {
    // final fieldName = find.byWidgetPredicate(
    //   (widget) => widget is FlowyText && widget.title == name,
    // );
    expect(find.text(name), findsOneWidget);
  }

  Future<void> renameField(String newName) async {
    final textField = find.byType(FieldNameTextField);
    expect(textField, findsOneWidget);
    await enterText(textField, newName);
    await pumpAndSettle();
  }

  Future<void> dismissFieldEditor() async {
    await sendKeyEvent(LogicalKeyboardKey.escape);
    await sendKeyEvent(LogicalKeyboardKey.escape);
    await pumpAndSettle(const Duration(milliseconds: 500));
  }

  Future<void> tapCreateRowButtonInGrid() async {
    await tapButton(find.byType(GridAddRowButton));
  }

  Future<void> tapCreateRowButtonInRowMenuOfGrid() async {
    await tapButton(find.byType(InsertRowButton));
  }

  Future<void> tapRowMenuButtonInGrid() async {
    await tapButton(find.byType(RowMenuButton));
  }

  /// Should call [tapRowMenuButtonInGrid] first.
  Future<void> tapDeleteOnRowMenu() async {
    await tapButtonWithName(LocaleKeys.grid_row_delete.tr());
  }
}

Finder finderForFieldType(FieldType fieldType) {
  switch (fieldType) {
    case FieldType.Checkbox:
      return find.byType(GridCheckboxCell);
    case FieldType.DateTime:
      return find.byType(GridDateCell);
    case FieldType.LastEditedTime:
    case FieldType.CreatedTime:
      return find.byType(GridDateCell);
    case FieldType.SingleSelect:
      return find.byType(GridSingleSelectCell);
    case FieldType.MultiSelect:
      return find.byType(GridMultiSelectCell);
    case FieldType.Checklist:
      return find.byType(GridChecklistCell);
    case FieldType.Number:
      return find.byType(GridNumberCell);
    case FieldType.RichText:
      return find.byType(GridTextCell);
    case FieldType.URL:
      return find.byType(GridURLCell);
    default:
      throw Exception('Unknown field type: $fieldType');
  }
}
