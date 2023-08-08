import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class ThemeSettingEntryTemplateWidget extends StatelessWidget {
  const ThemeSettingEntryTemplateWidget({
    super.key,
    this.resetButtonKey,
    required this.label,
    this.trailing,
    this.onResetRequested,
  });

  final String label;
  final Key? resetButtonKey;
  final List<Widget>? trailing;
  final void Function()? onResetRequested;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FlowyText.medium(
            label,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailing != null) ...trailing!,
        if (onResetRequested != null)
          FlowyIconButton(
            key: resetButtonKey,
            width: 24,
            icon: FlowySvg(
              name: 'common/recover',
              color: Theme.of(context).colorScheme.onBackground,
            ),
            tooltipText: LocaleKeys.settings_appearance_resetSetting.tr(),
            onPressed: onResetRequested,
          ),
      ],
    );
  }
}

class ThemeValueDropDown extends StatefulWidget {
  const ThemeValueDropDown({
    super.key,
    required this.currentValue,
    required this.popupBuilder,
    this.popoverKey,
    this.onClose,
  });

  final String currentValue;
  final Key? popoverKey;
  final Widget Function(BuildContext) popupBuilder;
  final void Function()? onClose;

  @override
  State<ThemeValueDropDown> createState() => _ThemeValueDropDownState();
}

class _ThemeValueDropDownState extends State<ThemeValueDropDown> {
  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      key: widget.popoverKey,
      direction: PopoverDirection.bottomWithRightAligned,
      popupBuilder: widget.popupBuilder,
      constraints: const BoxConstraints(
        minWidth: 80,
        maxWidth: 160,
        maxHeight: 400,
      ),
      onClose: widget.onClose,
      child: FlowyTextButton(
        widget.currentValue,
        fontColor: Theme.of(context).colorScheme.onBackground,
        fillColor: Colors.transparent,
      ),
    );
  }
}
