import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

/// A section in the menu, optionally with a title and a list of children.
class AFMenuSection extends StatelessWidget {
  const AFMenuSection({
    super.key,
    this.title,
    required this.children,
    this.padding,
    this.constraints,
  });

  /// The title of the section (e.g., 'Section 1').
  final String? title;

  /// The widgets to display in this section (typically AFMenuItem widgets).
  final List<Widget> children;

  /// Section padding.
  final EdgeInsets? padding;

  /// The height of the section.
  final BoxConstraints? constraints;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    final effectivePadding = padding ??
        EdgeInsets.symmetric(
          horizontal: theme.spacing.m,
          vertical: theme.spacing.s,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: effectivePadding,
            child: Text(
              title!,
              style: theme.textStyle.caption.enhanced(
                color: theme.textColorScheme.tertiary,
              ),
            ),
          ),
        ],
        Container(
          constraints: constraints,
          child: SingleChildScrollView(
            child: Column(
              children: children,
            ),
          ),
        ),
      ],
    );
  }
}
