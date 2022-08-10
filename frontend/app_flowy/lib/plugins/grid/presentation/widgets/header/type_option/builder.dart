import 'dart:typed_data';

import 'package:app_flowy/plugins/grid/application/field/type_option/multi_select_type_option.dart';
import 'package:app_flowy/plugins/grid/application/field/type_option/type_option_data_controller.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/checkbox_type_option.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/date_type_option.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/multi_select_type_option.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/number_type_option.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/single_select_type_option.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/text_type_option.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/url_type_option.pb.dart';
import 'package:protobuf/protobuf.dart';
import 'package:app_flowy/plugins/grid/application/prelude.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flutter/material.dart';
import 'checkbox.dart';
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
  required TypeOptionOverlayDelegate overlayDelegate,
}) {
  final builder = makeTypeOptionWidgetBuilder(
    dataController: dataController,
    overlayDelegate: overlayDelegate,
  );
  return builder.build(context);
}

TypeOptionWidgetBuilder makeTypeOptionWidgetBuilder({
  required TypeOptionDataController dataController,
  required TypeOptionOverlayDelegate overlayDelegate,
}) {
  final gridId = dataController.gridId;
  final fieldType = dataController.field.fieldType;

  switch (dataController.field.fieldType) {
    case FieldType.Checkbox:
      return CheckboxTypeOptionWidgetBuilder(
        makeTypeOptionContextWithDataController<CheckboxTypeOption>(
          gridId: gridId,
          fieldType: fieldType,
          dataController: dataController,
        ),
      );
    case FieldType.DateTime:
      return DateTypeOptionWidgetBuilder(
        makeTypeOptionContextWithDataController<DateTypeOption>(
          gridId: gridId,
          fieldType: fieldType,
          dataController: dataController,
        ),
        overlayDelegate,
      );
    case FieldType.SingleSelect:
      return SingleSelectTypeOptionWidgetBuilder(
        makeTypeOptionContextWithDataController<SingleSelectTypeOptionPB>(
          gridId: gridId,
          fieldType: fieldType,
          dataController: dataController,
        ) as SingleSelectTypeOptionContext,
        overlayDelegate,
      );
    case FieldType.MultiSelect:
      return MultiSelectTypeOptionWidgetBuilder(
        makeTypeOptionContextWithDataController<MultiSelectTypeOption>(
          gridId: gridId,
          fieldType: fieldType,
          dataController: dataController,
        ) as MultiSelectTypeOptionContext,
        overlayDelegate,
      );
    case FieldType.Number:
      return NumberTypeOptionWidgetBuilder(
        makeTypeOptionContextWithDataController<NumberTypeOption>(
          gridId: gridId,
          fieldType: fieldType,
          dataController: dataController,
        ),
        overlayDelegate,
      );
    case FieldType.RichText:
      return RichTextTypeOptionWidgetBuilder(
        makeTypeOptionContextWithDataController<RichTextTypeOption>(
          gridId: gridId,
          fieldType: fieldType,
          dataController: dataController,
        ),
      );

    case FieldType.URL:
      return URLTypeOptionWidgetBuilder(
        makeTypeOptionContextWithDataController<URLTypeOption>(
          gridId: gridId,
          fieldType: fieldType,
          dataController: dataController,
        ),
      );
  }
  throw UnimplementedError;
}

TypeOptionContext<T> makeTypeOptionContext<T extends GeneratedMessage>({
  required String gridId,
  required GridFieldPB field,
}) {
  final loader = FieldTypeOptionLoader(gridId: gridId, field: field);
  final dataController = TypeOptionDataController(
    gridId: gridId,
    loader: loader,
    field: field,
  );
  return makeTypeOptionContextWithDataController(
    gridId: gridId,
    fieldType: field.fieldType,
    dataController: dataController,
  );
}

TypeOptionContext<T>
    makeTypeOptionContextWithDataController<T extends GeneratedMessage>({
  required String gridId,
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
        dataBuilder: SingleSelectTypeOptionWidgetDataParser(),
      ) as TypeOptionContext<T>;
    case FieldType.MultiSelect:
      return MultiSelectTypeOptionContext(
        dataController: dataController,
        dataParser: MultiSelectTypeOptionWidgetDataParser(),
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
