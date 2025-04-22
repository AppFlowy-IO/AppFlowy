import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/home/tab/mobile_space_tab.dart';
import 'package:appflowy/workspace/application/command_palette/command_palette_bloc.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileSearchAskAiEntrance extends StatelessWidget {
  const MobileSearchAskAiEntrance({super.key, this.query});
  final String? query;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return GestureDetector(
      onTap: () {
        context
            .read<CommandPaletteBloc?>()
            ?.add(CommandPaletteEvent.gointToAskAI());
        mobileCreateNewAIChatNotifier.value =
            mobileCreateNewAIChatNotifier.value + 1;
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
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
            buildText(theme),
          ],
        ),
      ),
    );
  }

  Widget buildText(AppFlowyThemeData theme) {
    final queryText = query ?? '';
    if (queryText.isEmpty) {
      return Text(
        LocaleKeys.search_askAIAnything.tr(),
        style: theme.textStyle.heading4
            .standard(color: theme.textColorScheme.primary),
      );
    }
    return Flexible(
      child: RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          children: [
            TextSpan(
              text: LocaleKeys.search_askAIFor.tr(),
              style: theme.textStyle.heading4
                  .standard(color: theme.textColorScheme.primary),
            ),
            TextSpan(
              text: ' "$queryText"',
              style: theme.textStyle.heading4
                  .enhanced(color: theme.textColorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
