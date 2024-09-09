import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/openai/widgets/loading.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/shared_widget.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart' show PlatformExtension;
import 'package:appflowy_result/appflowy_result.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

const _confirmText = 'DELETE MY ACCOUNT';
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
    final textColor = Theme.of(context).brightness == Brightness.light
        ? const Color(0xFF4F4F4F)
        : const Color(0xFFB0B0B0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FlowyText(
          LocaleKeys.button_deleteAccount.tr(),
          fontSize: 14.0,
          fontWeight: FontWeight.w500,
          figmaLineHeight: 21.0,
          color: textColor,
        ),
        const VSpace(8),
        Row(
          children: [
            Flexible(
              child: FlowyText.regular(
                LocaleKeys.newSettings_myAccount_deleteAccount_description.tr(),
                fontSize: 12.0,
                figmaLineHeight: 13.0,
                maxLines: 2,
                color: textColor,
              ),
            ),
            const HSpace(32),
            FlowyTextButton(
              LocaleKeys.button_deleteAccount.tr(),
              constraints: const BoxConstraints(minHeight: 32),
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
              fillColor: Colors.transparent,
              radius: Corners.s8Border,
              hoverColor: Theme.of(context).colorScheme.error.withOpacity(0.1),
              fontColor: Theme.of(context).colorScheme.error,
              fontHoverColor: Colors.white,
              fontSize: 12,
              isDangerous: true,
              lineHeight: 18.0 / 12.0,
              onPressed: () {
                isCheckedNotifier.value = false;
                textEditingController.clear();

                showCancelAndDeleteDialog(
                  context: context,
                  title:
                      LocaleKeys.newSettings_myAccount_deleteAccount_title.tr(),
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
                      Navigator.of(context).popUntil((route) {
                        if (route.settings.name == '/') {
                          return true;
                        }
                        return false;
                      });
                    },
                  ),
                );
              },
            ),
          ],
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
          hintText: _confirmText,
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
  return _acceptableConfirmTexts.contains(text);
}

Future<void> deleteMyAccount(
  BuildContext context,
  String confirmText,
  bool isChecked, {
  VoidCallback? onSuccess,
  VoidCallback? onFailure,
}) async {
  final bottomPadding = PlatformExtension.isMobile
      ? MediaQuery.of(context).viewInsets.bottom
      : 0.0;

  if (!isChecked) {
    showToastNotification(
      context,
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
      context,
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
        context,
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
        context,
        type: ToastificationType.error,
        bottomPadding: bottomPadding,
        message: f.msg,
      );

      onFailure?.call();
    },
  );
}
