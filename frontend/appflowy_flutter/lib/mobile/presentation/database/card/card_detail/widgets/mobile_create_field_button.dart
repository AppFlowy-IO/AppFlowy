import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/database/field/mobile_field_bottom_sheets.dart';
import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class MobileRowDetailCreateFieldButton extends StatelessWidget {
  const MobileRowDetailCreateFieldButton({
    super.key,
    required this.viewId,
    required this.fieldController,
  });

  final String viewId;
  final FieldController fieldController;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: double.infinity,
        minHeight: GridSize.headerHeight,
      ),
      child: TextButton.icon(
        style: Theme.of(context).textButtonTheme.style?.copyWith(
              shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              overlayColor: WidgetStateProperty.all<Color>(
                Theme.of(context).hoverColor,
              ),
              alignment: AlignmentDirectional.centerStart,
              splashFactory: NoSplash.splashFactory,
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(vertical: 14, horizontal: 6),
              ),
            ),
        label: FlowyText.medium(
          LocaleKeys.grid_field_newProperty.tr(),
          fontSize: 15,
        ),
        onPressed: () => mobileCreateFieldWorkflow(context, viewId),
        icon: const FlowySvg(FlowySvgs.add_m),
      ),
    );
  }
}
