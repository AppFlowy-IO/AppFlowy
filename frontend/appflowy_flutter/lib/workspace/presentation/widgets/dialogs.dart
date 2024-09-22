import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/tasks/app_widget.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/shared_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/style_widget/text_input.dart';
import 'package:flowy_infra_ui/widget/buttons/primary_button.dart';
import 'package:flowy_infra_ui/widget/buttons/secondary_button.dart';
import 'package:flowy_infra_ui/widget/dialog/styled_dialogs.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:universal_platform/universal_platform.dart';

export 'package:flowy_infra_ui/widget/dialog/styled_dialogs.dart';

class NavigatorTextFieldDialog extends StatefulWidget {
  const NavigatorTextFieldDialog({
    super.key,
    required this.title,
    this.autoSelectAllText = false,
    required this.value,
    required this.onConfirm,
    this.onCancel,
    this.maxLength,
    this.hintText,
  });

  final String value;
  final String title;
  final VoidCallback? onCancel;
  final void Function(String, BuildContext) onConfirm;
  final bool autoSelectAllText;
  final int? maxLength;
  final String? hintText;

  @override
  State<NavigatorTextFieldDialog> createState() =>
      _NavigatorTextFieldDialogState();
}

class _NavigatorTextFieldDialogState extends State<NavigatorTextFieldDialog> {
  String newValue = "";
  final controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    newValue = widget.value;
    controller.text = newValue;
    if (widget.autoSelectAllText) {
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: newValue.length,
      );
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StyledDialog(
      child: Column(
        children: <Widget>[
          FlowyText.medium(
            widget.title,
            color: Theme.of(context).colorScheme.tertiary,
            fontSize: FontSizes.s16,
          ),
          VSpace(Insets.m),
          FlowyFormTextInput(
            hintText:
                widget.hintText ?? LocaleKeys.dialogCreatePageNameHint.tr(),
            controller: controller,
            textStyle: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontSize: FontSizes.s16),
            maxLength: widget.maxLength,
            showCounter: false,
            autoFocus: true,
            onChanged: (text) {
              newValue = text;
            },
            onEditingComplete: () {
              widget.onConfirm(newValue, context);
              AppGlobals.nav.pop();
            },
          ),
          VSpace(Insets.xl),
          OkCancelButton(
            onOkPressed: () {
              if (newValue.isEmpty) {
                showToastNotification(
                  context,
                  message: LocaleKeys.space_spaceNameCannotBeEmpty.tr(),
                );
                return;
              }
              widget.onConfirm(newValue, context);
              Navigator.of(context).pop();
            },
            onCancelPressed: () {
              widget.onCancel?.call();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

class NavigatorAlertDialog extends StatefulWidget {
  const NavigatorAlertDialog({
    super.key,
    required this.title,
    this.cancel,
    this.confirm,
    this.hideCancelButton = false,
    this.constraints,
  });

  final String title;
  final void Function()? cancel;
  final void Function()? confirm;
  final bool hideCancelButton;
  final BoxConstraints? constraints;

  @override
  State<NavigatorAlertDialog> createState() => _CreateFlowyAlertDialog();
}

class _CreateFlowyAlertDialog extends State<NavigatorAlertDialog> {
  @override
  Widget build(BuildContext context) {
    return StyledDialog(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          ...[
            ConstrainedBox(
              constraints: widget.constraints ??
                  const BoxConstraints(
                    maxWidth: 400,
                    maxHeight: 260,
                  ),
              child: FlowyText.medium(
                widget.title,
                fontSize: FontSizes.s16,
                textAlign: TextAlign.center,
                color: Theme.of(context).colorScheme.tertiary,
                maxLines: null,
              ),
            ),
          ],
          if (widget.confirm != null) ...[
            const VSpace(20),
            OkCancelButton(
              onOkPressed: () {
                widget.confirm?.call();
                Navigator.of(context).pop();
              },
              onCancelPressed: widget.hideCancelButton
                  ? null
                  : () {
                      widget.cancel?.call();
                      Navigator.of(context).pop();
                    },
            ),
          ],
        ],
      ),
    );
  }
}

class NavigatorOkCancelDialog extends StatelessWidget {
  const NavigatorOkCancelDialog({
    super.key,
    this.onOkPressed,
    this.onCancelPressed,
    this.okTitle,
    this.cancelTitle,
    this.title,
    this.message,
    this.maxWidth,
    this.titleUpperCase = true,
    this.autoDismiss = true,
  });

  final VoidCallback? onOkPressed;
  final VoidCallback? onCancelPressed;
  final String? okTitle;
  final String? cancelTitle;
  final String? title;
  final String? message;
  final double? maxWidth;
  final bool titleUpperCase;
  final bool autoDismiss;

  @override
  Widget build(BuildContext context) {
    final onCancel = onCancelPressed == null
        ? null
        : () {
            onCancelPressed?.call();
            if (autoDismiss) {
              Navigator.of(context).pop();
            }
          };
    return StyledDialog(
      maxWidth: maxWidth ?? 500,
      padding: EdgeInsets.symmetric(horizontal: Insets.xl, vertical: Insets.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (title != null) ...[
            FlowyText.medium(
              titleUpperCase ? title!.toUpperCase() : title!,
              fontSize: FontSizes.s16,
              maxLines: 3,
            ),
            VSpace(Insets.sm * 1.5),
            Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              height: 1,
            ),
            VSpace(Insets.m * 1.5),
          ],
          if (message != null)
            FlowyText.medium(
              message!,
              maxLines: 3,
            ),
          SizedBox(height: Insets.l),
          OkCancelButton(
            onOkPressed: () {
              onOkPressed?.call();
              if (autoDismiss) {
                Navigator.of(context).pop();
              }
            },
            onCancelPressed: onCancel,
            okTitle: okTitle?.toUpperCase(),
            cancelTitle: cancelTitle?.toUpperCase(),
          ),
        ],
      ),
    );
  }
}

class OkCancelButton extends StatelessWidget {
  const OkCancelButton({
    super.key,
    this.onOkPressed,
    this.onCancelPressed,
    this.okTitle,
    this.cancelTitle,
    this.minHeight,
    this.alignment = MainAxisAlignment.spaceAround,
    this.mode = TextButtonMode.big,
  });

