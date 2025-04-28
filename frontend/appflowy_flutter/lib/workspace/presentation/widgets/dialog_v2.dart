import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

typedef SimpleAFDialogAction = (String, void Function(BuildContext)?);

/// A simple dialog with a title, content, and actions.
///
/// The primary button is a filled button and colored using theme or destructive
/// color depending on the [isDestructive] parameter. The secondary button is an
/// outlined button.
///
Future<void> showSimpleAFDialog({
  required BuildContext context,
  required String title,
  required String content,
  bool isDestructive = false,
  required SimpleAFDialogAction primaryAction,
  SimpleAFDialogAction? secondaryAction,
  bool barrierDismissible = true,
}) {
  final theme = AppFlowyTheme.of(context);

  return showDialog(
    context: context,
    barrierColor: theme.surfaceColorScheme.overlay,
    barrierDismissible: barrierDismissible,
    builder: (_) {
      return AFModal(
        constraints: BoxConstraints(
          maxWidth: AFModalDimension.S,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AFModalHeader(
              leading: Text(
                title,
                style: theme.textStyle.heading4.prominent(
                  color: theme.textColorScheme.primary,
                ),
              ),
              trailing: [
                AFGhostButton.normal(
                  onTap: () => Navigator.of(context).pop(),
                  builder: (context, isHovering, disabled) {
                    return FlowySvg(
                      FlowySvgs.close_s,
                      size: Size.square(20),
                    );
                  },
                ),
              ],
            ),
            Flexible(
              child: ConstrainedBox(
                // AFModalDimension.dialogHeight - header - footer
                constraints: BoxConstraints(minHeight: 108.0),
                child: AFModalBody(
                  child: Text(content),
                ),
              ),
            ),
            AFModalFooter(
              trailing: [
                if (secondaryAction != null)
                  AFOutlinedButton.normal(
                    onTap: () {
                      secondaryAction.$2?.call(context);
                      Navigator.of(context).pop();
                    },
                    builder: (context, isHovering, disabled) {
                      return Text(secondaryAction.$1);
                    },
                  ),
                isDestructive
                    ? AFFilledTextButton.destructive(
                        text: primaryAction.$1,
                        onTap: () {
                          primaryAction.$2?.call(context);
                          Navigator.of(context).pop();
                        },
                      )
                    : AFFilledTextButton.primary(
                        text: primaryAction.$1,
                        onTap: () {
                          primaryAction.$2?.call(context);
                          Navigator.of(context).pop();
                        },
                      ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
