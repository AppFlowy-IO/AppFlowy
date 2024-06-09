import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/mobile/presentation/database/field/mobile_field_bottom_sheets.dart';
import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/util/field_type_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class MobileFieldButton extends StatelessWidget {
  const MobileFieldButton.first({
    super.key,
    required this.viewId,
    required this.fieldController,
    required this.fieldInfo,
  })  : radius = const BorderRadius.only(topLeft: Radius.circular(24)),
        margin = const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        index = null;

  const MobileFieldButton({
    super.key,
    required this.viewId,
    required this.fieldController,
    required this.fieldInfo,
    required this.index,
  })  : radius = BorderRadius.zero,
        margin = const EdgeInsets.symmetric(vertical: 14, horizontal: 12);

  final String viewId;
  final int? index;
  final FieldController fieldController;
  final FieldInfo fieldInfo;
  final BorderRadius? radius;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    Widget child = Container(
      width: 200,
      decoration: _getDecoration(context),
      child: FlowyButton(
        onTap: () =>
            showQuickEditField(context, viewId, fieldController, fieldInfo),
        radius: radius,
        margin: margin,
        leftIconSize: const Size.square(18),
        leftIcon: FlowySvg(
          fieldInfo.fieldType.svgData,
          size: const Size.square(18),
        ),
        text: FlowyText(
          fieldInfo.name,
          fontSize: 15,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );

    if (index != null) {
      child = ReorderableDelayedDragStartListener(index: index!, child: child);
    }

    return child;
  }

  BoxDecoration? _getDecoration(BuildContext context) {
    final borderSide = BorderSide(
      color: Theme.of(context).dividerColor,
    );

    if (index == null) {
      return BoxDecoration(
        borderRadius: const BorderRadiusDirectional.only(
          topStart: Radius.circular(24),
        ),
        border: BorderDirectional(
          top: borderSide,
          start: borderSide,
        ),
      );
    } else {
      return null;
    }
  }
}
