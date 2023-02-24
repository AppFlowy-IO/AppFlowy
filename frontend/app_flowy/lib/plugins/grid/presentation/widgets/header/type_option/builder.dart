import 'dart:typed_data';

import 'package:app_flowy/plugins/grid/application/field/field_controller.dart';
import 'package:app_flowy/plugins/grid/application/field/type_option/type_option_context.dart';
import 'package:app_flowy/plugins/grid/application/field/type_option/type_option_data_controller.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:appflowy_backend/protobuf/flowy-database/checkbox_type_option.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/checklist_type_option.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/date_type_option.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/multi_select_type_option.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/number_type_option.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/single_select_type_option.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/text_type_option.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database/url_type_option.pb.dart';
import 'package:protobuf/protobuf.dart' hide FieldInfo;
import 'package:appflowy_backend/protobuf/flowy-database/field_entities.pb.dart';
import 'package:flutter/material.dart';
import 'checkbox.dart';
import 'checklist.dart';
import 'date.dart';
import 'multi_select.dart';
import 'number.dart';
import 'rich_text.dart';
import 'single_select.dart';
import 'url.dart';

typedef TypeOptionData = Uint8List;
typedef TypeOptionDataCallback = void Function(TypeOptionData typeOptionData);
typedef ShowOverlayCallback = void Function(
  BuildContext anchorContext,
  Widget child, {
  VoidCallback? onRemoved,
});
typedef HideOverlayCallback = void Function(BuildContext anchorContext);

class TypeOptionOverlayDelegate {
  ShowOverlayCallback showOverlay;
  HideOverlayCallback hideOverlay;
  TypeOptionOverlayDelegate({
    required this.showOverlay,
    required this.hideOverlay,
  });
}

abstract class TypeOptionWidgetBuilder {
  Widget? build(BuildContext context);
}

Widget? makeTypeOptionWidget({
  required BuildContext context,
  required TypeOptionDataController dataController,
  required PopoverMutex popoverMutex,
}) {
  final builder = makeTypeOptionWidgetBuilder(
    dataController: dataController,
    popoverMutex: popoverMutex,
  );
  return builder.build(context);
}

TypeOptionWidgetBuilder makeTypeOptionWidgetBuilder({
  required TypeOptionDataController dataController,
  required PopoverMutex popoverMutex,
}) {
  final databaseId = dataController.databaseId;
  final fieldType = dataController.field.fieldType;

  switch (dataController.field.fieldType) {
    case FieldType.Checkbox:
      return CheckboxTypeOptionWidgetBuilder(
        makeTypeOptionContextWithDataController<CheckboxTypeOptionPB>(
          databaseId: databaseId,
          fieldType: fieldType,
          dataController: dataController,
        ),
      );
    case FieldType.DateTime:
      return DateTypeOptionWidgetBuilder(
          makeTypeOptionContextWithDataController<DateTypeOptionPB>(
            databaseId: databaseId,
            fieldType: fieldType,
            dataController: dataController,
          ),
          popoverMutex);
    case FieldType.SingleSelect:
      return SingleSelectTypeOptionWidgetBuilder(
        makeTypeOptionContextWithDataController<SingleSelectTypeOptionPB>(
          databaseId: databaseId,
          fieldType: fieldType,
          dataController: dataController,
        ),
        popoverMutex,
      );
    case FieldType.MultiSelect:
      return MultiSelectTypeOptionWidgetBuilder(
        makeTypeOptionContextWithDataController<MultiSelectTypeOptionPB>(
          databaseId: databaseId,
          fieldType: fieldType,
          dataController: dataController,
        ),
        popoverMutex,
      );
    case FieldType.Number:
      return NumberTypeOptionWidgetBuilder(
        makeTypeOptionContextWithDataController<NumberTypeOptionPB>(
          databaseId: databaseId,
          fieldType: fieldType,
          dataController: dataController,
        ),
        popoverMutex,
      );
    case FieldType.RichText:
      return RichTextTypeOptionWidgetBuilder(
        makeTypeOptionContextWithDataController<RichTextTypeOptionPB>(
          databaseId: databaseId,
          fieldType: fieldType,
          dataController: dataController,
        ),
      );

    case FieldType.URL:
      return URLTypeOptionWidgetBuilder(
        makeTypeOptionContextWithDataController<URLTypeOptionPB>(
          databaseId: databaseId,
          fieldType: fieldType,
          dataController: dataController,
        ),
      );

    case FieldType.Checklist:
      return ChecklistTypeOptionWidgetBuilder(
        makeTypeOptionContextWithDataController<ChecklistTypeOptionPB>(
          databaseId: databaseId,
          fieldType: fieldType,
          dataController: dataController,
        ),
      );
  }
  throw UnimplementedError;
}

