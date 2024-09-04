import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/calculations/calculation_type_ext.dart';
import 'package:appflowy/plugins/database/board/presentation/board_page.dart';
import 'package:appflowy/plugins/database/board/presentation/widgets/board_column_header.dart';
import 'package:appflowy/plugins/database/calendar/application/calendar_bloc.dart';
import 'package:appflowy/plugins/database/calendar/presentation/calendar_day.dart';
import 'package:appflowy/plugins/database/calendar/presentation/calendar_event_card.dart';
import 'package:appflowy/plugins/database/calendar/presentation/calendar_event_editor.dart';
import 'package:appflowy/plugins/database/calendar/presentation/calendar_page.dart';
import 'package:appflowy/plugins/database/calendar/presentation/toolbar/calendar_layout_setting.dart';
import 'package:appflowy/plugins/database/grid/presentation/grid_page.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/calculations/calculate_cell.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/calculations/calculation_type_item.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/common/type_option_separator.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/choicechip/checkbox.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/choicechip/checklist/checklist.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/choicechip/select_option/option_list.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/choicechip/select_option/select_option.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/choicechip/text.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/create_filter_list.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/disclosure_button.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/filter_menu_item.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/footer/grid_footer.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/header/desktop_field_cell.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/row/row.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/sort/create_sort_list.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/sort/order_panel.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/sort/sort_editor.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/sort/sort_menu.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/toolbar/filter_button.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/toolbar/sort_button.dart';
import 'package:appflowy/plugins/database/tab_bar/desktop/tab_bar_add_button.dart';
import 'package:appflowy/plugins/database/tab_bar/desktop/tab_bar_header.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_skeleton/checkbox.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_skeleton/checklist.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_skeleton/date.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_skeleton/number.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_skeleton/select_option.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_skeleton/text.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_skeleton/timestamp.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_skeleton/url.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/checklist_cell_editor.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/checklist_progress_bar.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/date_editor.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/extension.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/select_option_cell_editor.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/select_option_text_field.dart';
import 'package:appflowy/plugins/database/widgets/database_layout_ext.dart';
import 'package:appflowy/plugins/database/widgets/field/field_editor.dart';
import 'package:appflowy/plugins/database/widgets/field/field_type_list.dart';
import 'package:appflowy/plugins/database/widgets/field/type_option_editor/date/date_time_format.dart';
import 'package:appflowy/plugins/database/widgets/field/type_option_editor/number.dart';
import 'package:appflowy/plugins/database/widgets/row/accessory/cell_accessory.dart';
import 'package:appflowy/plugins/database/widgets/row/row_action.dart';
import 'package:appflowy/plugins/database/widgets/row/row_banner.dart';
import 'package:appflowy/plugins/database/widgets/row/row_detail.dart';
import 'package:appflowy/plugins/database/widgets/row/row_document.dart';
import 'package:appflowy/plugins/database/widgets/row/row_property.dart';
import 'package:appflowy/plugins/database/widgets/setting/database_layout_selector.dart';
import 'package:appflowy/plugins/database/widgets/setting/database_setting_action.dart';
import 'package:appflowy/plugins/database/widgets/setting/database_settings_list.dart';
import 'package:appflowy/plugins/database/widgets/setting/setting_button.dart';
import 'package:appflowy/plugins/database/widgets/setting/setting_property_list.dart';
import 'package:appflowy/util/field_type_extension.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/clear_date_button.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/date_type_option_button.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/reminder_selector.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_board/appflowy_board.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/text_input.dart';
import 'package:flowy_infra_ui/widget/buttons/primary_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
// Non-exported member of the table_calendar library
import 'package:table_calendar/src/widgets/cell_content.dart';
import 'package:table_calendar/table_calendar.dart';

import 'base.dart';
import 'common_operations.dart';
import 'expectation.dart';
import 'mock/mock_file_picker.dart';

extension AppFlowyDatabaseTest on WidgetTester {
  Future<void> openV020database() async {
    final context = await initializeAppFlowy();
    await tapAnonymousSignInButton();

    // expect to see a readme page
    expectToSeePageName(gettingStarted);

    await tapAddViewButton();
    await tapImportButton();

    final testFileNames = ['v020.afdb'];
    final paths = <String>[];
    for (final fileName in testFileNames) {
      // Don't use the p.join to build the path that used in loadString. It
      // is not working on windows.
      final str = await rootBundle
          .loadString("assets/test/workspaces/database/$fileName");

      // Write the content to the file.
      final path = p.join(
        context.applicationDataDirectory,
        fileName,
      );
      paths.add(path);
      File(path).writeAsStringSync(str);
    }
    // mock get files
    mockPickFilePaths(
      paths: paths,
    );
    await tapDatabaseRawDataButton();
    await pumpAndSettle();
    await openPage('v020', layout: ViewLayoutPB.Grid);
  }

  Future<void> hoverOnFirstRowOfGrid([Future<void> Function()? onHover]) async {
    final findRow = find.byType(GridRow);
    expect(findRow, findsWidgets);

    final firstRow = findRow.first;
    await hoverOnWidget(firstRow, onHover: onHover);
  }

  Future<void> editCell({
    required int rowIndex,
    required FieldType fieldType,
    required String input,
    int cellIndex = 0,
  }) async {
    final cell = cellFinder(rowIndex, fieldType, cellIndex: cellIndex);

    expect(cell, findsOneWidget);
    await enterText(cell, input);
    await pumpAndSettle();
  }

