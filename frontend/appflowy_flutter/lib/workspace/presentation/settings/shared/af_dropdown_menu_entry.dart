import 'package:appflowy/shared/google_fonts_extension.dart';
import 'package:appflowy/workspace/application/settings/appearance/base_appearance.dart';
import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';

DropdownMenuEntry<T> buildDropdownMenuEntry<T>(
  BuildContext context, {
  required T value,
  required String label,
  T? selectedValue,
  Widget? leadingWidget,
  Widget? trailingWidget,
  String? fontFamily,
}) {
  final fontFamilyUsed = fontFamily != null
      ? getGoogleFontSafely(fontFamily).fontFamily ?? defaultFontFamily
      : defaultFontFamily;

  return DropdownMenuEntry<T>(
    style: ButtonStyle(
      foregroundColor:
          WidgetStatePropertyAll(Theme.of(context).colorScheme.primary),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      ),
      minimumSize: const WidgetStatePropertyAll(Size(double.infinity, 29)),
      maximumSize: const WidgetStatePropertyAll(Size(double.infinity, 29)),
    ),
    value: value,
    label: label,
    leadingIcon: leadingWidget,
    labelWidget: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: FlowyText.medium(
        label,
        fontSize: 14,
        textAlign: TextAlign.start,
        fontFamily: fontFamilyUsed,
      ),
    ),
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
