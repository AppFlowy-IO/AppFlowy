import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';

class WebUrlHintWidget extends StatelessWidget {
  const WebUrlHintWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: FlowyTooltip(
        message: LocaleKeys.workspace_learnMore.tr(),
        preferBelow: false,
        child: FlowyIconButton(
          width: 24,
          height: 24,
          icon: const FlowySvg(
            FlowySvgs.information_s,
          ),
          onPressed: () {
            afLaunchUrlString(
              'https://appflowy.com/docs/self-host-appflowy-run-appflowy-web',
            );
          },
        ),
      ),
    );
  }
}
