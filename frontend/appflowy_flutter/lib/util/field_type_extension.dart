import 'dart:ui';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';

extension FieldTypeExtension on FieldType {
  String get i18n => switch (this) {
        FieldType.RichText => LocaleKeys.grid_field_textFieldName.tr(),
        FieldType.Number => LocaleKeys.grid_field_numberFieldName.tr(),
        FieldType.DateTime => LocaleKeys.grid_field_dateFieldName.tr(),
        FieldType.SingleSelect =>
          LocaleKeys.grid_field_singleSelectFieldName.tr(),
        FieldType.MultiSelect =>
          LocaleKeys.grid_field_multiSelectFieldName.tr(),
        FieldType.Checkbox => LocaleKeys.grid_field_checkboxFieldName.tr(),
        FieldType.Checklist => LocaleKeys.grid_field_checklistFieldName.tr(),
        FieldType.URL => LocaleKeys.grid_field_urlFieldName.tr(),
        FieldType.LastEditedTime =>
          LocaleKeys.grid_field_updatedAtFieldName.tr(),
        FieldType.CreatedTime => LocaleKeys.grid_field_createdAtFieldName.tr(),
        _ => throw UnimplementedError(),
      };

  FlowySvgData get svgData => switch (this) {
        FieldType.RichText => FlowySvgs.text_s,
        FieldType.Number => FlowySvgs.number_s,
        FieldType.DateTime => FlowySvgs.date_s,
        FieldType.SingleSelect => FlowySvgs.single_select_s,
        FieldType.MultiSelect => FlowySvgs.multiselect_s,
        FieldType.Checkbox => FlowySvgs.checkbox_s,
        FieldType.URL => FlowySvgs.url_s,
        FieldType.Checklist => FlowySvgs.checklist_s,
        FieldType.LastEditedTime => FlowySvgs.last_modified_s,
        FieldType.CreatedTime => FlowySvgs.created_at_s,
        _ => throw UnimplementedError(),
      };

  Color get mobileIconBackgroundColor => switch (this) {
        FieldType.RichText => const Color(0xFFBECCFF),
        FieldType.Number => const Color(0xFFCABDFF),
        FieldType.DateTime => const Color(0xFFFDEDA7),
        FieldType.SingleSelect => const Color(0xFFBECCFF),
        FieldType.MultiSelect => const Color(0xFFBECCFF),
        FieldType.URL => const Color(0xFFFFB9EF),
        FieldType.Checkbox => const Color(0xFF98F4CD),
        FieldType.Checklist => const Color(0xFF98F4CD),
        FieldType.LastEditedTime => const Color(0xFFFDEDA7),
        FieldType.CreatedTime => const Color(0xFFFDEDA7),
        _ => throw UnimplementedError(),
      };
}
