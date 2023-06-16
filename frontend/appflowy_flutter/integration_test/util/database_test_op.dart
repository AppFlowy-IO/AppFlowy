import 'dart:io';
import 'dart:ui';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/setting/setting_bloc.dart';
import 'package:appflowy/plugins/database_view/board/presentation/board_page.dart';
import 'package:appflowy/plugins/database_view/calendar/presentation/calendar_page.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/filter/choicechip/checkbox.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/filter/choicechip/checklist/checklist.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/filter/choicechip/select_option/option_list.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/filter/choicechip/select_option/select_option.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/filter/choicechip/text.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/filter/create_filter_list.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/filter/disclosure_button.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/filter/filter_menu_item.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/field_cell_action_sheet.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/field_type_list.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/field_type_option_editor.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/toolbar/filter_button.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/toolbar/grid_layout.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/checklist_cell/checklist_progress_bar.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/select_option_cell/extension.dart';
import 'package:appflowy/plugins/database_view/widgets/row/row_document.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/date_cell/date_editor.dart';
import 'package:appflowy/plugins/database_view/widgets/setting/database_setting.dart';
import 'package:appflowy/plugins/database_view/widgets/setting/setting_button.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/setting_entities.pbenum.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/style_widget/text_field.dart';
import 'package:flowy_infra_ui/widget/buttons/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:appflowy/plugins/document/presentation/editor_plugins/emoji_picker/emoji_menu_item.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pbenum.dart';
import 'package:table_calendar/table_calendar.dart';

import 'base.dart';
import 'common_operations.dart';
import 'expectation.dart';
import 'package:path/path.dart' as p;

import 'mock/mock_file_picker.dart';

extension AppFlowyDatabaseTest on WidgetTester {
  Future<void> openV020database() async {
    await initializeAppFlowy();
    await tapGoButton();

    // expect to see a readme page
    expectToSeePageName(readme);

    await tapAddButton();
    await tapImportButton();

    final testFileNames = ['v020.afdb'];
    final fileLocation = await currentFileLocation();
    for (final fileName in testFileNames) {
      final str = await rootBundle.loadString(
        p.join(
          'assets/test/workspaces/database',
          fileName,
        ),
      );
      File(p.join(fileLocation, fileName)).writeAsStringSync(str);
    }
    // mock get files
    await mockPickFilePaths(testFileNames, name: 'import_files');
    await tapDatabaseRawDataButton();
    await openPage('v020');
  }

  Future<void> hoverOnFirstRowOfGrid() async {
    final findRow = find.byType(GridRow);
    expect(findRow, findsWidgets);

    final firstRow = findRow.first;
    await hoverOnWidget(firstRow);
  }

  Future<void> editCell({
    required int rowIndex,
    required FieldType fieldType,
    required String input,
  }) async {
    final cell = cellFinder(rowIndex, fieldType);

    expect(cell, findsOneWidget);
    await enterText(cell, input);
    await pumpAndSettle();
  }

  Finder cellFinder(int rowIndex, FieldType fieldType) {
    final findRow = find.byType(GridRow, skipOffstage: false);
    final findCell = finderForFieldType(fieldType);
    return find.descendant(
      of: findRow.at(rowIndex),
      matching: findCell,
      skipOffstage: false,
    );
  }

  Future<void> tapCheckboxCellInGrid({
    required int rowIndex,
  }) async {
    final cell = cellFinder(rowIndex, FieldType.Checkbox);

    final button = find.descendant(
      of: cell,
      matching: find.byType(FlowyIconButton),
    );

    expect(cell, findsOneWidget);
    await tapButton(button);
  }

  Future<void> assertCheckboxCell({
    required int rowIndex,
    required bool isSelected,
  }) async {
    final cell = cellFinder(rowIndex, FieldType.Checkbox);
    var finder = find.byType(CheckboxCellUncheck);
    if (isSelected) {
      finder = find.byType(CheckboxCellCheck);
    }

    expect(
      find.descendant(
        of: cell,
        matching: finder,
      ),
      findsOneWidget,
    );
  }

  Future<void> tapCellInGrid({
    required int rowIndex,
    required FieldType fieldType,
  }) async {
    final cell = cellFinder(rowIndex, fieldType);
    expect(cell, findsOneWidget);
    await tapButton(cell, warnIfMissed: false);
  }

  /// The [fieldName] must be uqniue in the grid.
  Future<void> assertCellContent({
    required int rowIndex,
    required FieldType fieldType,
    required String content,
  }) async {
    final findCell = cellFinder(rowIndex, fieldType);
    final findContent = find.descendant(
      of: findCell,
      matching: find.text(content),
      skipOffstage: false,
    );

    final text = find.descendant(
      of: find.byType(TextField),
      matching: findContent,
      skipOffstage: false,
    );

    expect(text, findsOneWidget);
  }