  final VoidCallback? onOkPressed;
  final VoidCallback? onCancelPressed;
  final String? okTitle;
  final String? cancelTitle;
  final double? minHeight;
  final MainAxisAlignment alignment;
  final TextButtonMode mode;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: alignment,
        children: <Widget>[
          if (onCancelPressed != null)
            SecondaryTextButton(
              cancelTitle ?? LocaleKeys.button_cancel.tr(),
              onPressed: onCancelPressed,
              mode: mode,
            ),
          if (onCancelPressed != null) HSpace(Insets.m),
          if (onOkPressed != null)
            PrimaryTextButton(
              okTitle ?? LocaleKeys.button_ok.tr(),
              onPressed: onOkPressed,
              mode: mode,
            ),
        ],
      ),
    );
  }
}

void showToastNotification(
  BuildContext context, {
  required String message,
  String? description,
  ToastificationType type = ToastificationType.success,
  ToastificationCallbacks? callbacks,
  double bottomPadding = 100,
}) {
  if (UniversalPlatform.isMobile) {
    toastification.showCustom(
      alignment: Alignment.bottomCenter,
      autoCloseDuration: const Duration(milliseconds: 3000),
      callbacks: callbacks ?? const ToastificationCallbacks(),
      builder: (_, __) => _MToast(
        message: message,
        type: type,
        bottomPadding: bottomPadding,
      ),
    );
    return;
  }

  toastification.show(
    context: context,
    type: type,
    style: ToastificationStyle.flat,
    title: FlowyText(
      message,
      maxLines: 3,
    ),
    description: description != null
        ? FlowyText.regular(
            description,
            fontSize: 12,
            lineHeight: 1.2,
            maxLines: 3,
          )
        : null,
    alignment: Alignment.bottomCenter,
    autoCloseDuration: const Duration(milliseconds: 3000),
    showProgressBar: false,
    backgroundColor: Theme.of(context).colorScheme.surface,
    borderSide: BorderSide(
      color: Colors.grey.withOpacity(0.4),
    ),
  );
}

