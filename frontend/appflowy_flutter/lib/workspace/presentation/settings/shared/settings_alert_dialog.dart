import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/dialog/styled_dialogs.dart';

class SettingsAlertDialog extends StatefulWidget {
  const SettingsAlertDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.children,
    this.cancel,
    this.confirm,
    this.confirmLabel,
    this.hideCancelButton = false,
    this.isDangerous = false,
    this.implyLeading = false,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? children;
  final void Function()? cancel;
  final void Function()? confirm;
  final String? confirmLabel;
  final bool hideCancelButton;
  final bool isDangerous;

  /// If true, a back button will show in the top left corner
  final bool implyLeading;

  @override
  State<SettingsAlertDialog> createState() => _SettingsAlertDialogState();
}

class _SettingsAlertDialogState extends State<SettingsAlertDialog> {
  @override
  Widget build(BuildContext context) {
    return StyledDialog(
      maxHeight: 600,
      maxWidth: 600,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (widget.implyLeading) ...[
                GestureDetector(
                  onTap: Navigator.of(context).pop,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Row(
                      children: [
                        const FlowySvg(
                          FlowySvgs.arrow_back_m,
                          size: Size.square(24),
                        ),
                        const HSpace(8),
                        FlowyText.semibold(
                          LocaleKeys.button_back.tr(),
                          fontSize: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const Spacer(),
              GestureDetector(
                onTap: Navigator.of(context).pop,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: FlowySvg(
                    FlowySvgs.m_close_m,
                    size: const Size.square(20),
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: FlowyText.medium(
                  widget.title,
                  fontSize: 22,
                  color: Theme.of(context).colorScheme.tertiary,
                  maxLines: null,
                ),
              ),
            ],
          ),
          if (widget.subtitle?.isNotEmpty ?? false) ...[
            const VSpace(16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: FlowyText.regular(
                    widget.subtitle!,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.tertiary,
                    textAlign: TextAlign.center,
                    maxLines: null,
                  ),
                ),
              ],
            ),
          ],
          if (widget.children?.isNotEmpty ?? false) ...[
            const VSpace(16),
            ...widget.children!,
          ],
          if (widget.confirm != null || !widget.hideCancelButton) ...[
            const VSpace(20),
          ],
          _Actions(
            hideCancelButton: widget.hideCancelButton,
            confirmLabel: widget.confirmLabel,
            cancel: widget.cancel,
            confirm: widget.confirm,
            isDangerous: widget.isDangerous,
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.hideCancelButton,
    this.confirmLabel,
    this.cancel,
    this.confirm,
    this.isDangerous = false,
  });

  final bool hideCancelButton;
  final String? confirmLabel;
  final VoidCallback? cancel;
  final VoidCallback? confirm;
  final bool isDangerous;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!hideCancelButton) ...[
          SizedBox(
            height: 24,
            child: FlowyTextButton(
              LocaleKeys.button_cancel.tr(),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              fontColor: AFThemeExtension.of(context).textColor,
              fillColor: Colors.transparent,
              hoverColor: Colors.transparent,
              onPressed: () {
                cancel?.call();
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
        if (confirm != null && !hideCancelButton) ...[
          const HSpace(8),
        ],
        if (confirm != null) ...[
          SizedBox(
            height: 48,
            child: FlowyTextButton(
              confirmLabel ?? LocaleKeys.button_confirm.tr(),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              fontColor: isDangerous ? Colors.white : null,
              fontHoverColor: Colors.white,
              fillColor: isDangerous
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
              hoverColor: isDangerous
                  ? Theme.of(context).colorScheme.error
                  : const Color(0xFF005483),
              onPressed: confirm,
            ),
          ),
        ],
      ],
    );
  }
}
