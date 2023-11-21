import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet_database_field_editor.dart';
import 'package:appflowy/plugins/database_view/application/field/field_info.dart';
import 'package:appflowy/plugins/database_view/grid/application/grid_bloc.dart';

import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'field_type_extension.dart';

class MobileFieldButton extends StatelessWidget {
  final String viewId;
  final FieldInfo field;
  final int? maxLines;
  final BorderRadius? radius;
  final EdgeInsets? margin;

  const MobileFieldButton({
    required this.viewId,
    required this.field,
    this.maxLines = 1,
    this.radius = BorderRadius.zero,
    this.margin,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final border = BorderSide(
      color: Theme.of(context).dividerColor,
      width: 1.0,
    );
    final fieldController =
        context.read<GridBloc>().databaseController.fieldController;
    return Container(
      width: field.fieldSettings!.width.toDouble(),
      decoration: BoxDecoration(
        border: Border(right: border, bottom: border),
      ),
      child: TextButton(
        onLongPress: () {
          showMobileBottomSheet(
            context: context,
            builder: (context) => MobileDBBottomSheetFieldEditor(
              viewId: viewId,
              field: field,
              fieldController: fieldController,
            ),
          );
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        ),
        onPressed: () {},
        child: Row(
          children: [
            FlowySvg(
              field.fieldType.icon(),
              color: Theme.of(context).iconTheme.color,
            ),
            const HSpace(6),
            Expanded(
              child: FlowyText.medium(
                field.name,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                color: AFThemeExtension.of(context).textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
