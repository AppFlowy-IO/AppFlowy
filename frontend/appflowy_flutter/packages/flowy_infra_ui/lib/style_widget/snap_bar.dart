import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';

void showSnapBar(BuildContext context, String title, {VoidCallback? onClosed}) {
  ScaffoldMessenger.of(context).clearSnackBars();

  ScaffoldMessenger.of(context)
      .showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 8000),
          content: WillPopScope(
            onWillPop: () async {
              ScaffoldMessenger.of(context).removeCurrentSnackBar();
              return true;
            },
            child: FlowyText.medium(
              title,
              fontSize: 12,
              maxLines: 3,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.background,
        ),
      )
      .closed
      .then((value) => onClosed?.call());
}