  Future<void> assertSingleSelectOption({
    required int rowIndex,
    required String content,
  }) async {
    final findCell = cellFinder(rowIndex, FieldType.SingleSelect);
    if (content.isNotEmpty) {
      final finder = find.descendant(
        of: findCell,
        matching: find.byWidgetPredicate(
          (widget) => widget is SelectOptionTag && widget.name == content,
        ),
      );
      expect(finder, findsOneWidget);
    }
  }

  Future<void> assertMultiSelectOption({
    required int rowIndex,
    required List<String> contents,
  }) async {
    final findCell = cellFinder(rowIndex, FieldType.MultiSelect);
    for (final content in contents) {
      if (content.isNotEmpty) {
        final finder = find.descendant(
          of: findCell,
          matching: find.byWidgetPredicate(
            (widget) => widget is SelectOptionTag && widget.name == content,
          ),
        );
        expect(finder, findsOneWidget);
      }
    }
  }

  Future<void> assertChecklistCellInGrid({
    required int rowIndex,
    required double percent,
  }) async {
    final findCell = cellFinder(rowIndex, FieldType.Checklist);
    final finder = find.descendant(
      of: findCell,
      matching: find.byWidgetPredicate(
        (widget) {
          if (widget is ChecklistProgressBar) {
            return widget.percent == percent;
          }
          return false;
        },
      ),
    );
    expect(finder, findsOneWidget);
  }

  Future<void> assertDateCellInGrid({
    required int rowIndex,
    required FieldType fieldType,
    required String content,
  }) async {
    final findRow = find.byType(GridRow, skipOffstage: false);
    final findCell = find.descendant(
      of: findRow.at(rowIndex),
      matching: find.byWidgetPredicate(
        (widget) => widget is GridDateCell && widget.fieldType == fieldType,
      ),
      skipOffstage: false,
    );

    final dateCellText = find.descendant(
      of: findCell,
      matching: find.byType(GridDateCellText),
    );

    final text = find.descendant(
      of: dateCellText,
      matching: find.byWidgetPredicate(
        (widget) {
          if (widget is FlowyText) {
            return widget.title == content;
          }
          return false;
        },
      ),
      skipOffstage: false,
    );
    expect(text, findsOneWidget);
  }

