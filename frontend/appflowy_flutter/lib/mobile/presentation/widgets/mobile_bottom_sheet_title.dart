import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// TODO(yijing): needs reorganize with bottom sheet widget
class MobileBottomSheetTitle extends StatelessWidget {
  const MobileBottomSheetTitle(
    this.title, {
    super.key,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.labelSmall,
        ),
        IconButton(
          icon: Icon(
            Icons.close,
            color: theme.hintColor,
          ),
          onPressed: () {
            context.pop();
          },
        )
      ],
    );
  }
}
