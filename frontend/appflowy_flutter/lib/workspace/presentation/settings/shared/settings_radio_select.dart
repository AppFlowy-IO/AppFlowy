import 'package:flutter/material.dart';

import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';

class SettingsRadioItem<T> {
  const SettingsRadioItem({
    required this.value,
    required this.label,
    required this.isSelected,
    this.icon,
  });

  final T value;
  final String label;
  final bool isSelected;
  final Widget? icon;
}

class SettingsRadioSelect<T> extends StatelessWidget {
  const SettingsRadioSelect({
    super.key,
    required this.items,
    required this.onChanged,
    this.selectedItem,
  });

  final List<SettingsRadioItem<T>> items;
  final void Function(SettingsRadioItem<T>) onChanged;
  final SettingsRadioItem<T>? selectedItem;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 24,
      runSpacing: 8,
      children: items
          .map(
            (i) => GestureDetector(
              onTap: () => onChanged(i),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AFThemeExtension.of(context).textColor,
                      ),
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: i.isSelected
                            ? AFThemeExtension.of(context).textColor
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const HSpace(8),
                  if (i.icon != null) ...[i.icon!, const HSpace(4)],
                  FlowyText.regular(i.label, fontSize: 14),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
