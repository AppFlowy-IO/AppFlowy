import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/util/field_type_extension.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';

typedef SelectFieldCallback = void Function(FieldType);

const List<FieldType> _supportedFieldTypes = [
  FieldType.RichText,
  FieldType.Number,
  FieldType.SingleSelect,
  FieldType.MultiSelect,
  FieldType.DateTime,
  FieldType.Media,
  FieldType.URL,
  FieldType.Checkbox,
  FieldType.Checklist,
  FieldType.LastEditedTime,
  FieldType.CreatedTime,
  FieldType.Relation,
  FieldType.Summary,
  FieldType.Translate,
  // FieldType.Time,
];

class FieldTypeList extends StatelessWidget with FlowyOverlayDelegate {
  const FieldTypeList({required this.onSelectField, super.key});

  final SelectFieldCallback onSelectField;

  @override
  Widget build(BuildContext context) {
    final cells = _supportedFieldTypes.map((fieldType) {
      return FieldTypeCell(
        fieldType: fieldType,
        onSelectField: (fieldType) {
          onSelectField(fieldType);
          PopoverContainer.of(context).closeAll();
        },
      );
    }).toList();

    return SizedBox(
      width: 140,
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: cells.length,
        separatorBuilder: (context, index) {
          return VSpace(GridSize.typeOptionSeparatorHeight);
        },
        physics: StyledScrollPhysics(),
        itemBuilder: (BuildContext context, int index) {
          return cells[index];
        },
      ),
    );
  }
}

class FieldTypeCell extends StatelessWidget {
  const FieldTypeCell({
    super.key,
    required this.fieldType,
    required this.onSelectField,
  });

  final FieldType fieldType;
  final SelectFieldCallback onSelectField;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        text: FlowyText(fieldType.i18n, lineHeight: 1.0),
        onTap: () => onSelectField(fieldType),
        leftIcon: FlowySvg(
          fieldType.svgData,
        ),
      ),
    );
  }
}
