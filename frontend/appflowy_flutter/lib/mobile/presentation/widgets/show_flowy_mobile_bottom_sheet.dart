import 'package:flowy_infra/size.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

Future<T?> showFlowyMobileBottomSheet<T>(
  BuildContext context, {
  required String title,
  required Widget Function(BuildContext) builder,
  bool isScrollControlled = false,
}) async {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: isScrollControlled,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Corners.s12Radius,
      ),
    ),
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BottomSheetTitle(title),
          const SizedBox(
            height: 16,
          ),
          builder(context),
        ],
      ),
    ),
  );
}

class _BottomSheetTitle extends StatelessWidget {
  const _BottomSheetTitle(this.title);

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
        ),
      ],
    );
  }
}
