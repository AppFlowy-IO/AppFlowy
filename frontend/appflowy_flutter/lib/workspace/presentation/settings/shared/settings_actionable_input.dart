import 'package:flutter/material.dart';

import 'package:flowy_infra_ui/flowy_infra_ui.dart';

class SettingsActionableInput extends StatelessWidget {
  const SettingsActionableInput({
    super.key,
    required this.controller,
    this.focusNode,
    this.placeholder,
    this.onSave,
    this.actions = const [],
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? placeholder;
  final Function(String)? onSave;

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: SizedBox(
            height: 48,
            child: FlowyTextField(
              controller: controller,
              focusNode: focusNode,
              hintText: placeholder,
              autoFocus: false,
              isDense: false,
              suffixIconConstraints:
                  BoxConstraints.tight(const Size(23 + 18, 24)),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              onSubmitted: onSave,
            ),
          ),
        ),
        if (actions.isNotEmpty) ...[
          const HSpace(8),
          SeparatedRow(
            separatorBuilder: () => const HSpace(16),
            children: actions,
          ),
        ],
      ],
    );
  }
}
