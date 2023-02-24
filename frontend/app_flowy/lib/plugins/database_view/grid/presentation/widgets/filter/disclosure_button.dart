import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:app_flowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flutter/material.dart';

class DisclosureButton extends StatefulWidget {
  final PopoverMutex popoverMutex;
  final Function(FilterDisclosureAction) onAction;
  const DisclosureButton({
    required this.popoverMutex,
    required this.onAction,
    Key? key,
  }) : super(key: key);

  @override
  State<DisclosureButton> createState() => _DisclosureButtonState();
}

class _DisclosureButtonState extends State<DisclosureButton> {
  @override
  Widget build(BuildContext context) {
    return PopoverActionList<FilterDisclosureActionWrapper>(
      asBarrier: true,
      mutex: widget.popoverMutex,
      direction: PopoverDirection.rightWithTopAligned,
      actions: FilterDisclosureAction.values
          .map((action) => FilterDisclosureActionWrapper(action))
          .toList(),
      buildChild: (controller) {
        return FlowyIconButton(
          width: 20,
          icon: svgWidget(
            "editor/details",
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => controller.show(),
        );
      },
      onSelected: (action, controller) async {
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
  Widget? leftIcon(Color iconColor) => null;

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
