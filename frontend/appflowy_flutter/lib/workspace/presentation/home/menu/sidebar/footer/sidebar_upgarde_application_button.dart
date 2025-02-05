import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/util/theme_extension.dart';
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
          const Opacity(
            opacity: 0.7,
            child: FlowyText(
              'Get the latest features and bug fixes. Click "Update" to install now.',
              fontSize: 13,
              figmaLineHeight: 16,
              maxLines: null,
            ),
          ),
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
        const FlowyText.medium(
          'New Version Available!',
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
          child: const FlowyText.medium(
            'Update',
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
