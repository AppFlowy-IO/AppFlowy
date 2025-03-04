import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

import 'operations/ai_writer_entities.dart';

class SuggestionActionBar extends StatelessWidget {
  const SuggestionActionBar({
    super.key,
    required this.actions,
    required this.onTap,
  });

  final List<SuggestionAction> actions;
  final void Function(SuggestionAction) onTap;

  @override
  Widget build(BuildContext context) {
    return SeparatedRow(
      mainAxisSize: MainAxisSize.min,
      separatorBuilder: () => const HSpace(4.0),
      children: actions
          .map(
            (action) => SuggestionActionButton(
              action: action,
              onTap: () => onTap(action),
            ),
          )
          .toList(),
    );
  }
}

class SuggestionActionButton extends StatelessWidget {
  const SuggestionActionButton({
    super.key,
    required this.action,
    required this.onTap,
  });

  final SuggestionAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: FlowyButton(
        text: FlowyText(
          action.i18n,
          figmaLineHeight: 20,
        ),
        leftIcon: action.buildIcon(context),
        iconPadding: 4.0,
        margin: const EdgeInsets.symmetric(
          horizontal: 6.0,
          vertical: 4.0,
        ),
        onTap: onTap,
        useIntrinsicWidth: true,
      ),
    );
  }
}
