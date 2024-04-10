import 'package:flutter/material.dart';

import 'package:appflowy/flutter/af_dropdown_menu.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';

class SettingsDropdown<T> extends StatefulWidget {
  const SettingsDropdown({
    super.key,
    required this.selectedOption,
    required this.options,
    this.onChanged,
    this.actions,
    this.expandWidth = true,
  });

  final T selectedOption;
  final List<DropdownMenuEntry<T>> options;
  final void Function(T)? onChanged;
  final List<Widget>? actions;
  final bool expandWidth;

  @override
  State<SettingsDropdown<T>> createState() => _SettingsDropdownState<T>();
}

class _SettingsDropdownState<T> extends State<SettingsDropdown<T>> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(
      text: widget.options
          .firstWhere((e) => e.value == widget.selectedOption)
          .label,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: AFDropdownMenu<T>(
            controller: controller,
            expandedInsets: widget.expandWidth ? EdgeInsets.zero : null,
            initialSelection: widget.selectedOption,
            dropdownMenuEntries: widget.options,
            menuStyle: MenuStyle(
              maximumSize:
                  const MaterialStatePropertyAll(Size(double.infinity, 250)),
              elevation: const MaterialStatePropertyAll(10),
              shadowColor:
                  MaterialStatePropertyAll(Colors.black.withOpacity(0.4)),
              backgroundColor: MaterialStatePropertyAll(
                Theme.of(context).colorScheme.surface,
              ),
              padding: const MaterialStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              ),
              alignment: Alignment.bottomLeft,
              visualDensity: VisualDensity.compact,
            ),
            inputDecorationTheme: InputDecorationTheme(
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 18,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                ),
                borderRadius: Corners.s8Border,
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                ),
                borderRadius: Corners.s8Border,
              ),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.error,
                ),
                borderRadius: Corners.s8Border,
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.error,
                ),
                borderRadius: Corners.s8Border,
              ),
            ),
            onSelected: (v) async {
              debugPrint("REACHED HERE ($v)");
              v != null ? widget.onChanged?.call(v) : null;
            },
          ),
        ),
        if (widget.actions?.isNotEmpty == true) ...[
          const HSpace(16),
          SeparatedRow(
            separatorBuilder: () => const HSpace(8),
            children: widget.actions!,
          ),
        ],
      ],
    );
  }
}
