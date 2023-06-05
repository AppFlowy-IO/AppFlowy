import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flutter/material.dart';

class DisclosureButton extends StatefulWidget {
  final PopoverMutex popoverMutex;
  final Function(FilterDisclosureAction) onAction;
  const DisclosureButton({
    required this.popoverMutex,
    required this.onAction,
    final Key? key,
  }) : super(key: key);

  @override
  State<DisclosureButton> createState() => _DisclosureButtonState();
}

class _DisclosureButtonState extends State<DisclosureButton> {
  @override
  Widget build(final BuildContext context) {
    return PopoverActionList<FilterDisclosureActionWrapper>(
      asBarrier: true,
      mutex: widget.popoverMutex,
      direction: PopoverDirection.rightWithTopAligned,
      actions: FilterDisclosureAction.values
          .map((final action) => FilterDisclosureActionWrapper(action))
          .toList(),
      buildChild: (final controller) {
        return FlowyIconButton(
          hoverColor: AFThemeExtension.of(context).lightGreyHover,
          width: 20,
          icon: svgWidget(
            "editor/details",
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () => controller.show(),
        );
      },
      onSelected: (final action, final controller) async {
        widget.onAction(action.inner);
        controller.close();
      },
    );
  }
}

enum FilterDisclosureAction {
  delete,
}

class FilterDisclosureActionWrapper extends ActionCell {
  final FilterDisclosureAction inner;

  FilterDisclosureActionWrapper(this.inner);

  @override
  Widget? leftIcon(final Color iconColor) => null;

  @override
  String get name => inner.name;
}

extension FilterDisclosureActionExtension on FilterDisclosureAction {
  String get name {
    switch (this) {
      case FilterDisclosureAction.delete:
        return LocaleKeys.grid_settings_deleteFilter.tr();
    }
  }
}