TypeOptionContext<T> makeTypeOptionContext<T extends GeneratedMessage>({
  required String databaseId,
  required FieldInfo fieldInfo,
}) {
  final loader =
      FieldTypeOptionLoader(viewId: databaseId, field: fieldInfo.field);
  final dataController = TypeOptionDataController(
    databaseId: databaseId,
    loader: loader,
    fieldInfo: fieldInfo,
  );
  return makeTypeOptionContextWithDataController(
    databaseId: databaseId,
    fieldType: fieldInfo.fieldType,
    dataController: dataController,
  );
}

TypeOptionContext<SingleSelectTypeOptionPB> makeSingleSelectTypeOptionContext({
  required String databaseId,
  required FieldPB fieldPB,
}) {
  return makeSelectTypeOptionContext(databaseId: databaseId, fieldPB: fieldPB);
}

TypeOptionContext<MultiSelectTypeOptionPB> makeMultiSelectTypeOptionContext({
  required String databaseId,
  required FieldPB fieldPB,
}) {
  return makeSelectTypeOptionContext(databaseId: databaseId, fieldPB: fieldPB);
}

TypeOptionContext<T> makeSelectTypeOptionContext<T extends GeneratedMessage>({
  required String databaseId,
  required FieldPB fieldPB,
}) {
  final loader = FieldTypeOptionLoader(
    viewId: databaseId,
    field: fieldPB,
  );
  final dataController = TypeOptionDataController(
    databaseId: databaseId,
    loader: loader,
  );
  final typeOptionContext = makeTypeOptionContextWithDataController<T>(
    databaseId: databaseId,
    fieldType: fieldPB.fieldType,
    dataController: dataController,
  );
  return typeOptionContext;
}

TypeOptionContext<T>
    makeTypeOptionContextWithDataController<T extends GeneratedMessage>({
  required String databaseId,
  required FieldType fieldType,
  required TypeOptionDataController dataController,
}) {
  switch (fieldType) {
    case FieldType.Checkbox:
      return CheckboxTypeOptionContext(
        dataController: dataController,
        dataParser: CheckboxTypeOptionWidgetDataParser(),
      ) as TypeOptionContext<T>;
    case FieldType.DateTime:
      return DateTypeOptionContext(
        dataController: dataController,
        dataParser: DateTypeOptionDataParser(),
      ) as TypeOptionContext<T>;
    case FieldType.SingleSelect:
      return SingleSelectTypeOptionContext(
        dataController: dataController,
        dataParser: SingleSelectTypeOptionWidgetDataParser(),
      ) as TypeOptionContext<T>;
    case FieldType.MultiSelect:
      return MultiSelectTypeOptionContext(
        dataController: dataController,
        dataParser: MultiSelectTypeOptionWidgetDataParser(),
      ) as TypeOptionContext<T>;
    case FieldType.Checklist:
      return ChecklistTypeOptionContext(
        dataController: dataController,
        dataParser: ChecklistTypeOptionWidgetDataParser(),
      ) as TypeOptionContext<T>;
    case FieldType.Number:
      return NumberTypeOptionContext(
        dataController: dataController,
        dataParser: NumberTypeOptionWidgetDataParser(),
      ) as TypeOptionContext<T>;
    case FieldType.RichText:
      return RichTextTypeOptionContext(
        dataController: dataController,
        dataParser: RichTextTypeOptionWidgetDataParser(),
      ) as TypeOptionContext<T>;

    case FieldType.URL:
      return URLTypeOptionContext(
        dataController: dataController,
        dataParser: URLTypeOptionWidgetDataParser(),
      ) as TypeOptionContext<T>;
  }

  throw UnimplementedError;
}
