import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:string_validator/string_validator.dart';

class ShareWithUserWidget extends StatefulWidget {
  const ShareWithUserWidget({
    super.key,
    required this.onInvite,
  });

  final void Function(List<String> emails) onInvite;

  @override
  State<ShareWithUserWidget> createState() => _ShareWithUserWidgetState();
}

class _ShareWithUserWidgetState extends State<ShareWithUserWidget> {
  final TextEditingController controller = TextEditingController();
  bool isButtonEnabled = false;

  @override
  void initState() {
    super.initState();

    controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return Row(
      children: [
        Expanded(
          child: AFTextField(
            controller: controller,
            size: AFTextFieldSize.m,
            hintText: LocaleKeys.shareTab_inviteByEmail.tr(),
          ),
        ),
        HSpace(theme.spacing.s),
        AFFilledTextButton.primary(
          text: LocaleKeys.shareTab_invite.tr(),
          disabled: !isButtonEnabled,
          onTap: () {
            widget.onInvite(controller.text.trim().split(','));
          },
        ),
      ],
    );
  }

  void _onTextChanged() {
    setState(() {
      final texts = controller.text.trim().split(',');
      isButtonEnabled = texts.isNotEmpty && texts.every(isEmail);
    });
  }
}
