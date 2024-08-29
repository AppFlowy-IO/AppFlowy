import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/shared_widget.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_editor/appflowy_editor.dart' show PlatformExtension;
import 'package:appflowy_result/appflowy_result.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class AccountDeletionButton extends StatefulWidget {
  const AccountDeletionButton({super.key});

  @override
  State<AccountDeletionButton> createState() => _AccountDeletionButtonState();
}

class _AccountDeletionButtonState extends State<AccountDeletionButton> {
  final TextEditingController emailController = TextEditingController();
  final isCheckedNotifier = ValueNotifier(false);

  @override
  void dispose() {
    emailController.dispose();
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
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
              fillColor: Colors.transparent,
              radius: Corners.s12Border,
              hoverColor: Theme.of(context).colorScheme.error.withOpacity(0.1),
              fontColor: Theme.of(context).colorScheme.error,
              fontHoverColor: Colors.white,
              fontSize: 12,
              isDangerous: true,
              lineHeight: 18.0 / 12.0,
              onPressed: () {
                isCheckedNotifier.value = false;

                showCancelAndDeleteDialog(
                  context: context,
                  title:
                      LocaleKeys.newSettings_myAccount_deleteAccount_title.tr(),
                  description: '',
                  builder: (_) => _AccountDeletionDialog(
                    emailController: emailController,
                    isChecked: isCheckedNotifier,
                  ),
                  onDelete: () => deleteMyAccount(
                    context,
                    emailController.text.trim(),
                    isCheckedNotifier.value,
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
    required this.emailController,
    required this.isChecked,
  });

  final TextEditingController emailController;
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
          hintText: LocaleKeys.settings_user_email.tr(),
          controller: emailController,
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

Future<void> deleteMyAccount(
  BuildContext context,
  String email,
  bool isChecked,
) async {
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

  // fetch the user email from server instead of reading from provider,
  // this is to avoid the email doesn't match the real user's email
  final userEmail = await UserBackendService.getCurrentUserProfile()
      .fold((s) => s.email, (_) => null);

  if (!context.mounted) {
    return;
  }

  if (userEmail == null) {
    showToastNotification(
      context,
      type: ToastificationType.error,
      bottomPadding: bottomPadding,
      message: LocaleKeys
          .newSettings_myAccount_deleteAccount_failedToGetCurrentUser
          .tr(),
    );
    return;
  }

  if (email.isEmpty || email.toLowerCase() != userEmail.toLowerCase()) {
    showToastNotification(
      context,
      type: ToastificationType.warning,
      bottomPadding: bottomPadding,
      message: LocaleKeys
          .newSettings_myAccount_deleteAccount_emailValidationFailed
          .tr(),
    );
    return;
  }

  // Todo(Lucas): delete account
  showToastNotification(
    context,
    message: LocaleKeys.newSettings_myAccount_deleteAccount_deleteAccountSuccess
        .tr(),
    bottomPadding: bottomPadding,
  );
}
