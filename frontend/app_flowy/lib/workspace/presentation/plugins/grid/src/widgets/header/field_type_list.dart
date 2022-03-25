import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_list.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/meta.pb.dart';
import 'package:flutter/material.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef SelectFieldCallback = void Function(FieldType);

class FieldTypeList extends StatelessWidget {
  final SelectFieldCallback onSelectField;
  const FieldTypeList({required this.onSelectField, Key? key}) : super(key: key);

  static void show(BuildContext context, SelectFieldCallback onSelectField) {
    final list = FieldTypeList(onSelectField: onSelectField);
    FlowyOverlay.of(context).insertWithAnchor(
      widget: OverlayContainer(
        child: list,
        constraints: BoxConstraints.loose(const Size(140, 300)),
      ),
      identifier: list.identifier(),
      anchorContext: context,
      anchorDirection: AnchorDirection.leftWithCenterAligned,
      style: FlowyOverlayStyle(blur: false),
      anchorOffset: const Offset(-20, 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cells = FieldType.values.map((fieldType) {
      return FieldTypeCell(
        fieldType: fieldType,
        onSelectField: (fieldType) {
          onSelectField(fieldType);
          FlowyOverlay.of(context).remove(identifier());
        },
      );
    }).toList();

    return ListView.separated(
      shrinkWrap: true,
      controller: ScrollController(),
      itemCount: cells.length,
      separatorBuilder: (context, index) {
        return const VSpace(10);
      },
      physics: StyledScrollPhysics(),
      itemBuilder: (BuildContext context, int index) {
        return cells[index];
      },
    );
  }

  String identifier() {
    return toString();
  }
}

class FieldTypeCell extends StatelessWidget {
  final FieldType fieldType;
  final SelectFieldCallback onSelectField;
  const FieldTypeCell({
    required this.fieldType,
    required this.onSelectField,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();

    return SizedBox(
      height: 26,
      child: FlowyButton(
        text: FlowyText.medium(fieldType.title(), fontSize: 12),
        hoverColor: theme.hover,
        onTap: () => onSelectField(fieldType),
        leftIcon: svg(fieldType.iconName(), color: theme.iconColor),
      ),
    );
  }
}

extension FieldTypeListExtension on FieldType {
  String iconName() {
    switch (this) {
      case FieldType.Checkbox:
        return "grid/field/checkbox";
      case FieldType.DateTime:
        return "grid/field/date";
      case FieldType.MultiSelect:
        return "grid/field/multi_select";
      case FieldType.Number:
        return "grid/field/number";
      case FieldType.RichText:
        return "grid/field/text";
      case FieldType.SingleSelect:
        return "grid/field/single_select";
      default:
        throw UnimplementedError;
    }
  }

  String title() {
    switch (this) {
      case FieldType.Checkbox:
        return LocaleKeys.grid_field_checkboxFieldName.tr();
      case FieldType.DateTime:
        return LocaleKeys.grid_field_dateFieldName.tr();
      case FieldType.MultiSelect:
        return LocaleKeys.grid_field_multiSelectFieldName.tr();
      case FieldType.Number:
        return LocaleKeys.grid_field_numberFieldName.tr();
      case FieldType.RichText:
        return LocaleKeys.grid_field_textFieldName.tr();
      case FieldType.SingleSelect:
        return LocaleKeys.grid_field_singleSelectFieldName.tr();
      default:
        throw UnimplementedError;
    }
  }
}
