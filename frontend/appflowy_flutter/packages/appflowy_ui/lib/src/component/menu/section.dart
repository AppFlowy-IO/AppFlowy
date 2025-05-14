import 'package:flutter/material.dart';

/// A section in the menu, optionally with a title and a list of children.
class AFMenuSection extends StatelessWidget {
  /// The title of the section (e.g., 'Section 1').
  final String? title;

  /// The widgets to display in this section (typically AFMenuItem widgets).
  final List<Widget> children;

  const AFMenuSection({
    Key? key,
    this.title,
    required this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 4),
            child: Text(
              title!,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
            ),
          ),
        ],
        ...children,
      ],
    );
  }
}
