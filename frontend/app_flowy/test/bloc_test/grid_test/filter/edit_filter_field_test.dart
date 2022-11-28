import 'package:app_flowy/plugins/grid/application/field/field_editor_bloc.dart';
import 'package:app_flowy/plugins/grid/application/field/type_option/type_option_context.dart';
import 'package:app_flowy/plugins/grid/application/filter/filter_menu_bloc.dart';
import 'package:app_flowy/plugins/grid/application/filter/filter_service.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/text_filter.pb.dart';
import 'package:flutter_test/flutter_test.dart';

import '../util.dart';

void main() {
  late AppFlowyGridTest gridTest;
  setUpAll(() async {
    gridTest = await AppFlowyGridTest.ensureInitialized();
  });

  test("create a text filter and then alter the filter's field)", () async {
    final context = await gridTest.createTestGrid();
    final service = FilterFFIService(viewId: context.gridView.id);
    final textField = context.textFieldContext();

    // Create the filter menu bloc
    final menuBloc = GridFilterMenuBloc(
      fieldController: context.fieldController,
      viewId: context.gridView.id,
    )..add(const GridFilterMenuEvent.initial());

    // Insert filter for the text field
    await service.insertTextFilter(
        fieldId: textField.id,
        condition: TextFilterCondition.TextIsEmpty,
        content: "");
    await gridResponseFuture();
    assert(menuBloc.state.filters.length == 1);

    // Edit the text field
    final loader = FieldTypeOptionLoader(
      gridId: context.gridView.id,
      field: textField.field,
    );

    final editorBloc = FieldEditorBloc(
      gridId: context.gridView.id,
      fieldName: textField.field.name,
      isGroupField: false,
      loader: loader,
    )..add(const FieldEditorEvent.initial());
    await gridResponseFuture();

    // Alter the field type to Number
    editorBloc.add(const FieldEditorEvent.switchToField(FieldType.Number));
    await gridResponseFuture();

    // Check the number of filters
    assert(menuBloc.state.filters.isEmpty);
  });
}
