import 'dart:typed_data';

import 'package:app_flowy/workspace/application/grid/field/type_option/multi_select_type_option.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/header/type_option/checkbox.dart';
import 'package:app_flowy/workspace/application/grid/prelude.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pb.dart';
import 'package:flutter/material.dart';
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
  required GridFieldContext fieldContext,
  required TypeOptionOverlayDelegate overlayDelegate,
}) {
  final builder = makeTypeOptionWidgetBuilder(fieldContext, overlayDelegate);
  return builder.build(context);
}

TypeOptionWidgetBuilder makeTypeOptionWidgetBuilder(
  GridFieldContext fieldContext,
  TypeOptionOverlayDelegate overlayDelegate,
) {
  switch (fieldContext.field.fieldType) {
    case FieldType.Checkbox:
      final context = CheckboxTypeOptionContext(
        fieldContext: fieldContext,
        dataBuilder: CheckboxTypeOptionWidgetDataParser(),
      );
      return CheckboxTypeOptionWidgetBuilder(context);
    case FieldType.DateTime:
      final context = DateTypeOptionContext(
        fieldContext: fieldContext,
        dataBuilder: DateTypeOptionDataParser(),
      );
      return DateTypeOptionWidgetBuilder(
        context,
        overlayDelegate,
      );
    case FieldType.SingleSelect:
      final context = SingleSelectTypeOptionContext(
        fieldContext: fieldContext,
        dataBuilder: SingleSelectTypeOptionWidgetDataParser(),
      );
      return SingleSelectTypeOptionWidgetBuilder(
        context,
        overlayDelegate,
      );
    case FieldType.MultiSelect:
      final context = MultiSelectTypeOptionContext(
        fieldContext: fieldContext,
        dataBuilder: MultiSelectTypeOptionWidgetDataParser(),
      );
      return MultiSelectTypeOptionWidgetBuilder(
        context,
        overlayDelegate,
      );
    case FieldType.Number:
      final context = NumberTypeOptionContext(
        fieldContext: fieldContext,
        dataBuilder: NumberTypeOptionWidgetDataParser(),
      );
      return NumberTypeOptionWidgetBuilder(
        context,
        overlayDelegate,
      );
    case FieldType.RichText:
      final context = RichTextTypeOptionContext(
        fieldContext: fieldContext,
        dataBuilder: RichTextTypeOptionWidgetDataParser(),
      );
      return RichTextTypeOptionWidgetBuilder(context);

    case FieldType.URL:
      final context = URLTypeOptionContext(
        fieldContext: fieldContext,
        dataBuilder: URLTypeOptionWidgetDataParser(),
      );
      return URLTypeOptionWidgetBuilder(context);
  }
  throw UnimplementedError;
}
