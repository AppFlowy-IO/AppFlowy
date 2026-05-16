import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/shared/google_fonts_extension.dart';
import 'package:appflowy/workspace/application/settings/appearance/base_appearance.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';

DropdownMenuEntry<T> buildDropdownMenuEntry<T>(
  BuildContext context, {
  required T value,
  required String label,
  String subLabel = '',
  T? selectedValue,
  Widget? leadingWidget,
  Widget? trailingWidget,
  String? fontFamily,
  double maximumHeight = 29,
}) {
  final fontFamilyUsed = fontFamily != null
      ? getGoogleFontSafely(fontFamily).fontFamily ?? defaultFontFamily
      : defaultFontFamily;
  Widget? labelWidget;
  if (subLabel.isNotEmpty) {
    labelWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FlowyText.regular(
          label,
          fontSize: 14,
        ),
        const VSpace(4),
        FlowyText.regular(
          subLabel,
          fontSize: 10,
        ),
      ],
    );
  } else {
    labelWidget = FlowyText.regular(
      label,
      fontSize: 14,
      textAlign: TextAlign.start,
      fontFamily: fontFamilyUsed,
    );
  }

  return DropdownMenuEntry<T>(
    style: ButtonStyle(
      foregroundColor:
          WidgetStatePropertyAll(Theme.of(context).colorScheme.primary),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      ),
      minimumSize: const WidgetStatePropertyAll(Size(double.infinity, 29)),
      maximumSize: WidgetStatePropertyAll(Size(double.infinity, maximumHeight)),
    ),
    value: value,
    label: label,
    leadingIcon: leadingWidget,
    labelWidget: labelWidget,
    trailingIcon: Row(
      children: [
        if (trailingWidget != null) ...[
          trailingWidget,
          const HSpace(8),
        ],
        value == selectedValue
            ? const FlowySvg(FlowySvgs.check_s)
            : const SizedBox.shrink(),
      ],
    ),
  );
}
