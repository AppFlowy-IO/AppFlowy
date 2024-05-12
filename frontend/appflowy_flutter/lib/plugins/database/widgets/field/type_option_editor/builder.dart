import 'dart:typed_data';

import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flutter/material.dart';

import 'checkbox.dart';
import 'checklist.dart';
import 'date.dart';
import 'multi_select.dart';
import 'number.dart';
import 'relation.dart';
import 'rich_text.dart';
import 'single_select.dart';
import 'summary.dart';
import 'timestamp.dart';
import 'url.dart';
import 'timer.dart';

typedef TypeOptionDataCallback = void Function(Uint8List typeOptionData);

abstract class TypeOptionEditorFactory {
  factory TypeOptionEditorFactory.makeBuilder(FieldType fieldType) {
    return switch (fieldType) {
      FieldType.RichText => const RichTextTypeOptionEditorFactory(),
      FieldType.Number => const NumberTypeOptionEditorFactory(),
      FieldType.URL => const URLTypeOptionEditorFactory(),
      FieldType.DateTime => const DateTypeOptionEditorFactory(),
      FieldType.LastEditedTime => const TimestampTypeOptionEditorFactory(),
      FieldType.CreatedTime => const TimestampTypeOptionEditorFactory(),
      FieldType.SingleSelect => const SingleSelectTypeOptionEditorFactory(),
      FieldType.MultiSelect => const MultiSelectTypeOptionEditorFactory(),
      FieldType.Checkbox => const CheckboxTypeOptionEditorFactory(),
      FieldType.Checklist => const ChecklistTypeOptionEditorFactory(),
      FieldType.Relation => const RelationTypeOptionEditorFactory(),
      FieldType.Summary => const SummaryTypeOptionEditorFactory(),
      FieldType.Timer => const TimerTypeOptionEditorFactory(),
      _ => throw UnimplementedError(),
    };
  }

  Widget? build({
    required BuildContext context,
    required String viewId,
    required FieldPB field,
    required PopoverMutex popoverMutex,
    required TypeOptionDataCallback onTypeOptionUpdated,
  });
}

Widget? makeTypeOptionEditor({
  required BuildContext context,
  required String viewId,
  required FieldPB field,
  required PopoverMutex popoverMutex,
  required TypeOptionDataCallback onTypeOptionUpdated,
}) {
  final editorBuilder = TypeOptionEditorFactory.makeBuilder(field.fieldType);
  return editorBuilder.build(
    context: context,
    viewId: viewId,
    field: field,
    onTypeOptionUpdated: onTypeOptionUpdated,
    popoverMutex: popoverMutex,
  );
}
