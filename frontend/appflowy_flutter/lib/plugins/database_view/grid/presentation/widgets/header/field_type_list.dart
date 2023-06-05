import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:appflowy_backend/protobuf/flowy-database/field_entities.pb.dart';
import 'package:flutter/material.dart';
import '../../layout/sizes.dart';
import 'field_type_extension.dart';

typedef SelectFieldCallback = void Function(FieldType);

class FieldTypeList extends StatelessWidget with FlowyOverlayDelegate {
  final SelectFieldCallback onSelectField;
  const FieldTypeList({required this.onSelectField, final Key? key})
      : super(key: key);

  @override
  Widget build(final BuildContext context) {
    final cells = FieldType.values.map((final fieldType) {
      return FieldTypeCell(
        fieldType: fieldType,
        onSelectField: (final fieldType) {
          onSelectField(fieldType);
          PopoverContainer.of(context).closeAll();
        },
      );
    }).toList();

    return SizedBox(
      width: 140,
      child: ListView.separated(
        shrinkWrap: true,
        controller: ScrollController(),
        itemCount: cells.length,
        separatorBuilder: (final context, final index) {
          return VSpace(GridSize.typeOptionSeparatorHeight);
        },
        physics: StyledScrollPhysics(),
        itemBuilder: (final BuildContext context, final int index) {
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
    final Key? key,
  }) : super(key: key);

  @override
  Widget build(final BuildContext context) {
    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        text: FlowyText.medium(
          fieldType.title(),
        ),
        onTap: () => onSelectField(fieldType),
        leftIcon: FlowySvg(
          name: fieldType.iconName(),
        ),
      ),
    );
  }
}
