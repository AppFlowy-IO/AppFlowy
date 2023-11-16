import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class FlowyMessageToast extends StatelessWidget {
  final String message;
  const FlowyMessageToast({required this.message, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: FlowyText.medium(
          message,
          fontSize: FontSizes.s16,
          maxLines: 3,
        ),
      ),
    );
  }
}

void initToastWithContext(BuildContext context) {
  getIt<FToast>().init(context);
}

void showMessageToast(
  String message, {
  BuildContext? context,
  ToastGravity gravity = ToastGravity.BOTTOM,
}) {
  final child = FlowyMessageToast(message: message);
  final toast = context == null ? getIt<FToast>() : FToast()
    ..init(context!);
  toast.showToast(
    child: child,
    gravity: gravity,
    toastDuration: const Duration(seconds: 3),
  );
}

void showSnackBarMessage(
  BuildContext context,
  String message, {
  bool showCancel = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Theme.of(context).colorScheme.onSecondary,
      action: !showCancel
          ? null
          : SnackBarAction(
              label: LocaleKeys.button_cancel.tr(),
              textColor: Theme.of(context).colorScheme.onSurface,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
      content: FlowyText(
        message,
      ),
    ),
  );
}
