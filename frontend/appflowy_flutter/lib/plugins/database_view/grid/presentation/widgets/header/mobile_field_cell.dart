import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/mobile/presentation/database/card/card_detail/mobile_edit_field_screen.dart';
import 'package:appflowy/mobile/presentation/database/card/card_detail/widgets/_field_options_eidtor.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/field/field_info.dart';
import 'package:appflowy/plugins/database_view/application/field/field_service.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
    return Container(
      width: fieldInfo.fieldSettings!.width.toDouble(),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1.0,
          ),
        ),
      ),
      child: FlowyButton(
        onTap: () async {
          final optionValues = await context.push<FieldOptionValues>(
            MobileEditPropertyScreen.routeName,
            extra: {
              MobileEditPropertyScreen.argViewId: viewId,
              MobileEditPropertyScreen.argField: fieldInfo.field,
              MobileEditPropertyScreen.argIsPrimary: fieldInfo.isPrimary,
            },
          );
          if (optionValues != null) {
            final fieldId = fieldInfo.field.id;
            final service = FieldBackendService(
              viewId: viewId,
              fieldId: fieldId,
            );

            if (optionValues.name != fieldInfo.name) {
              await service.updateField(name: optionValues.name);
            }

            if (optionValues.type != fieldInfo.fieldType) {
              await service.updateFieldType(fieldType: optionValues.type);
            }

            final data = optionValues.toTypeOptionBuffer();
            if (data != null) {
              await FieldBackendService.updateFieldTypeOption(
                viewId: viewId,
                fieldId: fieldId,
                typeOptionData: data,
              );
            }
          }
        },
        radius: BorderRadius.zero,
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        leftIcon: FlowySvg(
          fieldInfo.fieldType.icon(),
          color: Theme.of(context).hintColor,
        ),
        text: FlowyText.medium(
          fieldInfo.name,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          color: Theme.of(context).hintColor,
        ),
      ),
    );
  }
}
