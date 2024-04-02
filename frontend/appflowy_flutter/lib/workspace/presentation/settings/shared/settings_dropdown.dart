import 'package:flutter/material.dart';

import 'package:flowy_infra_ui/flowy_infra_ui.dart';

class SettingsDropdown extends StatefulWidget {
  const SettingsDropdown({
    super.key,
    required this.selectedOption,
    required this.options,
    this.onChanged,
    this.actions,
  });

  final String selectedOption;
  final List<DropdownMenuEntry<String>> options;
  final void Function(String)? onChanged;
  final List<Widget>? actions;

  @override
  State<SettingsDropdown> createState() => _SettingsDropdownState();
}

class _SettingsDropdownState extends State<SettingsDropdown> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.selectedOption);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DropdownMenu<String>(
          controller: controller,
          menuStyle:
              MenuStyle(visualDensity: VisualDensity.adaptivePlatformDensity),
          initialSelection: widget.selectedOption,
          dropdownMenuEntries: widget.options,
          onSelected: (value) =>
              value != null ? widget.onChanged?.call(value) : null,
        ),
        if (widget.actions?.isNotEmpty == true) ...[
          const HSpace(16),
          SeparatedRow(
            separatorBuilder: () => const HSpace(16),
            children: widget.actions!,
          ),
        ],
      ],
    );
  }
}
