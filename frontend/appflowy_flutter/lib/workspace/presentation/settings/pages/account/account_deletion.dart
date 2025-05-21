import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/loading.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy/util/navigator_context_extension.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/shared_widget.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:universal_platform/universal_platform.dart';

const _acceptableConfirmTexts = [
  'delete my account',
  'deletemyaccount',
  'DELETE MY ACCOUNT',
  'DELETEMYACCOUNT',
];

class AccountDeletionButton extends StatefulWidget {
  const AccountDeletionButton({
    super.key,
  });

  @override
  State<AccountDeletionButton> createState() => _AccountDeletionButtonState();
}

class _AccountDeletionButtonState extends State<AccountDeletionButton> {
  final textEditingController = TextEditingController();
  final isCheckedNotifier = ValueNotifier(false);

  @override
  void dispose() {
    textEditingController.dispose();
    isCheckedNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                LocaleKeys.button_deleteAccount.tr(),
                style: theme.textStyle.heading4.enhanced(
                  color: theme.textColorScheme.primary,
                ),
              ),
              const VSpace(4),
              Text(
                LocaleKeys.newSettings_myAccount_deleteAccount_description.tr(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textStyle.caption.standard(
                  color: theme.textColorScheme.secondary,
                ),
              ),
            ],
          ),
        ),
        AFOutlinedTextButton.destructive(
          text: LocaleKeys.button_deleteAccount.tr(),
          textStyle: theme.textStyle.body.standard(
            color: theme.textColorScheme.error,
            weight: FontWeight.w400,
          ),
          onTap: () {
            isCheckedNotifier.value = false;
            textEditingController.clear();

            showCancelAndDeleteDialog(
              context: context,
              title: LocaleKeys.newSettings_myAccount_deleteAccount_title.tr(),
              description: '',
              builder: (_) => _AccountDeletionDialog(
                controller: textEditingController,
                isChecked: isCheckedNotifier,
              ),
              onDelete: () => deleteMyAccount(
                context,
                textEditingController.text.trim(),
                isCheckedNotifier.value,
                onSuccess: () {
                  context.popToHome();
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AccountDeletionDialog extends StatelessWidget {
  const _AccountDeletionDialog({
    required this.controller,
    required this.isChecked,
  });

  final TextEditingController controller;
  final ValueNotifier<bool> isChecked;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FlowyText.regular(
          LocaleKeys.newSettings_myAccount_deleteAccount_confirmHint1.tr(),
          fontSize: 14.0,
          figmaLineHeight: 18.0,
          maxLines: 2,
          color: ConfirmPopupColor.descriptionColor(context),
        ),
        const VSpace(12.0),
        FlowyTextField(
          hintText:
              LocaleKeys.newSettings_myAccount_deleteAccount_confirmHint3.tr(),
          controller: controller,
        ),
        const VSpace(16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => isChecked.value = !isChecked.value,
              child: ValueListenableBuilder<bool>(
                valueListenable: isChecked,
                builder: (context, isChecked, _) {
                  return FlowySvg(
                    isChecked ? FlowySvgs.check_filled_s : FlowySvgs.uncheck_s,
                    size: const Size.square(16.0),
                    blendMode: isChecked ? null : BlendMode.srcIn,
                  );
                },
              ),
            ),
            const HSpace(6.0),
            Expanded(
              child: FlowyText.regular(
                LocaleKeys.newSettings_myAccount_deleteAccount_confirmHint2
                    .tr(),
                fontSize: 14.0,
                figmaLineHeight: 16.0,
                maxLines: 3,
                color: ConfirmPopupColor.descriptionColor(context),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

bool _isConfirmTextValid(String text) {
  // don't convert the text to lower case or upper case,
  //  just check if the text is in the list
  return _acceptableConfirmTexts.contains(text) ||
      text == LocaleKeys.newSettings_myAccount_deleteAccount_confirmHint3.tr();
}

Future<void> deleteMyAccount(
  BuildContext context,
  String confirmText,
  bool isChecked, {
  VoidCallback? onSuccess,
  VoidCallback? onFailure,
}) async {
  final bottomPadding = UniversalPlatform.isMobile
      ? MediaQuery.of(context).viewInsets.bottom
      : 0.0;

  if (!isChecked) {
    showToastNotification(
      type: ToastificationType.warning,
      bottomPadding: bottomPadding,
      message: LocaleKeys
          .newSettings_myAccount_deleteAccount_checkToConfirmError
          .tr(),
    );
    return;
  }
  if (!context.mounted) {
    return;
  }

  if (confirmText.isEmpty || !_isConfirmTextValid(confirmText)) {
    showToastNotification(
      type: ToastificationType.warning,
      bottomPadding: bottomPadding,
      message: LocaleKeys
          .newSettings_myAccount_deleteAccount_confirmTextValidationFailed
          .tr(),
    );
    return;
  }

  final loading = Loading(context)..start();

  await UserBackendService.deleteCurrentAccount().fold(
    (s) {
      Log.info('account deletion success');

      loading.stop();
      showToastNotification(
        message: LocaleKeys
            .newSettings_myAccount_deleteAccount_deleteAccountSuccess
            .tr(),
      );

      // delay 1 second to make sure the toast notification is shown
      Future.delayed(const Duration(seconds: 1), () async {
        onSuccess?.call();

        // restart the application
        await runAppFlowy();
      });
    },
    (f) {
      Log.error('account deletion failed, error: $f');

      loading.stop();
      showToastNotification(
        type: ToastificationType.error,
        bottomPadding: bottomPadding,
        message: f.msg,
      );

      onFailure?.call();
    },
  );
}
