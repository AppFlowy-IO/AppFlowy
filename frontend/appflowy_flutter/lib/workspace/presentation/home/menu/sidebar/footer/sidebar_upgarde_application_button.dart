import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class SidebarUpgradeApplicationButton extends StatelessWidget {
  const SidebarUpgradeApplicationButton({
    super.key,
    required this.onUpdateButtonTap,
    required this.onCloseButtonTap,
  });

  final VoidCallback onUpdateButtonTap;
  final VoidCallback onCloseButtonTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.sidebarUpgradeButtonBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // title
          _buildTitle(),
          const VSpace(2),
          // description
          _buildDescription(),
          const VSpace(10),
          // update button
          _buildUpdateButton(),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        const FlowySvg(
          FlowySvgs.sidebar_upgrade_version_s,
          blendMode: null,
        ),
        const HSpace(6),
        FlowyText.medium(
          LocaleKeys.autoUpdate_bannerUpdateTitle.tr(),
          fontSize: 14,
          figmaLineHeight: 18,
        ),
        const Spacer(),
        FlowyButton(
          useIntrinsicWidth: true,
          text: const FlowySvg(FlowySvgs.upgrade_close_s),
          onTap: onCloseButtonTap,
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Opacity(
      opacity: 0.7,
      child: FlowyText(
        LocaleKeys.autoUpdate_bannerUpdateDescription.tr(),
        fontSize: 13,
        figmaLineHeight: 16,
        maxLines: null,
      ),
    );
  }

  Widget _buildUpdateButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onUpdateButtonTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: ShapeDecoration(
            color: const Color(0xFFA44AFD),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          child: FlowyText.medium(
            LocaleKeys.autoUpdate_settingsUpdateButton.tr(),
            color: Colors.white,
            fontSize: 12.0,
            figmaLineHeight: 15.0,
          ),
        ),
      ),
    );
  }
}

extension on BuildContext {
  Color get sidebarUpgradeButtonBackground => Theme.of(this).isLightMode
      ? const Color(0xB2EBE4FF)
      : const Color(0xB239275B);
}
