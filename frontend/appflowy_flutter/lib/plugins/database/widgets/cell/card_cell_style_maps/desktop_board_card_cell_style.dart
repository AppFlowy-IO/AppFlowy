import 'package:appflowy/plugins/database/widgets/cell/card_cell_skeleton/summary_card_cell.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:flutter/material.dart';

import '../card_cell_builder.dart';
import '../card_cell_skeleton/checkbox_card_cell.dart';
import '../card_cell_skeleton/checklist_card_cell.dart';
import '../card_cell_skeleton/date_card_cell.dart';
import '../card_cell_skeleton/number_card_cell.dart';
import '../card_cell_skeleton/relation_card_cell.dart';
import '../card_cell_skeleton/select_option_card_cell.dart';
import '../card_cell_skeleton/text_card_cell.dart';
import '../card_cell_skeleton/timestamp_card_cell.dart';
import '../card_cell_skeleton/url_card_cell.dart';
import '../card_cell_skeleton/time_card_cell.dart';

CardCellStyleMap desktopBoardCardCellStyleMap(BuildContext context) {
  const EdgeInsetsGeometry padding = EdgeInsets.all(4);
  final TextStyle textStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(
        fontSize: 11,
        overflow: TextOverflow.ellipsis,
        fontWeight: FontWeight.w400,
      );

  return {
    FieldType.Checkbox: CheckboxCardCellStyle(
      padding: padding,
      iconSize: const Size.square(16),
      showFieldName: true,
      textStyle: textStyle,
    ),
    FieldType.Checklist: ChecklistCardCellStyle(
      padding: padding,
      textStyle: textStyle.copyWith(color: Theme.of(context).hintColor),
    ),
    FieldType.CreatedTime: TimestampCardCellStyle(
      padding: padding,
      textStyle: textStyle,
    ),
    FieldType.DateTime: DateCardCellStyle(
      padding: padding,
      textStyle: textStyle,
    ),
    FieldType.LastEditedTime: TimestampCardCellStyle(
      padding: padding,
      textStyle: textStyle,
    ),
    FieldType.MultiSelect: SelectOptionCardCellStyle(
      padding: padding,
      tagFontSize: 11,
      wrap: true,
      tagPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    ),
    FieldType.Number: NumberCardCellStyle(
      padding: padding,
      textStyle: textStyle,
    ),
    FieldType.RichText: TextCardCellStyle(
      padding: padding,
      textStyle: textStyle,
      maxLines: 2,
      titleTextStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
            overflow: TextOverflow.ellipsis,
          ),
    ),
    FieldType.SingleSelect: SelectOptionCardCellStyle(
      padding: padding,
      tagFontSize: 11,
      wrap: true,
      tagPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    ),
    FieldType.URL: URLCardCellStyle(
      padding: padding,
      textStyle: textStyle.copyWith(
        color: Theme.of(context).colorScheme.primary,
        decoration: TextDecoration.underline,
      ),
    ),
    FieldType.Relation: RelationCardCellStyle(
      padding: padding,
      wrap: true,
      textStyle: textStyle,
    ),
    FieldType.Summary: SummaryCardCellStyle(
      padding: padding,
      textStyle: textStyle,
    ),
    FieldType.Time: TimeCardCellStyle(
      padding: padding,
      textStyle: textStyle,
    ),
  };
}
