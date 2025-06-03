import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:string_validator/string_validator.dart';

class ShareWithUserWidget extends StatefulWidget {
  const ShareWithUserWidget({
    super.key,
    required this.onInvite,
    this.controller,
    this.disabled = false,
    this.tooltip,
  });

  final TextEditingController? controller;
  final void Function(List<String> emails) onInvite;
  final bool disabled;
  final String? tooltip;

  @override
  State<ShareWithUserWidget> createState() => _ShareWithUserWidgetState();
}

class _ShareWithUserWidgetState extends State<ShareWithUserWidget> {
  late final TextEditingController effectiveController;
  bool isButtonEnabled = false;

  @override
  void initState() {
    super.initState();

    effectiveController = widget.controller ?? TextEditingController();
    effectiveController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      effectiveController.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    final Widget child = Row(
      children: [
        Expanded(
          child: AFTextField(
            controller: effectiveController,
            size: AFTextFieldSize.m,
            hintText: LocaleKeys.shareTab_inviteByEmail.tr(),
          ),
        ),
        HSpace(theme.spacing.s),
        AFFilledTextButton.primary(
          text: LocaleKeys.shareTab_invite.tr(),
          disabled: !isButtonEnabled,
          onTap: () {
            widget.onInvite(effectiveController.text.trim().split(','));
          },
        ),
      ],
    );

    if (widget.disabled) {
      return FlowyTooltip(
        message:
            widget.tooltip ?? LocaleKeys.shareTab_onlyFullAccessCanInvite.tr(),
        child: IgnorePointer(
          child: child,
        ),
      );
    }

    return child;
  }

  void _onTextChanged() {
    setState(() {
      final texts = effectiveController.text.trim().split(',');
      isButtonEnabled = texts.isNotEmpty && texts.every(isEmail);
    });
  }
}
