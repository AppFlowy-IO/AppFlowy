import 'package:flutter/material.dart';

import 'package:flowy_infra_ui/flowy_infra_ui.dart';

/// Renders a simple category taking a title and the list
/// of children (settings) to be rendered.
///
class SettingsCategory extends StatelessWidget {
  const SettingsCategory({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FlowyText.semibold(
          title,
          maxLines: 2,
          fontSize: 16,
          overflow: TextOverflow.ellipsis,
        ),
        const VSpace(8),
        SeparatedColumn(
          mainAxisSize: MainAxisSize.min,
          separatorBuilder: () =>
              children.length > 1 ? const VSpace(16) : const SizedBox.shrink(),
          children: children,
        ),
      ],
    );
  }
}
