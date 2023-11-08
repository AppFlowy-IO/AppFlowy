import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class IncludeTimeSwitch extends StatelessWidget {
  const IncludeTimeSwitch({
    required this.switchValue,
    required this.onChanged,
    super.key,
  });
  final bool switchValue;
  final void Function(bool)? onChanged;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          LocaleKeys.grid_field_includeTime.tr(),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const Spacer(),
        Switch.adaptive(
          value: switchValue,
          activeColor: Theme.of(context).colorScheme.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
