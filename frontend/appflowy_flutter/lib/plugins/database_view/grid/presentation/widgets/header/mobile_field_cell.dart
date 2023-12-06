import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/mobile/presentation/database/field/bottom_sheet_create_field.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/field/field_info.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

import 'field_type_extension.dart';

class MobileFieldButton extends StatelessWidget {
  final String viewId;
  final FieldController fieldController;
  final FieldInfo fieldInfo;
  final int? maxLines;
  final BorderRadius? radius;
  final EdgeInsets? margin;

  const MobileFieldButton({
    required this.viewId,
    required this.fieldController,
    required this.fieldInfo,
    this.maxLines = 1,
    this.radius = BorderRadius.zero,
    this.margin,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fieldInfo.fieldSettings!.width.toDouble(),
      child: FlowyButton(
        onTap: () => showQuickEditField(context, viewId, fieldInfo),
        radius: BorderRadius.zero,
        margin: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        leftIconSize: const Size.square(18),
        leftIcon: FlowySvg(
          fieldInfo.fieldType.icon(),
          size: const Size.square(18),
        ),
        text: FlowyText(
          fieldInfo.name,
          fontSize: 15,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
