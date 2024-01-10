import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';

class DocumentStarButton extends StatelessWidget {
  const DocumentStarButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FlowyTooltip(
      message: LocaleKeys.moreAction_moreOptions.tr(),
      child: FlowyHover(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: FlowySvg(
            FlowySvgs.unfavorite_s,
            size: const Size(18, 18),
            color: Theme.of(context).iconTheme.color,
          ),
        ),
      ),
    );
  }
}
