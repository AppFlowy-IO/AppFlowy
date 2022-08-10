import 'dart:typed_data';

import 'package:app_flowy/plugins/grid/application/field/type_option/multi_select_type_option.dart';
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
  final builder = makeTypeOptionWidgetBuilder(dataController, overlayDelegate);
  return builder.build(context);
}

TypeOptionWidgetBuilder makeTypeOptionWidgetBuilder(
  TypeOptionDataController dataController,
  TypeOptionOverlayDelegate overlayDelegate,
) {
  switch (dataController.field.fieldType) {
    case FieldType.Checkbox:
      final context = CheckboxTypeOptionContext(
        dataController: dataController,
        dataParser: CheckboxTypeOptionWidgetDataParser(),
      );
      return CheckboxTypeOptionWidgetBuilder(context);
    case FieldType.DateTime:
      final context = DateTypeOptionContext(
        dataController: dataController,
        dataParser: DateTypeOptionDataParser(),
      );
      return DateTypeOptionWidgetBuilder(
        context,
        overlayDelegate,
      );
    case FieldType.SingleSelect:
      final context = SingleSelectTypeOptionContext(
        dataController: dataController,
        dataBuilder: SingleSelectTypeOptionWidgetDataParser(),
      );
      return SingleSelectTypeOptionWidgetBuilder(
        context,
        overlayDelegate,
      );
    case FieldType.MultiSelect:
      final context = MultiSelectTypeOptionContext(
        dataController: dataController,
        dataParser: MultiSelectTypeOptionWidgetDataParser(),
      );
      return MultiSelectTypeOptionWidgetBuilder(
        context,
        overlayDelegate,
      );
    case FieldType.Number:
      final context = NumberTypeOptionContext(
        dataController: dataController,
        dataParser: NumberTypeOptionWidgetDataParser(),
      );
      return NumberTypeOptionWidgetBuilder(
        context,
        overlayDelegate,
      );
    case FieldType.RichText:
      final context = RichTextTypeOptionContext(
        dataController: dataController,
        dataParser: RichTextTypeOptionWidgetDataParser(),
      );
      return RichTextTypeOptionWidgetBuilder(context);

    case FieldType.URL:
      final context = URLTypeOptionContext(
        dataController: dataController,
        dataParser: URLTypeOptionWidgetDataParser(),
      );
      return URLTypeOptionWidgetBuilder(context);
  }
  throw UnimplementedError;
}
