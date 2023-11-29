import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/database/card/card_property_edit/widgets/property_title.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class IncludeTimeSwitch extends StatelessWidget {
  const IncludeTimeSwitch({
    super.key,
    required this.switchValue,
    required this.onChanged,
  });

  final bool switchValue;
  final void Function(bool)? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PropertyTitle(
          LocaleKeys.grid_field_includeTime.tr(),
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