class _MToast extends StatelessWidget {
  const _MToast({
    required this.message,
    this.type = ToastificationType.success,
    this.bottomPadding = 100,
  });

  final String message;
  final ToastificationType type;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final hintText = FlowyText.regular(
      message,
      fontSize: 16.0,
      figmaLineHeight: 18.0,
      color: Colors.white,
      maxLines: 10,
    );
    return Container(
      alignment: Alignment.bottomCenter,
      padding: EdgeInsets.only(bottom: bottomPadding, left: 16, right: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 13.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          color: const Color(0xE5171717),
        ),
        child: type == ToastificationType.success
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (type == ToastificationType.success) ...[
                    const FlowySvg(
                      FlowySvgs.success_s,
                      blendMode: null,
                    ),
                    const HSpace(8.0),
                  ],
                  Expanded(child: hintText),
                ],
              )
            : hintText,
      ),
    );
  }
}

Future<void> showConfirmDeletionDialog({
  required BuildContext context,
  required String name,
  required String description,
  required VoidCallback onConfirm,
}) {
  return showDialog(
    context: context,
    builder: (_) {
      final title = LocaleKeys.space_deleteConfirmation.tr() + name;
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: SizedBox(
          width: 440,
          child: ConfirmPopup(
            title: title,
            description: description,
            onConfirm: onConfirm,
          ),
        ),
      );
    },
  );
}

Future<void> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String description,
  VoidCallback? onConfirm,
  VoidCallback? onCancel,
  String? confirmLabel,
  ConfirmPopupStyle style = ConfirmPopupStyle.onlyOk,
}) {
  return showDialog(
    context: context,
    builder: (_) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: SizedBox(
          width: 440,
          child: ConfirmPopup(
            title: title,
            description: description,
            onConfirm: () => onConfirm?.call(),
            onCancel: () => onCancel?.call(),
            confirmLabel: confirmLabel,
            style: style,
          ),
        ),
      );
    },
  );
}

Future<void> showCancelAndConfirmDialog({
  required BuildContext context,
  required String title,
  required String description,
  VoidCallback? onConfirm,
  VoidCallback? onCancel,
  String? confirmLabel,
}) {
  return showDialog(
    context: context,
    builder: (_) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: SizedBox(
          width: 440,
          child: ConfirmPopup(
            title: title,
            description: description,
            onConfirm: () => onConfirm?.call(),
            confirmLabel: confirmLabel,
            confirmButtonColor: Theme.of(context).colorScheme.primary,
            onCancel: () => onCancel?.call(),
          ),
        ),
      );
    },
  );
}

Future<void> showCustomConfirmDialog({
  required BuildContext context,
  required String title,
  required String description,
  required Widget Function(BuildContext) builder,
  VoidCallback? onConfirm,
  String? confirmLabel,
  ConfirmPopupStyle style = ConfirmPopupStyle.onlyOk,
  bool closeOnConfirm = true,
}) {
  return showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: SizedBox(
          width: 440,
          child: ConfirmPopup(
            title: title,
            description: description,
            onConfirm: () => onConfirm?.call(),
            confirmLabel: confirmLabel,
            style: style,
            closeOnAction: closeOnConfirm,
            child: builder(context),
          ),
        ),
      );
    },
  );
}

Future<void> showCancelAndDeleteDialog({
  required BuildContext context,
  required String title,
  required String description,
  Widget Function(BuildContext)? builder,
  VoidCallback? onDelete,
  String? confirmLabel,
  bool closeOnAction = false,
}) {
  return showDialog(
    context: context,
    builder: (_) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: SizedBox(
          width: 440,
          child: ConfirmPopup(
            title: title,
            description: description,
            onConfirm: () => onDelete?.call(),
            closeOnAction: closeOnAction,
            confirmLabel: confirmLabel,
            confirmButtonColor: Theme.of(context).colorScheme.error,
            child: builder?.call(context),
          ),
        ),
      );
    },
  );
}
