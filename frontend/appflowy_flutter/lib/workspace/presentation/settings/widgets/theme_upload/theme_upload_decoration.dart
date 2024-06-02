import 'package:dotted_border/dotted_border.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flutter/material.dart';

import 'theme_upload_view.dart';

class ThemeUploadDecoration extends StatelessWidget {
  const ThemeUploadDecoration({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ThemeUploadWidget.borderRadius),
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: AFThemeExtension.of(context).onBackground.withOpacity(
                ThemeUploadWidget.fadeOpacity,
              ),
        ),
      ),
      padding: ThemeUploadWidget.padding,
      child: DottedBorder(
        borderType: BorderType.RRect,
        dashPattern: const [6, 6],
        color: Theme.of(context)
            .colorScheme
            .onSurface
            .withOpacity(ThemeUploadWidget.fadeOpacity),
        radius: const Radius.circular(ThemeUploadWidget.borderRadius),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(ThemeUploadWidget.borderRadius),
          child: child,
        ),
      ),
    );
  }
}
