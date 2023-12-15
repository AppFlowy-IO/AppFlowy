import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

import '../../layout/sizes.dart';
import 'field_type_extension.dart';

typedef SelectFieldCallback = void Function(FieldType);

class FieldTypeList extends StatelessWidget with FlowyOverlayDelegate {
  final SelectFieldCallback onSelectField;
  const FieldTypeList({required this.onSelectField, super.key});

  @override
  Widget build(BuildContext context) {
    final cells = FieldType.values.map((fieldType) {
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
  final FieldType fieldType;
  final SelectFieldCallback onSelectField;
  const FieldTypeCell({
    required this.fieldType,
    required this.onSelectField,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        text: FlowyText.medium(
          fieldType.title(),
        ),
        onTap: () => onSelectField(fieldType),
        leftIcon: FlowySvg(
          fieldType.icon(),
        ),
      ),
    );
  }
}
