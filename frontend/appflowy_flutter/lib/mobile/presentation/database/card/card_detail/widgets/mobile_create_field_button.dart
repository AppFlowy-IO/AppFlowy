import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/database/field/bottom_sheet_create_field.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
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
      constraints: const BoxConstraints(minWidth: double.infinity),
      child: TextButton.icon(
        style: Theme.of(context).textButtonTheme.style?.copyWith(
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  side: BorderSide.none,
                ),
              ),
              overlayColor: MaterialStateProperty.all<Color>(
                Theme.of(context).hoverColor,
              ),
              alignment: AlignmentDirectional.centerStart,
              splashFactory: NoSplash.splashFactory,
              padding: const MaterialStatePropertyAll(
                EdgeInsets.symmetric(vertical: 14, horizontal: 6),
              ),
            ),
        label: FlowyText.medium(
          LocaleKeys.grid_field_newProperty.tr(),
          fontSize: 15,
        ),
        onPressed: () => showCreateFieldBottomSheet(context, viewId),
        icon: const FlowySvg(FlowySvgs.add_m),
      ),
    );
  }
}
