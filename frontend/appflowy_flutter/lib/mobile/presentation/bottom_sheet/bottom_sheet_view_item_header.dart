import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MobileViewItemBottomSheetHeader extends StatelessWidget {
  const MobileViewItemBottomSheetHeader({
    super.key,
    required this.view,
    required this.showBackButton,
    required this.onBack,
  });

  final ViewPB view;
  final bool showBackButton;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        // back button,
        showBackButton
            ? InkWell(
                onTap: onBack,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 24.0,
                  ),
                ),
              )
            : const SizedBox.shrink(),
        // title
        Expanded(
          child: Text(
            view.name,
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
