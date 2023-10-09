import 'dart:typed_data';

import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_parser.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/checkbox_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/number_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/text_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/timestamp_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/url_entities.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flutter/widgets.dart';
import 'package:protobuf/protobuf.dart' hide FieldInfo;
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';

import 'checkbox.dart';
import 'checklist.dart';
import 'date.dart';
import 'multi_select.dart';
import 'number.dart';
import 'rich_text.dart';
import 'single_select.dart';
import 'timestamp.dart';
import 'url.dart';

typedef TypeOptionData = Uint8List;
typedef TypeOptionDataCallback = void Function(TypeOptionData typeOptionData);

class TypeOptionEditor extends StatelessWidget {
  final FieldPB field;
  final PopoverMutex popoverMutex;
  const TypeOptionEditor({
    required this.field,
    required this.popoverMutex,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final fieldType = field.fieldType;
    return switch (fieldType) {
      FieldType.Checkbox => CheckboxTypeOptionEditor(
          parser: makeTypeOptionParser<CheckboxTypeOptionPB>(fieldType),
          popoverMutex: popoverMutex,
        ),
      FieldType.DateTime => DateTimeTypeOptionEditor(
          parser: makeTypeOptionParser<DateTypeOptionPB>(fieldType),
          popoverMutex: popoverMutex,
        ),
      FieldType.LastEditedTime ||
      FieldType.CreatedTime =>
        TimestampTypeOptionEditor(
          parser: makeTypeOptionParser<TimestampTypeOptionPB>(fieldType),
          popoverMutex: popoverMutex,
        ),
      FieldType.SingleSelect => SingleSelectTypeOptionEditor(
          parser: makeTypeOptionParser<SingleSelectTypeOptionPB>(fieldType),
          popoverMutex: popoverMutex,
        ),
      FieldType.MultiSelect => MultiSelectTypeOptionEditor(
          parser: makeTypeOptionParser<MultiSelectTypeOptionPB>(fieldType),
          popoverMutex: popoverMutex,
        ),
      FieldType.Number => NumberTypeOptionEditor(
          parser: makeTypeOptionParser<NumberTypeOptionPB>(fieldType),
          popoverMutex: popoverMutex,
        ),
      FieldType.RichText => RichTextTypeOptionEditor(
          parser: makeTypeOptionParser<RichTextTypeOptionPB>(fieldType),
          popoverMutex: popoverMutex,
        ),
      FieldType.Checklist => ChecklistTypeOptionEditor(
          parser: makeTypeOptionParser<ChecklistTypeOptionPB>(fieldType),
          popoverMutex: popoverMutex,
        ),
      FieldType.URL => URLTypeOptionEditor(
          parser: makeTypeOptionParser<URLTypeOptionPB>(fieldType),
          popoverMutex: popoverMutex,
        ),
      _ => throw UnimplementedError(),
    };
  }
}

TypeOptionParser<T> makeTypeOptionParser<T extends GeneratedMessage>(
  FieldType fieldType,
) {
  return switch (fieldType) {
    FieldType.Checkbox => CheckboxTypeOptionDataParser(),
    FieldType.DateTime => DateTypeOptionDataParser(),
    FieldType.LastEditedTime ||
    FieldType.CreatedTime =>
      TimestampTypeOptionDataParser(),
    FieldType.SingleSelect => SingleSelectTypeOptionDataParser(),
    FieldType.MultiSelect => MultiSelectTypeOptionDataParser(),
    FieldType.Checklist => ChecklistTypeOptionDataParser(),
    FieldType.Number => NumberTypeOptionDataParser(),
    FieldType.RichText => RichTextTypeOptionDataParser(),
    FieldType.URL => URLTypeOptionDataParser(),
    _ => throw UnimplementedError,
  } as TypeOptionParser<T>;
}
