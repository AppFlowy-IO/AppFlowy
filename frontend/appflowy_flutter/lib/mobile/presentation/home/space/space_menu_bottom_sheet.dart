import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/space/space_action_type.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class SpaceMenuMoreOptions extends StatelessWidget {
  const SpaceMenuMoreOptions({
    super.key,
    required this.onAction,
    required this.actions,
  });

  final void Function(SpaceMoreActionType action) onAction;
  final List<SpaceMoreActionType> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: actions
          .map(
            (action) => _buildActionButton(context, action),
          )
          .toList(),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    SpaceMoreActionType action,
  ) {
    switch (action) {
      case SpaceMoreActionType.rename:
        return FlowyOptionTile.text(
          text: LocaleKeys.button_rename.tr(),
          height: 52.0,
          leftIcon: const FlowySvg(
            FlowySvgs.view_item_rename_s,
            size: Size.square(18),
          ),
          showTopBorder: false,
          showBottomBorder: false,
          onTap: () => onAction(
            SpaceMoreActionType.rename,
          ),
        );
      case SpaceMoreActionType.delete:
        return FlowyOptionTile.text(
          text: LocaleKeys.button_delete.tr(),
          height: 52.0,
          textColor: Theme.of(context).colorScheme.error,
          leftIcon: FlowySvg(
            FlowySvgs.trash_s,
            size: const Size.square(18),
            color: Theme.of(context).colorScheme.error,
          ),
          showTopBorder: false,
          showBottomBorder: false,
          onTap: () => onAction(
            SpaceMoreActionType.delete,
          ),
        );
      case SpaceMoreActionType.manage:
        return FlowyOptionTile.text(
          text: LocaleKeys.space_manage.tr(),
          height: 52.0,
          leftIcon: const FlowySvg(
            FlowySvgs.settings_s,
            size: Size.square(18),
          ),
          showTopBorder: false,
          showBottomBorder: false,
          onTap: () => onAction(
            SpaceMoreActionType.manage,
          ),
        );
      case SpaceMoreActionType.duplicate:
        return FlowyOptionTile.text(
          text: SpaceMoreActionType.duplicate.name,
          height: 52.0,
          leftIcon: const FlowySvg(
            FlowySvgs.duplicate_s,
            size: Size.square(18),
          ),
          showTopBorder: false,
          showBottomBorder: false,
          onTap: () => onAction(
            SpaceMoreActionType.duplicate,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
