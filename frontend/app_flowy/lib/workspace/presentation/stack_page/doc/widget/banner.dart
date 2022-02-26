import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/buttons/base_styled_button.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:app_flowy/generated/locale_keys.g.dart';

class DocBanner extends StatelessWidget {
  final void Function() onRestore;
  final void Function() onDelete;
  const DocBanner({required this.onRestore, required this.onDelete, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // [[Row]] CrossAxisAlignment vs mainAxisAlignment
    // https://stackoverflow.com/questions/53850149/flutter-crossaxisalignment-vs-mainaxisalignment
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 60),
      child: Container(
        color: Theme.of(context).primaryColor,
        child: Row(
          children: [
            FlowyText.medium(LocaleKeys.deletePagePrompt_text.tr(), color: Colors.white),
            const HSpace(20),
            BaseStyledButton(
                minWidth: 160,
                minHeight: 40,
                contentPadding: EdgeInsets.zero,
                bgColor: Colors.transparent,
                hoverColor: Theme.of(context).hoverColor,
                downColor: Theme.of(context).primaryColor,
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
                hoverColor: Theme.of(context).hoverColor,
                downColor: Theme.of(context).primaryColor,
                outlineColor: Colors.white,
                borderRadius: Corners.s8Border,
                child: FlowyText.medium(LocaleKeys.deletePagePrompt_deletePermanent.tr(),
                    color: Colors.white, fontSize: 14),
                onPressed: onDelete),
          ],
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
        ),
      ),
    );
  }
}
