import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class MobileSearchAskAiEntrance extends StatelessWidget {
  const MobileSearchAskAiEntrance({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Container(
      height: 48,
      margin: EdgeInsets.only(top: 16),
      padding: EdgeInsets.fromLTRB(8, 12, 8, 12),
      child: Row(
        children: [
          FlowySvg(
            FlowySvgs.m_home_ai_chat_icon_m,
            size: Size.square(24),
            blendMode: null,
          ),
          HSpace(12),
          FlowyText.regular(
            LocaleKeys.search_askAIAnything.tr(),
            fontSize: 16,
            figmaLineHeight: 22,
            color: theme.textColorScheme.primary,
          ),
        ],
      ),
    );
  }
}
