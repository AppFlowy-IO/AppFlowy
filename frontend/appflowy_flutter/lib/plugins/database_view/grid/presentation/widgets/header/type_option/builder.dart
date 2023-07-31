import 'dart:typed_data';

import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_context.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_data_controller.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/checkbox_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/number_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/text_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/url_entities.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:protobuf/protobuf.dart' hide FieldInfo;
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
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
  required TypeOptionController dataController,
  required PopoverMutex popoverMutex,
}) {
  final builder = makeTypeOptionWidgetBuilder(
    dataController: dataController,
    popoverMutex: popoverMutex,
  );
  return builder.build(context);
}

TypeOptionWidgetBuilder makeTypeOptionWidgetBuilder({
  required TypeOptionController dataController,
  required PopoverMutex popoverMutex,
}) {
  final viewId = dataController.loader.viewId;
  final fieldType = dataController.field.fieldType;

  switch (dataController.field.fieldType) {
    case FieldType.Checkbox:
      return CheckboxTypeOptionWidgetBuilder(
        makeTypeOptionContextWithDataController<CheckboxTypeOptionPB>(
          viewId: viewId,
          fieldType: fieldType,
          dataController: dataController,
        ),
      );
    case FieldType.DateTime:
    case FieldType.LastEditedTime:
    case FieldType.CreatedTime:
      return DateTypeOptionWidgetBuilder(
        makeTypeOptionContextWithDataController<DateTypeOptionPB>(
          viewId: viewId,
          fieldType: fieldType,
          dataController: dataController,
        ),
        popoverMutex,
      );
    case FieldType.SingleSelect:
      return SingleSelectTypeOptionWidgetBuilder(
        makeTypeOptionContextWithDataController<SingleSelectTypeOptionPB>(
          viewId: viewId,
          fieldType: fieldType,
          dataController: dataController,
        ),
        popoverMutex,
      );
    case FieldType.MultiSelect:
      return MultiSelectTypeOptionWidgetBuilder(
        makeTypeOptionContextWithDataController<MultiSelectTypeOptionPB>(
          viewId: viewId,
          fieldType: fieldType,
          dataController: dataController,
        ),
        popoverMutex,
      );
    case FieldType.Number:
      return NumberTypeOptionWidgetBuilder(
        makeTypeOptionContextWithDataController<NumberTypeOptionPB>(
          viewId: viewId,
          fieldType: fieldType,
          dataController: dataController,
        ),
        popoverMutex,
      );
    case FieldType.RichText:
      return RichTextTypeOptionWidgetBuilder(
        makeTypeOptionContextWithDataController<RichTextTypeOptionPB>(
          viewId: viewId,
          fieldType: fieldType,
          dataController: dataController,
        ),
      );

    case FieldType.URL:
      return URLTypeOptionWidgetBuilder(
        makeTypeOptionContextWithDataController<URLTypeOptionPB>(
          viewId: viewId,
          fieldType: fieldType,
          dataController: dataController,
        ),
      );

    case FieldType.Checklist:
      return ChecklistTypeOptionWidgetBuilder(
        makeTypeOptionContextWithDataController<ChecklistTypeOptionPB>(
          viewId: viewId,
          fieldType: fieldType,
          dataController: dataController,
        ),
      );
  }
  throw UnimplementedError;
}

TypeOptionContext<T> makeTypeOptionContext<T extends GeneratedMessage>({
  required String viewId,
  required FieldInfo fieldInfo,
}) {
  final loader = FieldTypeOptionLoader(viewId: viewId, field: fieldInfo.field);
  final dataController = TypeOptionController(
    loader: loader,
    field: fieldInfo.field,
  );
  return makeTypeOptionContextWithDataController(
    viewId: viewId,
    fieldType: fieldInfo.fieldType,
    dataController: dataController,
  );
}

TypeOptionContext<SingleSelectTypeOptionPB> makeSingleSelectTypeOptionContext({
  required String viewId,
  required FieldPB fieldPB,
}) {
  return makeSelectTypeOptionContext(viewId: viewId, fieldPB: fieldPB);
}

TypeOptionContext<MultiSelectTypeOptionPB> makeMultiSelectTypeOptionContext({
  required String viewId,
  required FieldPB fieldPB,
}) {
  return makeSelectTypeOptionContext(viewId: viewId, fieldPB: fieldPB);
}

TypeOptionContext<T> makeSelectTypeOptionContext<T extends GeneratedMessage>({
  required String viewId,
  required FieldPB fieldPB,
}) {
  final loader = FieldTypeOptionLoader(
    viewId: viewId,
    field: fieldPB,
  );
  final dataController = TypeOptionController(
    loader: loader,
    field: fieldPB,
  );
  final typeOptionContext = makeTypeOptionContextWithDataController<T>(
    viewId: viewId,
    fieldType: fieldPB.fieldType,
    dataController: dataController,
  );
  return typeOptionContext;
}

TypeOptionContext<T>
    makeTypeOptionContextWithDataController<T extends GeneratedMessage>({
  required String viewId,
  required FieldType fieldType,
  required TypeOptionController dataController,
}) {
  switch (fieldType) {
    case FieldType.Checkbox:
      return CheckboxTypeOptionContext(
        dataController: dataController,
        dataParser: CheckboxTypeOptionWidgetDataParser(),
      ) as TypeOptionContext<T>;
    case FieldType.DateTime:
    case FieldType.LastEditedTime:
    case FieldType.CreatedTime:
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
