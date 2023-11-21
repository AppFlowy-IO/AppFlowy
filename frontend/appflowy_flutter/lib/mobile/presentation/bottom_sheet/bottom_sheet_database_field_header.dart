import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MobileDBFieldBottomSheetHeader extends StatelessWidget {
  const MobileDBFieldBottomSheetHeader({
    super.key,
    required this.showBackButton,
    required this.onBack,
  });

  final bool showBackButton;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        // back button
        if (showBackButton)
          InkWell(
            onTap: onBack,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 24.0,
              ),
            ),
          ),
        // field name
        Expanded(
          child: Text(
            "Edit Field",
            style: theme.textTheme.labelSmall,
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.close,
            color: theme.hintColor,
          ),
          onPressed: () {
            context.pop();
          },
        ),
      ],
    );
  }
}