  Future<void> selectDay({
    required int content,
  }) async {
    final findCalendar = find.byType(TableCalendar);
    final findDay = find.text(content.toString());

    final finder = find.descendant(
      of: findCalendar,
      matching: findDay,
    );

    await tapButton(finder);
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

  Future<void> tapGridFieldWithName(String name) async {
    final field = find.byWidgetPredicate(
      (widget) => widget is FieldCellButton && widget.field.name == name,
    );
    await tapButton(field);
    await pumpAndSettle();
  }

  /// Should call [tapGridFieldWithName] first.
  Future<void> tapEditPropertyButton() async {
    await tapButtonWithName(LocaleKeys.grid_field_editProperty.tr());
    await pumpAndSettle(const Duration(milliseconds: 200));
  }

  /// Should call [tapGridFieldWithName] first.
  Future<void> tapDeletePropertyButton() async {
    final field = find.byWidgetPredicate(
      (widget) =>
          widget is FieldActionCell && widget.action == FieldAction.delete,
    );
    await tapButton(field);
  }

  /// Should call [tapGridFieldWithName] first.
  Future<void> tapDialogOkButton() async {
    final field = find.byWidgetPredicate(
      (widget) =>
          widget is PrimaryTextButton &&
          widget.label == LocaleKeys.button_OK.tr(),
    );
    await tapButton(field);
  }

  /// Should call [tapGridFieldWithName] first.
  Future<void> tapDuplicatePropertyButton() async {
    final field = find.byWidgetPredicate(
      (widget) =>
          widget is FieldActionCell && widget.action == FieldAction.duplicate,
    );
    await tapButton(field);
  }

  /// Should call [tapGridFieldWithName] first.
  Future<void> tapHidePropertyButton() async {
    final field = find.byWidgetPredicate(
      (widget) =>
          widget is FieldActionCell && widget.action == FieldAction.hide,
    );
    await tapButton(field);
  }

  Future<void> tapRowDetailPageCreatePropertyButton() async {
    await tapButton(find.byType(CreateRowFieldButton));
  }

  Future<void> tapRowDetailPageDeleteRowButton() async {
    await tapButton(find.byType(RowDetailPageDeleteButton));
  }

  Future<void> tapRowDetailPageDuplicateRowButton() async {
    await tapButton(find.byType(RowDetailPageDuplicateButton));
  }

  Future<void> tapTypeOptionButton() async {
    await tapButton(find.byType(SwitchFieldButton));
  }

  Future<void> tapEscButton() async {
    await sendKeyEvent(LogicalKeyboardKey.escape);
  }

  /// Must call [tapTypeOptionButton] first.
  Future<void> selectFieldType(FieldType fieldType) async {
    final fieldTypeCell = find.byType(FieldTypeCell);

    final fieldTypeButton = find.descendant(
      of: fieldTypeCell,
      matching: find.byWidgetPredicate(
        (widget) => widget is FlowyText && widget.title == fieldType.title(),
      ),
    );
    await tapButton(fieldTypeButton);
  }

  /// Each field has its own cell, so we can find the corresponding cell by
  /// the field type after create a new field.
  Future<void> findCellByFieldType(FieldType fieldType) async {
    final finder = finderForFieldType(fieldType);
    expect(finder, findsWidgets);
  }

  Future<void> assertNumberOfFieldsInGridPage(int num) async {
    expect(find.byType(GridFieldCell), findsNWidgets(num));
  }

  Future<void> assertNumberOfRowsInGridPage(int num) async {
    expect(
      find.byType(GridRow, skipOffstage: false),
      findsNWidgets(num),
    );
  }

  Future<void> assertDocumentExistInRowDetailPage() async {
    expect(find.byType(RowDocument), findsOneWidget);
  }

  /// Check the field type of the [FieldCellButton] is the same as the name.
  Future<void> assertFieldTypeWithFieldName(
    String name,
    FieldType fieldType,
  ) async {
    final field = find.byWidgetPredicate(
      (widget) =>
          widget is FieldCellButton &&
          widget.field.fieldType == fieldType &&
          widget.field.name == name,
    );

    expect(field, findsOneWidget);
  }

  Future<void> findFieldWithName(String name) async {
    final field = find.byWidgetPredicate(
      (widget) => widget is FieldCellButton && widget.field.name == name,
    );
    expect(field, findsOneWidget);
  }

  Future<void> noFieldWithName(String name) async {
    final field = find.byWidgetPredicate(
      (widget) => widget is FieldCellButton && widget.field.name == name,
    );
    expect(field, findsNothing);
  }

  Future<void> renameField(String newName) async {
    final textField = find.byType(FieldNameTextField);
    expect(textField, findsOneWidget);
    await enterText(textField, newName);
    await pumpAndSettle();
  }

  Future<void> dismissFieldEditor() async {
    await sendKeyEvent(LogicalKeyboardKey.escape);
    await pumpAndSettle(const Duration(milliseconds: 200));
  }

  Future<void> findFieldEditor(dynamic matcher) async {
    final finder = find.byType(FieldEditor);
    expect(finder, matcher);
  }

  Future<void> findDateEditor(dynamic matcher) async {
    final finder = find.byType(DateCellEditor);
    expect(finder, matcher);
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

  Future<void> assertRowCountInGridPage(int num) async {
    final text = find.byWidgetPredicate(
      (widget) => widget is FlowyText && widget.title == rowCountString(num),
    );
    expect(text, findsOneWidget);
  }

  Future<void> createField(FieldType fieldType, String name) async {
    await scrollToRight(find.byType(GridPage));
    await tapNewPropertyButton();
    await renameField(name);
    await tapTypeOptionButton();
    await selectFieldType(fieldType);
    await dismissFieldEditor();
  }

  Future<void> tapDatabaseSettingButton() async {
    await tapButton(find.byType(SettingButton));
  }

  Future<void> tapDatabaseFilterButton() async {
    await tapButton(find.byType(FilterButton));
  }

  Future<void> tapCreateFilterByFieldType(
    FieldType fieldType,
    String title,
  ) async {
    final findFilter = find.byWidgetPredicate(
      (widget) =>
          widget is GridFilterPropertyCell &&
          widget.fieldInfo.fieldType == fieldType &&
          widget.fieldInfo.name == title,
    );

    await tapButton(findFilter);
  }

  Future<void> tapFilterButtonInGrid(String filterName) async {
    final findFilter = find.byType(FilterMenuItem);
    final button = find.descendant(
      of: findFilter,
      matching: find.text(filterName),
    );

    await tapButton(button);
  }

  Future<void> scrollOptionFilterListByOffset(Offset offset) async {
    await drag(find.byType(SelectOptionFilterEditor), offset);
    await pumpAndSettle();
  }

  Future<void> enterTextInTextFilter(String text) async {
    final findEditor = find.byType(TextFilterEditor);
    final findTextField = find.descendant(
      of: findEditor,
      matching: find.byType(FlowyTextField),
    );

    await enterText(findTextField, text);
    await pumpAndSettle(const Duration(milliseconds: 300));
  }

  Future<void> tapDisclosureButtonInFinder(Finder finder) async {
    final findDisclosure = find.descendant(
      of: finder,
      matching: find.byType(DisclosureButton),
    );

    await tapButton(findDisclosure);
  }

  /// must call [tapDisclosureButtonInFinder] first.
  Future<void> tapDeleteFilterButtonInGrid() async {
    await tapButton(find.text(LocaleKeys.grid_settings_deleteFilter.tr()));
  }

  Future<void> tapCheckboxFilterButtonInGrid() async {
    await tapButton(find.byType(CheckboxFilterConditionList));
  }

  Future<void> tapChecklistFilterButtonInGrid() async {
    await tapButton(find.byType(ChecklistFilterConditionList));
  }

  /// The [SelectOptionFilterList] must show up first.
  Future<void> tapOptionFilterWithName(String name) async {
    final findCell = find.descendant(
      of: find.byType(SelectOptionFilterList),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is SelectOptionFilterCell && widget.option.name == name,
        skipOffstage: false,
      ),
      skipOffstage: false,
    );
    expect(findCell, findsOneWidget);
    await tapButton(findCell, warnIfMissed: false);
  }

  Future<void> tapCheckedButtonOnCheckboxFilter() async {
    final button = find.descendant(
      of: find.byType(HoverButton),
      matching: find.text(LocaleKeys.grid_checkboxFilter_isChecked.tr()),
    );

    await tapButton(button);
  }

  Future<void> tapUnCheckedButtonOnCheckboxFilter() async {
    final button = find.descendant(
      of: find.byType(HoverButton),
      matching: find.text(LocaleKeys.grid_checkboxFilter_isUnchecked.tr()),
    );

    await tapButton(button);
  }

  Future<void> tapCompletedButtonOnChecklistFilter() async {
    final button = find.descendant(
      of: find.byType(HoverButton),
      matching: find.text(LocaleKeys.grid_checklistFilter_isComplete.tr()),
    );

    await tapButton(button);
  }

  Future<void> tapUnCompletedButtonOnChecklistFilter() async {
    final button = find.descendant(
      of: find.byType(HoverButton),
      matching: find.text(LocaleKeys.grid_checklistFilter_isIncomplted.tr()),
    );

    await tapButton(button);
  }

  /// Should call [tapDatabaseSettingButton] first.
  Future<void> tapDatabaseLayoutButton() async {
    final findSettingItem = find.byType(DatabaseSettingItem);
    final findLayoutButton = find.byWidgetPredicate(
      (widget) =>
          widget is FlowyText &&
          widget.title == DatabaseSettingAction.showLayout.title(),
    );

    final button = find.descendant(
      of: findSettingItem,
      matching: findLayoutButton,
    );

    await tapButton(button);
  }

  Future<void> selectDatabaseLayoutType(DatabaseLayoutPB layout) async {
    final findLayoutCell = find.byType(DatabaseViewLayoutCell);
    final findText = find.byWidgetPredicate(
      (widget) => widget is FlowyText && widget.title == layout.layoutName(),
    );

    final button = find.descendant(
      of: findLayoutCell,
      matching: findText,
    );

    await tapButton(button);
  }

  Future<void> assertCurrentDatabaseLayoutType(DatabaseLayoutPB layout) async {
    expect(finderForDatabaseLayoutType(layout), findsOneWidget);
  }

  Future<void> tapDatabaseRawDataButton() async {
    await tapButtonWithName(LocaleKeys.importPanel_database.tr());
  }
}

Finder finderForDatabaseLayoutType(DatabaseLayoutPB layout) {
  switch (layout) {
    case DatabaseLayoutPB.Board:
      return find.byType(BoardPage);
    case DatabaseLayoutPB.Calendar:
      return find.byType(CalendarPage);
    case DatabaseLayoutPB.Grid:
      return find.byType(GridPage);
    default:
      throw Exception('Unknown database layout type: $layout');
  }
}

Finder finderForFieldType(FieldType fieldType) {
  switch (fieldType) {
    case FieldType.Checkbox:
      return find.byType(GridCheckboxCell, skipOffstage: false);
    case FieldType.DateTime:
      return find.byType(GridDateCell, skipOffstage: false);
    case FieldType.LastEditedTime:
    case FieldType.CreatedTime:
      return find.byType(GridDateCell, skipOffstage: false);
    case FieldType.SingleSelect:
      return find.byType(GridSingleSelectCell, skipOffstage: false);
    case FieldType.MultiSelect:
      return find.byType(GridMultiSelectCell, skipOffstage: false);
    case FieldType.Checklist:
      return find.byType(GridChecklistCell, skipOffstage: false);
    case FieldType.Number:
      return find.byType(GridNumberCell, skipOffstage: false);
    case FieldType.RichText:
      return find.byType(GridTextCell, skipOffstage: false);
    case FieldType.URL:
      return find.byType(GridURLCell, skipOffstage: false);
    default:
      throw Exception('Unknown field type: $fieldType');
  }
}
