import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class AIWriterBlockHeader extends StatelessWidget {
  const AIWriterBlockHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return FlowyText.medium(
      LocaleKeys.document_plugins_autoGeneratorTitleName.tr(),
      fontSize: 14,
    );
  }
}

class AIWriterBlockInputField extends StatelessWidget {
  const AIWriterBlockInputField({
    super.key,
    required this.onGenerate,
    required this.onExit,
  });

  final VoidCallback onGenerate;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PrimaryRoundedButton(
          text: LocaleKeys.button_generate.tr(),
          margin: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 10.0,
          ),
          radius: 8.0,
          onTap: onGenerate,
        ),
        const Space(10, 0),
        OutlinedRoundedButton(
          text: LocaleKeys.button_cancel.tr(),
          margin: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 10.0,
          ),
          onTap: onExit,
        ),
        Flexible(
          child: Container(
            alignment: Alignment.centerRight,
            child: FlowyText.regular(
              LocaleKeys.document_plugins_warning.tr(),
              color: Theme.of(context).hintColor,
              overflow: TextOverflow.ellipsis,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class AIWriterBlockFooter extends StatelessWidget {
  const AIWriterBlockFooter({
    super.key,
    required this.onKeep,
    required this.onRewrite,
    required this.onDiscard,
  });

  final VoidCallback onKeep;
  final VoidCallback onRewrite;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PrimaryRoundedButton(
          text: LocaleKeys.button_keep.tr(),
          margin: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 9.0,
          ),
          onTap: onKeep,
        ),
        const HSpace(10),
        OutlinedRoundedButton(
          text: LocaleKeys.document_plugins_autoGeneratorRewrite.tr(),
          onTap: onRewrite,
        ),
        const HSpace(10),
        OutlinedRoundedButton(
          text: LocaleKeys.button_discard.tr(),
          onTap: onDiscard,
        ),
      ],
    );
  }
}
