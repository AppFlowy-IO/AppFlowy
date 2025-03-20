import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/workspace/application/sidebar/space/space_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class SpacePermissionBottomSheet extends StatelessWidget {
  const SpacePermissionBottomSheet({
    super.key,
    required this.onAction,
    required this.permission,
  });

  final SpacePermission permission;
  final void Function(SpacePermission action) onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FlowyOptionTile.text(
          text: LocaleKeys.space_publicPermission.tr(),
          leftIcon: const FlowySvg(
            FlowySvgs.space_permission_public_s,
          ),
          trailing: permission == SpacePermission.public
              ? const FlowySvg(
                  FlowySvgs.m_blue_check_s,
                  blendMode: null,
                )
              : null,
          onTap: () => onAction(SpacePermission.public),
        ),
        FlowyOptionTile.text(
          text: LocaleKeys.space_privatePermission.tr(),
          showTopBorder: false,
          leftIcon: const FlowySvg(
            FlowySvgs.space_permission_private_s,
          ),
          trailing: permission == SpacePermission.private
              ? const FlowySvg(
                  FlowySvgs.m_blue_check_s,
                  blendMode: null,
                )
              : null,
          onTap: () => onAction(SpacePermission.private),
        ),
      ],
    );
  }
}
