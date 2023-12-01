import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/util/field_type_extension.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

const _supportedFieldTypes = [
  FieldType.RichText,
  FieldType.Number,
  FieldType.URL,
  FieldType.SingleSelect,
  FieldType.MultiSelect,
  FieldType.DateTime,
  FieldType.Checkbox,
  FieldType.Checklist,
];

class FieldOptions extends StatelessWidget {
  const FieldOptions({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 24.0,
      children: _supportedFieldTypes
          .map(
            (e) => _Field(
              type: e,
              onTap: () {},
            ),
          )
          .toList(),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.type,
    required this.onTap,
  });

  final FieldType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          FlowySvg(
            type.svgData,
            blendMode: null,
            size: Size.square(width / 4.0),
          ),
          const VSpace(6.0),
          FlowyText(type.i18n),
        ],
      ),
    );
  }
}
