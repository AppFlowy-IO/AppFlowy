import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/widgets.dart';

class PluginStateIndicator extends StatelessWidget {
  const PluginStateIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFFEDF7ED),
        borderRadius: BorderRadius.all(
          Radius.circular(4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          children: [
            const HSpace(8),
            const FlowySvg(
              FlowySvgs.download_success_s,
              color: Color(0xFF2E7D32),
            ),
            const HSpace(6),
            FlowyText(
              LocaleKeys.settings_aiPage_keys_localAILoaded.tr(),
              fontSize: 11,
              color: const Color(0xFF1E4620),
            ),
          ],
        ),
      ),
    );
  }
}
