import 'dart:io';

import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';

void showSnapBar(BuildContext context, String title, {VoidCallback? onClosed}) {
  ScaffoldMessenger.of(context).clearSnackBars();

  ScaffoldMessenger.of(context)
      .showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          duration: const Duration(milliseconds: 8000),
          content: FlowyText(
            title,
            maxLines: 2,
            fontSize:
                (Platform.isLinux || Platform.isWindows || Platform.isMacOS)
                    ? 14
                    : 12,
          ),
        ),
      )
      .closed
      .then((value) => onClosed?.call());
}