  Finder cellFinder(int rowIndex, FieldType fieldType, {int cellIndex = 0}) {
    final findRow = find.byType(GridRow, skipOffstage: false);
    final findCell = finderForFieldType(fieldType);
    return find
        .descendant(
          of: findRow.at(rowIndex),
          matching: findCell,
          skipOffstage: false,
        )
        .at(cellIndex);
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
    final finder = isSelected
        ? find.byWidgetPredicate(
            (widget) =>
                widget is FlowySvg && widget.svg == FlowySvgs.check_filled_s,
          )
        : find.byWidgetPredicate(
            (widget) => widget is FlowySvg && widget.svg == FlowySvgs.uncheck_s,
          );

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
    await tapButton(cell);
  }

  /// The [fieldName] must be unique in the grid.
  void assertCellContent({
    required int rowIndex,
    required FieldType fieldType,
    required String content,
    int cellIndex = 0,
  }) {
    final findCell = cellFinder(rowIndex, fieldType, cellIndex: cellIndex);
    final findContent = find.descendant(
      of: findCell,
      matching: find.text(content),
      skipOffstage: false,
    );
    expect(findContent, findsOneWidget);
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
          (widget) =>
              widget is SelectOptionTag &&
              (widget.name == content || widget.option?.name == content),
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
            (widget) =>
                widget is SelectOptionTag &&
                (widget.name == content || widget.option?.name == content),
          ),
        );
        expect(finder, findsOneWidget);
      }
    }
  }

  /// null percent means no progress bar should be found
  void assertChecklistCellInGrid({
    required int rowIndex,
    required double? percent,
  }) {
    final findCell = cellFinder(rowIndex, FieldType.Checklist);

    if (percent == null) {
      final finder = find.descendant(
        of: findCell,
        matching: find.byType(ChecklistProgressBar),
      );
      expect(finder, findsNothing);
    } else {
      final finder = find.descendant(
        of: findCell,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is ChecklistProgressBar && widget.percent == percent,
        ),
      );
      expect(finder, findsOneWidget);
    }
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

    // if the day is very near the beginning or the end of the month,
    // it may overlap with the same day in the next or previous month,
    // respectively because it was spilling over. This will lead to 2
    // widgets being found and thus cannot be tapped correctly.
    if (content < 15) {
      // e.g., Jan 2 instead of Feb 2
      await tapButton(finder.first);
    } else {
      // e.g. Jun 28 instead of May 28
      await tapButton(finder.last);
    }
  }

  Future<void> toggleIncludeTime() async {
    final findDateEditor = find.byType(IncludeTimeButton);
    final findToggle = find.byType(Toggle);
    final finder = find.descendant(
      of: findDateEditor,
      matching: findToggle,
    );
    await tapButton(finder);
  }

  Future<void> selectReminderOption(ReminderOption option) async {
    await tapButton(find.byType(ReminderSelector));

    final finder = find.descendant(
      of: find.byType(FlowyButton),
      matching: find.textContaining(option.label),
    );

    await tapButton(finder);
  }

  Future<bool> selectLastDateInPicker() async {
    final finder = find.byType(CellContent).last;
    final w = widget(finder) as CellContent;

    await tapButton(finder);

    return w.isToday;
  }

  Future<void> tapChangeDateTimeFormatButton() async {
    await tapButton(find.byType(DateTypeOptionButton));
  }

  Future<void> changeDateFormat() async {
    final findDateFormatButton = find.byType(DateFormatButton);
    await tapButton(findDateFormatButton);

    final findNewDateFormat = find.text("Day/Month/Year");
    await tapButton(findNewDateFormat);
  }

  Future<void> changeTimeFormat() async {
    final findDateFormatButton = find.byType(TimeFormatButton);
    await tapButton(findDateFormatButton);

    final findNewDateFormat = find.text("12 hour");
    await tapButton(findNewDateFormat);
  }

  Future<void> clearDate() async {
    final findDateEditor = find.byType(DateCellEditor);
    final findClearButton = find.byType(ClearDateButton);
    final finder = find.descendant(
      of: findDateEditor,
      matching: findClearButton,
    );
    await tapButton(finder);
  }

  Future<void> tapSelectOptionCellInGrid({
    required int rowIndex,
    required FieldType fieldType,
  }) async {
    assert(
      fieldType == FieldType.SingleSelect || fieldType == FieldType.MultiSelect,
    );

    final findRow = find.byType(GridRow);
    final findCell = finderForFieldType(fieldType);

    final cell = find.descendant(
      of: findRow.at(rowIndex),
      matching: findCell,
    );

    await tapButton(cell);
  }

  /// The [SelectOptionCellEditor] must be opened first.
  Future<void> createOption({required String name}) async {
    final findEditor = find.byType(SelectOptionCellEditor);
    expect(findEditor, findsOneWidget);

    final findTextField = find.byType(SelectOptionTextField);
    expect(findTextField, findsOneWidget);

    await enterText(findTextField, name);
    await pump();

    await testTextInput.receiveAction(TextInputAction.done);
    await pumpAndSettle();
  }

  Future<void> selectOption({required String name}) async {
    final option = find.byWidgetPredicate(
      (widget) => widget is SelectOptionTagCell && widget.option.name == name,
    );

    await tapButton(option);
  }

  Future<void> findSelectOptionWithNameInGrid({
    required int rowIndex,
    required String name,
  }) async {
    final findRow = find.byType(GridRow);
    final option = find.byWidgetPredicate(
      (widget) =>
          widget is SelectOptionTag &&
          (widget.name == name || widget.option?.name == name),
    );

    final cell = find.descendant(of: findRow.at(rowIndex), matching: option);
    expect(cell, findsOneWidget);
  }

  Future<void> assertNumberOfSelectedOptionsInGrid({
    required int rowIndex,
    required Matcher matcher,
  }) async {
    final findRow = find.byType(GridRow);

    final options = find.byWidgetPredicate(
      (widget) => widget is SelectOptionTag,
    );

    final cell = find.descendant(of: findRow.at(rowIndex), matching: options);
    expect(cell, matcher);
  }

  Future<void> tapChecklistCellInGrid({required int rowIndex}) async {
    final findRow = find.byType(GridRow);
    final findCell = finderForFieldType(FieldType.Checklist);

    final cell = find.descendant(of: findRow.at(rowIndex), matching: findCell);
    await tapButton(cell);
  }

  void assertChecklistEditorVisible({required bool visible}) {
    final editor = find.byType(ChecklistCellEditor);
    if (visible) {
      return expect(editor, findsOneWidget);
    }
    expect(editor, findsNothing);
  }

  Future<void> createNewChecklistTask({
    required String name,
    enter = false,
    button = false,
  }) async {
    assert(!(enter && button));
    final textField = find.descendant(
      of: find.byType(NewTaskItem),
      matching: find.byType(TextField),
    );

    await enterText(textField, name);
    await pumpAndSettle();
    if (enter) {
      await testTextInput.receiveAction(TextInputAction.done);
      await pumpAndSettle();
    } else {
      await tapButton(
        find.descendant(
          of: find.byType(NewTaskItem),
          matching: find.byType(FlowyTextButton),
        ),
      );
    }
  }

  void assertChecklistTaskInEditor({
    required int index,
    required String name,
    required bool isChecked,
  }) {
    final task = find.byType(ChecklistItem).at(index);
    final widget = this.widget<ChecklistItem>(task);
    assert(
      widget.task.data.name == name && widget.task.isSelected == isChecked,
    );
  }

  Future<void> renameChecklistTask({
    required int index,
    required String name,
  }) async {
    final textField = find
        .descendant(
          of: find.byType(ChecklistItem),
          matching: find.byType(TextField),
        )
        .at(index);

    await enterText(textField, name);
    await testTextInput.receiveAction(TextInputAction.done);
    await pumpAndSettle();
  }

  Future<void> checkChecklistTask({required int index}) async {
    final button = find.descendant(
      of: find.byType(ChecklistItem).at(index),
      matching: find.byWidgetPredicate(
        (widget) => widget is FlowySvg && widget.svg == FlowySvgs.uncheck_s,
      ),
    );

    await tapButton(button);
  }

  Future<void> deleteChecklistTask({required int index}) async {
    final task = find.byType(ChecklistItem).at(index);

    await startGesture(getCenter(task), kind: PointerDeviceKind.mouse);
    await pumpAndSettle();

    final button = find.byWidgetPredicate(
      (widget) => widget is FlowySvg && widget.svg == FlowySvgs.delete_s,
    );

    await tapButton(button);
  }

  Future<void> openFirstRowDetailPage() async {
    await hoverOnFirstRowOfGrid();

    final expandButton = find.byType(PrimaryCellAccessory);
    expect(expandButton, findsOneWidget);
    await tapButton(expandButton);
  }

  void assertRowDetailPageOpened() async {
    final findRowDetailPage = find.byType(RowDetailPage);
    expect(findRowDetailPage, findsOneWidget);
  }

  Future<void> dismissRowDetailPage() async {
    // use tap empty area instead of clicking ESC to dismiss the row detail page
    // sometimes, the ESC key is not working.
    await simulateKeyEvent(LogicalKeyboardKey.escape);
    await pumpAndSettle();
    final findRowDetailPage = find.byType(RowDetailPage);
    if (findRowDetailPage.evaluate().isNotEmpty) {
      await tapAt(const Offset(0, 0));
      await pumpAndSettle();
    }
  }

  Future<void> hoverRowBanner() async {
    final banner = find.byType(RowBanner);
    expect(banner, findsOneWidget);

    await startGesture(getCenter(banner), kind: PointerDeviceKind.mouse);
    await pumpAndSettle();
  }

  Future<void> openEmojiPicker() async =>
      tapButton(find.byType(AddEmojiButton));

  Future<void> tapDateCellInRowDetailPage() async {
    final findDateCell = find.byType(EditableDateCell);
    await tapButton(findDateCell);
  }

  Future<void> tapGridFieldWithNameInRowDetailPage(String name) async {
    final fields = find.byWidgetPredicate(
      (widget) => widget is FieldCellButton && widget.field.name == name,
    );
    final field = find.descendant(
      of: find.byType(RowDetailPage),
      matching: fields,
    );
    await tapButton(field);
    await pumpAndSettle();
  }

  Future<TestGesture> hoverOnFieldInRowDetail({required int index}) async {
    final fieldButtons = find.byType(FieldCellButton);
    final button = find
        .descendant(of: find.byType(RowDetailPage), matching: fieldButtons)
        .at(index);
    return startGesture(getCenter(button), kind: PointerDeviceKind.mouse);
  }

  Future<void> reorderFieldInRowDetail({required double offset}) async {
    final thumb = find
        .byWidgetPredicate(
          (widget) => widget is ReorderableDragStartListener && widget.enabled,
        )
        .first;
    await drag(thumb, Offset(0, offset), kind: PointerDeviceKind.mouse);
    await pumpAndSettle();
  }

  void assertToggleShowHiddenFieldsVisibility(bool shown) {
    final button = find.byType(ToggleHiddenFieldsVisibilityButton);
    if (shown) {
      expect(button, findsOneWidget);
    } else {
      expect(button, findsNothing);
    }
  }

  Future<void> toggleShowHiddenFields() async {
    final button = find.byType(ToggleHiddenFieldsVisibilityButton);
    await tapButton(button);
  }

  Future<void> tapDeletePropertyInFieldEditor() async {
    final deleteButton = find.byWidgetPredicate(
      (w) => w is FieldActionCell && w.action == FieldAction.delete,
    );
    await tapButton(deleteButton);

    final confirmButton = find.descendant(
      of: find.byType(NavigatorAlertDialog),
      matching: find.byType(PrimaryTextButton),
    );
    await tapButton(confirmButton);
  }

  Future<void> scrollRowDetailByOffset(Offset offset) async {
    await drag(find.byType(RowDetailPage), offset);
    await pumpAndSettle();
  }

  Future<void> scrollToRight(Finder find) async {
    final size = getSize(find);
    await drag(find, Offset(-size.width, 0), warnIfMissed: false);
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

  Future<void> changeFieldTypeOfFieldWithName(
    String name,
    FieldType type, {
    ViewLayoutPB layout = ViewLayoutPB.Grid,
  }) async {
    await tapGridFieldWithName(name);
    if (layout == ViewLayoutPB.Grid) {
      await tapEditFieldButton();
    }

    await tapSwitchFieldTypeButton();
    await selectFieldType(type);
    await dismissFieldEditor();
  }

  Future<void> changeCalculateAtIndex(int index, CalculationType type) async {
    await tap(find.byType(CalculateCell).at(index));
    await pumpAndSettle();

    await tap(
      find.descendant(
        of: find.byType(CalculationTypeItem),
        matching: find.text(type.label),
      ),
    );
    await pumpAndSettle();
  }

  /// Should call [tapGridFieldWithName] first.
  Future<void> tapEditFieldButton() async {
    await tapButtonWithName(LocaleKeys.grid_field_editProperty.tr());
    await pumpAndSettle(const Duration(milliseconds: 200));
  }

  /// Should call [tapGridFieldWithName] first.
  Future<void> tapDeletePropertyButton() async {
    final field = find.byWidgetPredicate(
      (w) => w is FieldActionCell && w.action == FieldAction.delete,
    );
    await tapButton(field);
  }

  /// A SimpleDialog must be shown first, e.g. when deleting a field.
  Future<void> tapDialogOkButton() async {
    final field = find.byWidgetPredicate(
      (w) => w is PrimaryTextButton && w.label == LocaleKeys.button_ok.tr(),
    );
    await tapButton(field);
  }

  /// Should call [tapGridFieldWithName] first.
  Future<void> tapDuplicatePropertyButton() async {
    final field = find.byWidgetPredicate(
      (w) => w is FieldActionCell && w.action == FieldAction.duplicate,
    );
    await tapButton(field);
  }

  Future<void> tapInsertFieldButton({
    required bool left,
    required String name,
  }) async {
    final field = find.byWidgetPredicate(
      (widget) =>
          widget is FieldActionCell &&
          (left && widget.action == FieldAction.insertLeft ||
              !left && widget.action == FieldAction.insertRight),
    );
    await tapButton(field);
    await renameField(name);
  }

  /// Should call [tapGridFieldWithName] first.
  Future<void> tapHidePropertyButton() async {
    final field = find.byWidgetPredicate(
      (w) => w is FieldActionCell && w.action == FieldAction.toggleVisibility,
    );
    await tapButton(field);
  }

  Future<void> tapHidePropertyButtonInFieldEditor() async {
    final button = find.byWidgetPredicate(
      (w) => w is FieldActionCell && w.action == FieldAction.toggleVisibility,
    );
    await tapButton(button);
  }

  Future<void> tapRowDetailPageRowActionButton() async =>
      tapButton(find.byType(RowActionButton));

  Future<void> tapRowDetailPageCreatePropertyButton() async =>
      tapButton(find.byType(CreateRowFieldButton));

  Future<void> tapRowDetailPageDeleteRowButton() async =>
      tapButton(find.byType(RowDetailPageDeleteButton));

  Future<void> tapRowDetailPageDuplicateRowButton() async =>
      tapButton(find.byType(RowDetailPageDuplicateButton));

  Future<void> tapSwitchFieldTypeButton() async =>
      tapButton(find.byType(SwitchFieldButton));

  Future<void> tapEscButton() async => sendKeyEvent(LogicalKeyboardKey.escape);

  /// Must call [tapSwitchFieldTypeButton] first.
  Future<void> selectFieldType(FieldType fieldType) async {
    final fieldTypeCell = find.byType(FieldTypeCell);
    final fieldTypeButton = find.descendant(
      of: fieldTypeCell,
      matching: find.byWidgetPredicate(
        (widget) => widget is FlowyText && widget.text == fieldType.i18n,
      ),
    );
    await tapButton(fieldTypeButton);
  }

  // Use in edit mode of FieldEditor
  void expectEmptyTypeOptionEditor() => expect(
        find.descendant(
          of: find.byType(FieldTypeOptionEditor),
          matching: find.byType(TypeOptionSeparator),
        ),
        findsNothing,
      );

  /// Each field has its own cell, so we can find the corresponding cell by
  /// the field type after create a new field.
  Future<void> findCellByFieldType(FieldType fieldType) async {
    final finder = finderForFieldType(fieldType);
    expect(finder, findsWidgets);
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
  Future<void> assertFieldTypeWithFieldName(String name, FieldType type) async {
    final field = find.byWidgetPredicate(
      (widget) =>
          widget is FieldCellButton &&
          widget.field.fieldType == type &&
          widget.field.name == name,
    );

    expect(field, findsOneWidget);
  }

  void assertFirstFieldInRowDetailByType(FieldType fieldType) {
    final firstField = find
        .descendant(
          of: find.byType(RowDetailPage),
          matching: find.byType(FieldCellButton),
        )
        .first;

    final widget = this.widget<FieldCellButton>(firstField);
    expect(widget.field.fieldType, fieldType);
  }

  void findFieldWithName(String name) {
    final field = find.byWidgetPredicate(
      (widget) => widget is FieldCellButton && widget.field.name == name,
    );
    expect(field, findsOneWidget);
  }

  void noFieldWithName(String name) {
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

  Future<void> findDateEditor(dynamic matcher) async {
    final finder = find.byType(DateCellEditor);
    expect(finder, matcher);
  }

  Future<void> findSelectOptionEditor(dynamic matcher) async {
    final finder = find.byType(SelectOptionCellEditor);
    expect(finder, matcher);
  }

  Future<void> dismissCellEditor() async {
    await sendKeyEvent(LogicalKeyboardKey.escape);
    await pumpAndSettle();
  }

  Future<void> tapCreateRowButtonInGrid() async {
    await tapButton(find.byType(GridAddRowButton));
  }

  Future<void> tapCreateRowButtonInRowMenuOfGrid() async {
    await tapButton(find.byType(InsertRowButton));
  }

  Future<void> tapRowMenuButtonInGrid() async {
    expect(find.byType(RowMenuButton), findsOneWidget);
    await tapButton(find.byType(RowMenuButton));
  }

  /// Should call [tapRowMenuButtonInGrid] first.
  Future<void> tapDeleteOnRowMenu() async {
    expect(find.text(LocaleKeys.grid_row_delete.tr()), findsOneWidget);
    await tapButtonWithName(LocaleKeys.grid_row_delete.tr());
  }

  Future<void> createField(
    FieldType fieldType, {
    String? name,
    ViewLayoutPB layout = ViewLayoutPB.Grid,
  }) async {
    if (layout == ViewLayoutPB.Grid) {
      await scrollToRight(find.byType(GridPage));
    }
    await tapNewPropertyButton();
    if (name != null) {
      await renameField(name);
    }
    await tapSwitchFieldTypeButton();
    await selectFieldType(fieldType);
  }

  Future<void> tapDatabaseSettingButton() async {
    await tapButton(find.byType(SettingButton));
  }

  Future<void> tapDatabaseFilterButton() async {
    await tapButton(find.byType(FilterButton));
  }

  Future<void> tapDatabaseSortButton() async {
    await tapButton(find.byType(SortButton));
  }

  Future<void> tapCreateFilterByFieldType(FieldType type, String title) async {
    final findFilter = find.byWidgetPredicate(
      (widget) =>
          widget is GridFilterPropertyCell &&
          widget.fieldInfo.fieldType == type &&
          widget.fieldInfo.name == title,
    );
    await tapButton(findFilter);
  }

  Future<void> tapFilterButtonInGrid(String name) async {
    final findFilter = find.byType(FilterMenuItem);
    final button = find.descendant(of: findFilter, matching: find.text(name));
    await tapButton(button);
  }

  Future<void> tapCreateSortByFieldType(FieldType type, String title) async {
    final findSort = find.byWidgetPredicate(
      (widget) =>
          widget is GridSortPropertyCell &&
          widget.fieldInfo.fieldType == type &&
          widget.fieldInfo.name == title,
    );
    await tapButton(findSort);
  }

  // Must call [tapSortMenuInSettingBar] first.
  Future<void> tapCreateSortByFieldTypeInSortMenu(
    FieldType fieldType,
    String title,
  ) async {
    await tapButton(find.byType(DatabaseAddSortButton));

    final findSort = find.byWidgetPredicate(
      (widget) =>
          widget is GridSortPropertyCell &&
          widget.fieldInfo.fieldType == fieldType &&
          widget.fieldInfo.name == title,
    );

    await tapButton(findSort);
    await pumpAndSettle();
  }

  Future<void> tapSortMenuInSettingBar() async {
    await tapButton(find.byType(SortMenu));
    await pumpAndSettle();
  }

  /// Must call [tapSortMenuInSettingBar] first.
  Future<void> tapSortButtonByName(String name) async {
    final findSortItem = find.byWidgetPredicate(
      (widget) =>
          widget is DatabaseSortItem && widget.sortInfo.fieldInfo.name == name,
    );
    await tapButton(findSortItem);
  }

  /// Must call [tapSortMenuInSettingBar] first.
  Future<void> reorderSort(
    (FieldType, String) from,
    (FieldType, String) to,
  ) async {
    final fromSortItem = find.byWidgetPredicate(
      (widget) =>
          widget is DatabaseSortItem &&
          widget.sortInfo.fieldInfo.fieldType == from.$1 &&
          widget.sortInfo.fieldInfo.name == from.$2,
    );
    final toSortItem = find.byWidgetPredicate(
      (widget) =>
          widget is DatabaseSortItem &&
          widget.sortInfo.fieldInfo.fieldType == to.$1 &&
          widget.sortInfo.fieldInfo.name == to.$2,
    );
    final dragElement = find.descendant(
      of: fromSortItem,
      matching: find.byType(ReorderableDragStartListener),
    );
    await drag(dragElement, getCenter(toSortItem) - getCenter(fromSortItem));
    await pumpAndSettle(const Duration(milliseconds: 200));
  }

  /// Must call [tapSortButtonByName] first.
  Future<void> tapSortByDescending() async {
    await tapButton(
      find.descendant(
        of: find.byType(OrderPannelItem),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is FlowyText &&
              widget.text == LocaleKeys.grid_sort_descending.tr(),
        ),
      ),
    );
    await sendKeyEvent(LogicalKeyboardKey.escape);
    await pumpAndSettle();
  }

  /// Must call [tapSortMenuInSettingBar] first.
  Future<void> tapAllSortButton() async {
    await tapButton(find.byType(DeleteAllSortsButton));
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
    await tapButton(findCell);
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

  /// Should call [tapDatabaseSettingButton] first.
  Future<void> tapViewPropertiesButton() async {
    final findSettingItem = find.byType(DatabaseSettingsList);
    final findLayoutButton = find.byWidgetPredicate(
      (widget) =>
          widget is FlowyText &&
          widget.text == DatabaseSettingAction.showProperties.title(),
    );

    final button = find.descendant(
      of: findSettingItem,
      matching: findLayoutButton,
    );

    await tapButton(button);
  }

  /// Should call [tapDatabaseSettingButton] first.
  Future<void> tapDatabaseLayoutButton() async {
    final findSettingItem = find.byType(DatabaseSettingsList);
    final findLayoutButton = find.byWidgetPredicate(
      (widget) =>
          widget is FlowyText &&
          widget.text == DatabaseSettingAction.showLayout.title(),
    );

    final button = find.descendant(
      of: findSettingItem,
      matching: findLayoutButton,
    );

    await tapButton(button);
  }

  Future<void> tapCalendarLayoutSettingButton() async {
    final findSettingItem = find.byType(DatabaseSettingsList);
    final findLayoutButton = find.byWidgetPredicate(
      (widget) =>
          widget is FlowyText &&
          widget.text == DatabaseSettingAction.showCalendarLayout.title(),
    );

    final button = find.descendant(
      of: findSettingItem,
      matching: findLayoutButton,
    );

    await tapButton(button);
  }

  Future<void> tapFirstDayOfWeek() async =>
      tapButton(find.byType(FirstDayOfWeek));

  Future<void> tapFirstDayOfWeekStartFromMonday() async {
    final finder = find.byWidgetPredicate(
      (widget) => widget is StartFromButton && widget.dayIndex == 1,
    );
    await tapButton(finder);

    // Dismiss the popover overlay in cause of obscure the tapButton
    // in the next test case.
    await sendKeyEvent(LogicalKeyboardKey.escape);
    await pumpAndSettle(const Duration(milliseconds: 200));
  }

  void assertFirstDayOfWeekStartFromMonday() {
    final finder = find.byWidgetPredicate(
      (w) => w is StartFromButton && w.dayIndex == 1 && w.isSelected == true,
    );
    expect(finder, findsOneWidget);
  }

  void assertFirstDayOfWeekStartFromSunday() {
    final finder = find.byWidgetPredicate(
      (w) => w is StartFromButton && w.dayIndex == 0 && w.isSelected == true,
    );
    expect(finder, findsOneWidget);
  }

  Future<void> scrollToToday() async {
    final todayCell = find.byWidgetPredicate(
      (widget) => widget is CalendarDayCard && widget.isToday,
    );
    final scrollable = find
        .descendant(
          of: find.byType(MonthView<CalendarDayEvent>),
          matching: find.byWidgetPredicate(
            (widget) => widget is Scrollable && widget.axis == Axis.vertical,
          ),
        )
        .first;
    await scrollUntilVisible(todayCell, 300, scrollable: scrollable);
    await pumpAndSettle(const Duration(milliseconds: 300));
  }

  Future<void> hoverOnTodayCalendarCell({
    Future<void> Function()? onHover,
  }) async {
    final todayCell = find.byWidgetPredicate(
      (widget) => widget is CalendarDayCard && widget.isToday,
    );

    await hoverOnWidget(todayCell, onHover: onHover);
  }

  Future<void> tapAddCalendarEventButton() async {
    final findFlowyButton = find.byType(FlowyIconButton);
    final findNewEventButton = find.byType(NewEventButton);
    final button = find.descendant(
      of: findNewEventButton,
      matching: findFlowyButton,
    );
    await tapButton(button);
  }

  /// Checks for a certain number of events. Parameters [date] and [title] can
  /// also be provided to restrict the scope of the search
  void assertNumberOfEventsInCalendar(int number, {String? title}) {
    Finder findEvents = find.byType(EventCard);
    if (title != null) {
      findEvents = find.descendant(of: findEvents, matching: find.text(title));
    }
    expect(findEvents, findsNWidgets(number));
  }

  void assertNumberOfEventsOnSpecificDay(
    int number,
    DateTime date, {
    String? title,
  }) {
    final findDayCell = find.byWidgetPredicate(
      (widget) => widget is CalendarDayCard && isSameDay(widget.date, date),
    );
    Finder findEvents = find.descendant(
      of: findDayCell,
      matching: find.byType(EventCard),
    );
    if (title != null) {
      findEvents = find.descendant(of: findEvents, matching: find.text(title));
    }
    expect(findEvents, findsNWidgets(number));
  }

  Future<void> doubleClickCalendarCell(DateTime date) async {
    final todayCell = find.byWidgetPredicate(
      (widget) => widget is CalendarDayCard && isSameDay(date, widget.date),
    );
    final location = getTopLeft(todayCell).translate(10, 10);
    await doubleTapAt(location);
  }

  Future<void> openCalendarEvent({required int index, DateTime? date}) async {
    final findDayCell = find.byWidgetPredicate(
      (widget) =>
          widget is CalendarDayCard &&
          isSameDay(widget.date, date ?? DateTime.now()),
    );
    final cards = find.descendant(
      of: findDayCell,
      matching: find.byType(EventCard),
    );

    await tapButton(cards.at(index));
  }

  void assertEventEditorOpen() =>
      expect(find.byType(CalendarEventEditor), findsOneWidget);

  Future<void> dismissEventEditor() async =>
      simulateKeyEvent(LogicalKeyboardKey.escape);

  Future<void> editEventTitle(String title) async {
    final textField = find.descendant(
      of: find.byType(CalendarEventEditor),
      matching: find.byType(FlowyTextField),
    );

    await enterText(textField, title);
    await pumpAndSettle(const Duration(milliseconds: 300));
  }

  Future<void> openEventToRowDetailPage() async {
    final button = find.descendant(
      of: find.byType(CalendarEventEditor),
      matching: find.byWidgetPredicate(
        (widget) => widget is FlowySvg && widget.svg == FlowySvgs.full_view_s,
      ),
    );

    await tapButton(button);
  }

  Future<void> deleteEventFromEventEditor() async {
    final button = find.descendant(
      of: find.byType(CalendarEventEditor),
      matching: find.byWidgetPredicate(
        (widget) => widget is FlowySvg && widget.svg == FlowySvgs.delete_s,
      ),
    );

    await tapButton(button);
  }

  Future<void> dragDropRescheduleCalendarEvent() async {
    final findEventCard = find.byType(EventCard);
    await drag(findEventCard.first, const Offset(0, 300));
    await pumpAndSettle(const Duration(microseconds: 300));
  }

  Future<void> openUnscheduledEventsPopup() async {
    final button = find.byType(UnscheduledEventsButton);
    await tapButton(button);
  }

  void findUnscheduledPopup(Matcher matcher, int numUnscheduledEvents) {
    expect(find.byType(UnscheduleEventsList), matcher);
    if (matcher != findsNothing) {
      expect(
        find.byType(UnscheduledEventCell),
        findsNWidgets(numUnscheduledEvents),
      );
    }
  }

  Future<void> clickUnscheduledEvent() async {
    final unscheduledEvent = find.byType(UnscheduledEventCell);
    await tapButton(unscheduledEvent);
  }

  Future<void> tapCreateLinkedDatabaseViewButton(
    DatabaseLayoutPB layoutType,
  ) async {
    final findAddButton = find.byType(AddDatabaseViewButton);
    await tapButton(findAddButton);

    final findCreateButton = find.byWidgetPredicate(
      (widget) =>
          widget is TabBarAddButtonActionCell && widget.action == layoutType,
    );
    await tapButton(findCreateButton);
  }

  void assertNumberOfGroups(int number) {
    final groups = find.byType(BoardColumnHeader, skipOffstage: false);
    expect(groups, findsNWidgets(number));
  }

  Future<void> scrollBoardToEnd() async {
    final scrollable = find
        .descendant(
          of: find.byType(AppFlowyBoard),
          matching: find.byWidgetPredicate(
            (widget) => widget is Scrollable && widget.axis == Axis.horizontal,
          ),
        )
        .first;
    await scrollUntilVisible(
      find.byType(BoardTrailing),
      300,
      scrollable: scrollable,
    );
  }

  Future<void> tapNewGroupButton() async {
    final button = find.descendant(
      of: find.byType(BoardTrailing),
      matching: find.byWidgetPredicate(
        (widget) => widget is FlowySvg && widget.svg == FlowySvgs.add_s,
      ),
    );
    expect(button, findsOneWidget);
    await tapButton(button);
  }

  void assertNewGroupTextField(bool isVisible) {
    final textField = find.descendant(
      of: find.byType(BoardTrailing),
      matching: find.byType(TextField),
    );
    if (isVisible) {
      return expect(textField, findsOneWidget);
    }
    expect(textField, findsNothing);
  }

  Future<void> enterNewGroupName(String name, {required bool submit}) async {
    final textField = find.descendant(
      of: find.byType(BoardTrailing),
      matching: find.byType(TextField),
    );
    await enterText(textField, name);
    await pumpAndSettle();
    if (submit) {
      await testTextInput.receiveAction(TextInputAction.done);
      await pumpAndSettle();
    }
  }

  Future<void> clearNewGroupTextField() async {
    final textField = find.descendant(
      of: find.byType(BoardTrailing),
      matching: find.byType(TextField),
    );
    await tapButton(
      find.descendant(
        of: textField,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is FlowySvg && widget.svg == FlowySvgs.close_filled_m,
        ),
      ),
    );
    final textFieldWidget = widget<TextField>(textField);
    assert(
      textFieldWidget.controller != null &&
          textFieldWidget.controller!.text.isEmpty,
    );
  }

  Future<void> tapTabBarLinkedViewByViewName(String name) async {
    final viewButton = findTabBarLinkViewByViewName(name);
    await tapButton(viewButton);
  }

  Finder findTabBarLinkViewByViewLayout(ViewLayoutPB layout) {
    return find.byWidgetPredicate(
      (widget) => widget is TabBarItemButton && widget.view.layout == layout,
    );
  }

  Finder findTabBarLinkViewByViewName(String name) {
    return find.byWidgetPredicate(
      (widget) => widget is TabBarItemButton && widget.view.name == name,
    );
  }

  Future<void> renameLinkedView(Finder linkedView, String name) async {
    await tap(linkedView, buttons: kSecondaryButton);
    await pumpAndSettle();

    await tapButton(
      find.byWidgetPredicate(
        (widget) =>
            widget is ActionCellWidget &&
            widget.action == TabBarViewAction.rename,
      ),
    );

    await enterText(
      find.descendant(
        of: find.byType(FlowyFormTextInput),
        matching: find.byType(TextFormField),
      ),
      name,
    );

    final field = find.byWidgetPredicate(
      (widget) =>
          widget is PrimaryTextButton &&
          widget.label == LocaleKeys.button_ok.tr(),
    );
    await tapButton(field);
  }

  Future<void> deleteDatebaseView(Finder linkedView) async {
    await tap(linkedView, buttons: kSecondaryButton);
    await pumpAndSettle();

    await tapButton(
      find.byWidgetPredicate(
        (widget) =>
            widget is ActionCellWidget &&
            widget.action == TabBarViewAction.delete,
      ),
    );

    final okButton = find.byWidgetPredicate(
      (widget) =>
          widget is PrimaryTextButton &&
          widget.label == LocaleKeys.button_ok.tr(),
    );
    await tapButton(okButton);
  }

  void assertCurrentDatabaseTagIs(DatabaseLayoutPB layout) => switch (layout) {
        DatabaseLayoutPB.Board =>
          expect(find.byType(DesktopBoardPage), findsOneWidget),
        DatabaseLayoutPB.Calendar =>
          expect(find.byType(CalendarPage), findsOneWidget),
        DatabaseLayoutPB.Grid => expect(find.byType(GridPage), findsOneWidget),
        _ => throw Exception('Unknown database layout type: $layout'),
      };

  Future<void> selectDatabaseLayoutType(DatabaseLayoutPB layout) async {
    final findLayoutCell = find.byType(DatabaseViewLayoutCell);
    final findText = find.byWidgetPredicate(
      (widget) => widget is FlowyText && widget.text == layout.layoutName,
    );

    final button = find.descendant(of: findLayoutCell, matching: findText);
    await tapButton(button);
  }

  Future<void> assertCurrentDatabaseLayoutType(DatabaseLayoutPB layout) async {
    expect(finderForDatabaseLayoutType(layout), findsOneWidget);
  }

  Future<void> tapDatabaseRawDataButton() async {
    await tapButtonWithName(LocaleKeys.importPanel_database.tr());
  }

  // Use in edit mode of FieldEditor
  Future<void> changeNumberFieldFormat() async {
    final changeFormatButton = find.descendant(
      of: find.byType(FieldTypeOptionEditor),
      matching: find.text("Number"),
    );
    await tapButton(changeFormatButton);

    await tapButton(
      find.byWidgetPredicate(
        (w) => w is NumberFormatCell && w.format == NumberFormatPB.USD,
      ),
    );
  }

  // Use in edit mode of FieldEditor
  Future<void> tapAddSelectOptionButton() async {
    await tapButtonWithName(LocaleKeys.grid_field_addSelectOption.tr());
  }

  Future<void> tapViewTogglePropertyVisibilityButtonByName(
    String fieldName,
  ) async {
    final field = find.byWidgetPredicate(
      (w) => w is DatabasePropertyCell && w.fieldInfo.name == fieldName,
    );
    final toggleVisibilityButton =
        find.descendant(of: field, matching: find.byType(FlowyIconButton));
    await tapButton(toggleVisibilityButton);
  }
}

Finder finderForDatabaseLayoutType(DatabaseLayoutPB layout) => switch (layout) {
      DatabaseLayoutPB.Board => find.byType(DesktopBoardPage),
      DatabaseLayoutPB.Calendar => find.byType(CalendarPage),
      DatabaseLayoutPB.Grid => find.byType(GridPage),
      _ => throw Exception('Unknown database layout type: $layout'),
    };

Finder finderForFieldType(FieldType fieldType) {
  switch (fieldType) {
    case FieldType.Checkbox:
      return find.byType(EditableCheckboxCell, skipOffstage: false);
    case FieldType.DateTime:
      return find.byType(EditableDateCell, skipOffstage: false);
    case FieldType.LastEditedTime:
      return find.byWidgetPredicate(
        (widget) =>
            widget is EditableTimestampCell &&
            widget.fieldType == FieldType.LastEditedTime,
        skipOffstage: false,
      );
    case FieldType.CreatedTime:
      return find.byWidgetPredicate(
        (widget) =>
            widget is EditableTimestampCell &&
            widget.fieldType == FieldType.CreatedTime,
        skipOffstage: false,
      );
    case FieldType.SingleSelect:
      return find.byWidgetPredicate(
        (widget) =>
            widget is EditableSelectOptionCell &&
            widget.fieldType == FieldType.SingleSelect,
        skipOffstage: false,
      );
    case FieldType.MultiSelect:
      return find.byWidgetPredicate(
        (widget) =>
            widget is EditableSelectOptionCell &&
            widget.fieldType == FieldType.MultiSelect,
        skipOffstage: false,
      );
    case FieldType.Checklist:
      return find.byType(EditableChecklistCell, skipOffstage: false);
    case FieldType.Number:
      return find.byType(EditableNumberCell, skipOffstage: false);
    case FieldType.RichText:
      return find.byType(EditableTextCell, skipOffstage: false);
    case FieldType.URL:
      return find.byType(EditableURLCell, skipOffstage: false);
    default:
      throw Exception('Unknown field type: $fieldType');
  }
}
