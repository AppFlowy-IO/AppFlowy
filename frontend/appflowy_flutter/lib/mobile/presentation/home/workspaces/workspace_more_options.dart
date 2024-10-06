import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

enum WorkspaceMenuMoreOption {
  rename,
  invite,
  delete,
  leave,
}

class WorkspaceMenuMoreOptions extends StatelessWidget {
  const WorkspaceMenuMoreOptions({
    super.key,
    this.isFavorite = false,
    required this.onAction,
    required this.actions,
  });

  final bool isFavorite;
  final void Function(WorkspaceMenuMoreOption action) onAction;
  final List<WorkspaceMenuMoreOption> actions;

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
    WorkspaceMenuMoreOption action,
  ) {
    switch (action) {
      case WorkspaceMenuMoreOption.rename:
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
            WorkspaceMenuMoreOption.rename,
          ),
        );
      case WorkspaceMenuMoreOption.delete:
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
            WorkspaceMenuMoreOption.delete,
          ),
        );
      case WorkspaceMenuMoreOption.invite:
        return FlowyOptionTile.text(
          // i18n
          text: 'Invite',
          height: 52.0,
          leftIcon: const FlowySvg(
            FlowySvgs.workspace_add_member_s,
            size: Size.square(18),
          ),
          showTopBorder: false,
          showBottomBorder: false,
          onTap: () => onAction(
            WorkspaceMenuMoreOption.invite,
          ),
        );
      case WorkspaceMenuMoreOption.leave:
        return FlowyOptionTile.text(
          text: LocaleKeys.workspace_leaveCurrentWorkspace.tr(),
          height: 52.0,
          textColor: Theme.of(context).colorScheme.error,
          leftIcon: FlowySvg(
            FlowySvgs.leave_workspace_s,
            size: const Size.square(18),
            color: Theme.of(context).colorScheme.error,
          ),
          showTopBorder: false,
          showBottomBorder: false,
          onTap: () => onAction(
            WorkspaceMenuMoreOption.leave,
          ),
        );
      default:
        return const Placeholder();
    }
  }
}
