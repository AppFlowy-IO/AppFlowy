import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet_database_field_editor.dart';
import 'package:appflowy/mobile/presentation/widgets/flowy_paginated_bottom_sheet.dart';
import 'package:appflowy/plugins/database_view/application/field/field_info.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
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
        onTap: () {
          showPaginatedBottomSheet(
            context,
            page: SheetPage(
              title: LocaleKeys.grid_field_editProperty.tr(),
              body: MobileDBBottomSheetFieldEditor(
                viewId: viewId,
                field: fieldInfo.field,
                fieldController: fieldController,
              ),
            ),
          );
        },
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
