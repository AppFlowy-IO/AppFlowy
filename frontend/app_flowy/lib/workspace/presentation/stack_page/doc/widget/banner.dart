import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/buttons/base_styled_button.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';

class DocBanner extends StatelessWidget {
  final void Function() onRestore;
  final void Function() onDelete;
  const DocBanner({required this.onRestore, required this.onDelete, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 60),
      child: Container(
        width: double.infinity,
        color: theme.main1,
        child: FittedBox(
          alignment: Alignment.center,
          fit: BoxFit.scaleDown,
          child: Row(
            children: [
              FlowyText.medium(LocaleKeys.deletePagePrompt_text.tr(), color: Colors.white),
              const HSpace(20),
              BaseStyledButton(
                  minWidth: 160,
                  minHeight: 40,
                  contentPadding: EdgeInsets.zero,
                  bgColor: Colors.transparent,
                  hoverColor: theme.main2,
                  downColor: theme.main1,
                  outlineColor: Colors.white,
                  borderRadius: Corners.s8Border,
                  child: FlowyText.medium(LocaleKeys.deletePagePrompt_restore.tr(), color: Colors.white, fontSize: 14),
                  onPressed: onRestore),
              const HSpace(20),
              BaseStyledButton(
                  minWidth: 220,
                  minHeight: 40,
                  contentPadding: EdgeInsets.zero,
                  bgColor: Colors.transparent,
                  hoverColor: theme.main2,
                  downColor: theme.main1,
                  outlineColor: Colors.white,
                  borderRadius: Corners.s8Border,
                  child: FlowyText.medium(LocaleKeys.deletePagePrompt_deletePermanent.tr(),
                      color: Colors.white, fontSize: 14),
                  onPressed: onDelete),
            ],
          ),
        ),
      ),
    );
  }
}
