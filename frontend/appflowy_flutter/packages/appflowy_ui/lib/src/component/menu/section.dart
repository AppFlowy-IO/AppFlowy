import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

/// A section in the menu, optionally with a title and a list of children.
class AFMenuSection extends StatelessWidget {
  const AFMenuSection({
    super.key,
    this.title,
    this.titleTrailing,
    required this.children,
    this.padding,
    this.constraints,
  });

  /// The title of the section (e.g., 'Section 1').
  final String? title;

  /// Widget to display after the title, only works when [title] is not null.
  final Widget? titleTrailing;

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
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title!,
                    style: theme.textStyle.caption.enhanced(
                      color: theme.textColorScheme.tertiary,
                    ),
                  ),
                ),
                // Title Trailing widget (e.g., icon), if provided
                if (titleTrailing != null) titleTrailing!,
              ],
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
